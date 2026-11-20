# What's new in FactorIA

The editor shows these notes when it offers an update, and each release on GitHub uses its section. Newest first.

Older versions, one file per minor version with its patch releases: [0.31](changelog/0.31.md), [0.30](changelog/0.30.md), [0.29](changelog/0.29.md), [0.28](changelog/0.28.md), [0.27](changelog/0.27.md), [0.26](changelog/0.26.md), [0.25](changelog/0.25.md), [0.24](changelog/0.24.md), [0.23](changelog/0.23.md), [0.22](changelog/0.22.md), [0.21](changelog/0.21.md), [0.20](changelog/0.20.md), [0.19](changelog/0.19.md), [0.18](changelog/0.18.md), [0.17](changelog/0.17.md), [0.16](changelog/0.16.md), [0.15](changelog/0.15.md), [0.14](changelog/0.14.md), [0.13](changelog/0.13.md), [0.12](changelog/0.12.md), [0.11](changelog/0.11.md), [0.10](changelog/0.10.md), [0.9](changelog/0.9.md), [0.8](changelog/0.8.md), [0.7](changelog/0.7.md), [0.6](changelog/0.6.md), [0.5](changelog/0.5.md), [0.4](changelog/0.4.md), [0.3](changelog/0.3.md), [0.2](changelog/0.2.md), [0.1](changelog/0.1.md).

## Unreleased

- **`factoria feedback collect examples/*`** no longer reports "no 'entries' array" for the files of that folder that are not feedback files (`examples.json`, a readme): when several paths are given, a file not called `ENGINE_FEEDBACK.json` that holds no feedback is skipped; named alone it is an error that says what to pass.
- **Lightmap baker core (M73.4, no command yet):** `fa/scene/lightmap_bake.h` bakes the diffuse light of lights, a sky and emissive surfaces into lightmap atlases and into spherical-harmonics probes with a deterministic CPU path tracer (the same bits with any number of threads, a public `TriBvh`, progress, cancel and refusals before it allocates); see docs/design/ARCHITECTURE_BAKING.md.
- **Radiance HDR reader and writer (M73.3a, P3a-1):** `fa/core/image_float.h` adds `ImageF`, a float32 RGB or RGBA image (bilinear
  sampling with clamp or wrap, box resize, sRGB conversion with exposure to and from `Image`) and the engine's own `.hdr`
  codec: `decode_hdr` / `load_hdr` read run-length, flat and old-style rows and refuse other orientations, XYZE and
  oversized headers with an error that says what to do; `encode_hdr` / `save_hdr` write run-length rows. Not reachable from
  scripts or `assets.import` yet; the HDRI environment import builds on it. New fuzz target `hdr`.

## 0.32.0

Every renderer takes a custom shader: sprites, shapes, tilemaps, text, particles and vfx, the sky and UI images use the same `fragment()`/`vertex()` snippets as meshes, with per-sprite values that keep batching. Post-process materials are passes of the M71 stack, placed around the built-in effects and after the tonemap, and can read the frame before. Mesh materials can be full shaders with their own passes and light loop. Compute materials run on D3D11, Metal and GL 4.3 (a clear refusal on GLES3 and WebGL2) and write buffers and images that meshes and sprites draw thousands of times in one draw. The Graph panel edits node graphs for mesh, sprite and post materials, with a live preview that writes the same JSON and snippet an AI writes.

### M72: custom shaders for everything

- **Quieter OpenGL log:** sokol_gfx's "not found in shader" notes (a uniform block, texture or vertex attribute the GL
  driver removed because the shader does not use it, as in a material without fog or `fa_time`) are logged at Debug,
  not as warnings: the binding is skipped and the picture is the same.
- **Sprites drawn from a compute buffer (M72.4, P18b):** a `kind: "sprite"` material can declare read-only `buffers` too, and
  read them in `vertex()` and in `fragment()` by `fa_instance_index`. `Sprite.instances` = N draws the sprite's quad N times in
  one draw (the quad is the template `vertex()` moves; a Sprite with such a material is never batched with another one).
  `materialParams` gives the compute buffer ids; there is no `instanceBounds`, because the CPU culls no sprite. A missing,
  destroyed or differently shaped buffer, a buffer shorter than `instances`, `instances` on a material without buffers and
  `"instanced"` params next to `buffers` are teaching errors with a JSON pointer, and the sprite is not drawn (nor counted in
  the stats). A Shape2D, Tilemap, Text, ParticleEmitter or UiBox with such a material is not drawn either. Same backends and
  CPU-path refusal as the mesh version (GLES3, WebGL2 and OpenGL 4.1 refuse at load). 2D GPU-particles recipe in
  docs/shaders/SHADERS_COMPUTE.md, "Sprites from a compute buffer".
- **Meshes drawn from a compute buffer (M72.4, P18a):** a mesh material (snippet or `mode: "full"`) can declare read-only
  `buffers`, written by a compute material, and read them in `vertex()`, in helpers and in `surface()`. `MeshRenderer.instances`
  = N draws the entity N times; `vertex()` gets `fa_instance_index` and places each instance, `materialParams` gives the compute
  buffer id of each buffer and `instanceBounds` the half-extent the camera culls the entity by (0 never culls). Instances cast
  shadows and enter the depth prepass (a full shader writes `"shadow": "custom"` and `"prepass": false`). A missing, destroyed or
  differently shaped buffer, or `instances` larger than the buffers, is an error with the JSON pointer and the entity is not
  drawn. sokol_gfx has no indirect draw, so GPU culling means the compute pass writes a flag and `vertex()` collapses the
  instance (recipe and two examples in docs/shaders/SHADERS_COMPUTE.md, "Drawing from a compute buffer"). Metal, Direct3D 11 and
  OpenGL 4.3; GLES3, WebGL2 and OpenGL 4.1 refuse the material at load and name the CPU path.
- **Shader tools and docs polish (M72, POL-R1):** docs/SHADERS.md no longer ends with a "Not available yet" list: each limit
  (per-instance params and extra vertex channels in sky and compute, depth and normals of a sprite, compute on Android and the
  web) is a sentence in the section of its kind. A sprite's `vertex()` may call `fa_scene_rgb()`; `fa_sample_main()` is
  fragment-only and an error from it in the vertex stage says so. The "did you mean" of an unknown `fa_` name suggests only names
  the docs list. A texture named like a field of the contract (`normal`, `albedo`...) still compiles; when `vertex()` or a shared helper reads that field, the error says to rename the texture; `alphaMode` on a
  sprite says to remove it. A "no matching overloaded function" on a lighting function gives the vertex-stage hint only when the
  call is compiled in the vertex stage, else the signature. `factoria validate` shares the material-path rules of the shader
  commands. The result of `shader.compile` documents its `graph` field. New tests: 12 varyings with instanced params for GLES3,
  a sprite material on a MeshRenderer, the cache key when `instanced` is toggled.

- **Node graphs for post materials (M72.5):** a material with `"kind": "post"` can hold a `"graph"`: `material.graph.generate`
  writes `post(in PostInput i, inout PostSurface s)` into `shaders/<name>.post.glsl`, with the same `graphHash` and hand-edit rule
  as the other kinds. The post `output` node has `color` and `rgb`; new nodes `post.scene`, `post.depth`, `post.normal`,
  `post.history` and `post.screen` write the helper calls of the post contract (`fa_scene_color`, `fa_depth`, `fa_normal`,
  `fa_history`, `i.texel`/`i.size`), and using one is all it takes to ask the renderer for the prepass or the history. Noise,
  `flow`, `uv`, `time` and math work there; the nodes of a mesh or a sprite are refused with what to use instead.
  `material.graph.nodes {kind: "post"}` returns a post example. Sprite and post graphs now convert `const.color` and `color`
  params with `fa_scene_rgb` (a colour looks as picked in a linear scene; mesh graphs are unchanged), the "no output node" error
  suggests a field of the material's own kind, and a palette search that matches a node of another kind (by name, category or
  description) says what to use instead. Graph panel: the combo next to New graph material has Post; a post graph starts as
  the picture unchanged.

- **Live preview of post materials (M72.5):** the Graph panel draws a `kind: post` material over a small 3D scene (a floor and
  four lit shapes at different depths, over a sky) seen by a camera whose `PostProcess.customPasses` holds only that material,
  four frames in a row, so `post.history` has a frame before it and `post.depth` / `post.normal` have their prepass. New
  `Renderer::capture_camera` (C++, `CameraCapture`): captures a world through a camera entity with the custom passes of its
  `PostProcess`, with its own histories (clean at each call, the game's are not touched), the same picture for the same world.
  It runs the custom passes only, every slot as one chain over the unencoded picture, not the rest of the stack. The panel's
  **Try on scene camera** button adds the saved material to the `customPasses` of the camera that draws the scene, as one undo
  step. The history is not available when a capture asks for one frame.

- **Node graphs for sprite materials (M72.5):** a material with `"kind": "sprite"` can hold a `"graph"`:
  `material.graph.generate` writes the sprite snippet (`fragment(in QuadInput i, inout QuadSurface s)` and, when
  `vertexOffset` is linked, `vertex(inout QuadVertex v)`), with the same `graphHash` and hand-edit rule as a mesh graph. The
  sprite `output` node has `color`, `rgb`, `alpha` and `vertexOffset`; new nodes `sprite.color`, `sprite.tint`,
  `sprite.texture`, `sprite.life`, `sprite.custom` and `sprite.position` read what a sprite shader gets. Noise, dissolve,
  flow, `uv`, `time` and math work in both kinds; `fresnel`, `triplanar`, `parallax` and the other 3D nodes are refused in a
  sprite graph with the node's pointer, why and what to use instead, and `material.graph.nodes {kind}` lists each node with the
  kinds it works in. Graph panel: a box next to New graph material picks `mesh` or `sprite`, a sprite graph's palette leaves out the
  3D nodes (a search that matches one says what to use), and its preview draws the 2D quad.

- **Material editor and material commands polish (M72, POL-LAST-A):** Graph panel: answering Overwrite for a file that changed on
  disk is no longer followed by a second question about the file when the snippet was hand-edited; Overwrite also writes a
  deleted material again, and a Reload that fails says why. New graph material picks a name that is free for the material and
  for its `shaders/<name>.surface.glsl` (a hand-written snippet is never taken over, and `create` refuses one), says so when it
  cannot remove its temporary file, and opening the material that is already open keeps a half-filled New param form. The
  preview deletes the `stage-*` files an editor that quit mid-compile left behind (older than ten minutes) and its errors name
  the material and the snippet instead of the stage files. Commands: `material.param.delete` and `material.texture.delete`
  leave an empty section where the last entry was (a later create fills it in place), a warning about a hand-written snippet
  says so, `shader.compile` keeps the original hint (for example where to get sokol-shdc) when it adds the regenerate fix, a
  material path like `c:x` is refused on every OS, and a snippet that is there but cannot be read is state `unreadable` with
  the path and the cause, not "does not exist yet".
  Last polish: `factoria validate` without sokol-shdc still warns (`/graph`) when the graph changed since its snippet, and
  reports a missing or unreadable snippet as an error with the regenerate hint instead of counting it as "not compiled". Graph
  panel: Overwrite on a deleted file no longer makes the poll ask again "The file changed on disk"; the preview names the real
  files also when the compiler prints the stage paths with `\` or a mix; an unreadable snippet shows in amber with the reason
  as tooltip; a New material that cannot remove its temporary file says so on every failure, not only on success; a rename
  in progress of a param or texture that a reload or an outside change of the file took away is dropped.

- **Post-process materials polish (M72, round 2a):** the images between the pieces of a final pass cut by custom passes
  are made in the display format, not the scene's (no second sRGB encode, no lost alpha), and in a float format when the
  window is HDR and the GPU can render it. The cap of 32 custom passes names the first entry left out and says why one that
  does not parse is not drawn. A material that does not build says what happens to its kind (a post pass is skipped, the sky
  is drawn as the gradient, `compute.*` commands that name it fail), not "drawn magenta". A history pass the GPU refused is
  not asked again every frame (it is asked again when the camera's rectangle or the picture format changes), the docs say
  that a game under about 7.5 fps at 60 Hz starts the history every frame, and `render.reset_post_history` answers an
  `entity` that is not a string with `invalid_argument` and a hint. New tests: the cut in a split screen, a multisampled
  frame with a HUD over the final pass, a gamma scene, the trail across a `capture_world`, the budget warning, the refusal,
  a reload and a shutdown without leaked images. The SSAO 321x181 test shuts its renderer down when a check fails.

- **Renderer polish: instances, full shaders, sky, compute and 2D materials (M72):** A mesh whose material failed to build
  is tried again when the mesh reloads. The per-instance params of a mesh material are packed once per entity and kept until
  its params change, not every frame. A full shader's parts fill their pass data once per part, and `stats.triangles` counts
  the triangles every pass draws (a part with two passes counts twice, as `drawCalls` does). A sky material that reads a
  `target:` texture is baked with the camera that was planned for it, and the main camera's environment now wins over a
  mirror camera's when both ask. `compute.read_image` with `x`, `y`, `width` and `height` copies only that region from the GPU (the Metal,
  D3D11 and OpenGL readbacks take a rectangle); a corner of a large image no longer costs the whole image. For 2D materials, one path
  asked as a sprite material and as a post material keeps two answers, the lookup of a sprite no longer allocates a map node
  per frame, a component whose `materialParams` is written while the frame renders is drawn with its current values with one
  warning (in every build, not an assert that only debug builds had), and the docs say that two spellings of the same params
  in another key order are two lookups of one material. `diff_images` documents that `maxError` is the plain difference.

- **Graph panel polish (M72):** Save looks at the file first: when it changed on disk since the editor read it, a window asks
  Overwrite, Reload or Cancel instead of replacing it. New graph material publishes the file whole and removes it again if the
  snippet cannot be written. The editor's own writes (a param default, a new param) no longer hide an outside change from the
  poll. Each preview stages its compile in files of its own and changing project or quitting the editor waits at most two seconds for it. What the
  material commands say (a snippet not written again, `warnings` on rename and delete) is shown in the status, Undo of a param or
  texture delete puts it back at its place, and closing or opening a graph clears the forms. The Graph autotest no longer relies on
  fixed delays, and the editor autotest always uses its own clipboard.

- **Compute storage images (M72.17):** a `"kind": "compute"` material can declare `"images"` (up to 4, each with a `format`
  of `rgba8`, `rgba16f`, `r32f` or `rgba32f`, an `access` of `write` or `readWrite` and a `size`) and write them with
  `imageStore` (read them with `imageLoad`). New commands `compute.create_image`, `compute.resize_image`,
  `compute.read_image`, `compute.destroy_image` and `compute.list_images`; `compute.dispatch` takes `images` next to
  `buffers`. The image is a texture for any material: put its `textureId` (`"compute:<id>"`) in `Sprite.texture`,
  `MeshRenderer.texture` or a texture param of a mesh, sprite or post material, and a dispatch made before a draw is
  finished when the draw reads it. A new image is zero; limits are counts (32 images, 8192 pixels a side, 256 MiB each,
  512 MiB in all) and a format the GPU cannot write is refused with the ones that work. `"readWrite"` (`imageLoad` and `imageStore`) is guaranteed for `r32f` only: `compute.create_image` asks the GPU (Direct3D 11 typed UAV loads, the Metal read-write texture tier) and refuses another format where it cannot load it, with `/images/<name>/access` and the way out (`r32f`, or two images). `factoria validate` accepts `compute:<n>` in a texture field. `material.info` lists `images`.
  Where there is no compute (Android, the web, macOS OpenGL 4.1) the refusal names the backend and the CPU path.
  Compute materials with no images keep the twins they had: **nothing needs to be exported again** unless it declares images.
  The page `factoria docs read shaders-compute` has the rules, a complete example and the table per backend.

- **Material tools polish (M72):** `shader.compile` and `factoria validate` tell you to run `material.graph.generate` when the
  snippet of a graph material is missing or older than its graph. `material.param.create` and `material.texture.create` take
  an optional `index` (where in `params`/`textures` to insert; the order of textures decides the slots) and the matching
  `delete` returns the `index` it had, so an undo puts the entry back in place. `create`, `rename` and `delete` work on a file
  whose graph reads a param that is not declared yet (create fixes it), and `rename`/`delete` return `warnings` when a
  hand-written snippet still uses the name. `"graph": null` is an error with a pointer instead of a hand-written snippet; a
  material called `..x.material.json` or `~tmp.material.json` is no longer refused as outside the project or absolute; the
  command descriptions say the material file is rewritten (2-space JSON) by every command that writes it.

- **Scene, Inspector and validation polish (M72):** `factoria validate` refuses a material path with a backslash, an absolute
  path or `..` the same way on every OS (the error names the JSON pointer and the form to write), and checks that
  `SceneSettings.skyMaterial` is a material of kind `sky` (the error names the kind it found and lists the project's sky
  materials). The Inspector's material params keep one edit and one error per component, so two components of one entity with
  a param of the same name no longer share them. Undo of two edits of one block of material params made within a moment redoes
  both. The editor's Viewport draws the sky as the game does (docs/EDITOR.md says so). The editor autotest copies and pastes
  through a clipboard of its own, so other programs using the system clipboard cannot fail it.
- **Post history (M72.16):** a post material that calls `fa_history(uv)` reads its own output of the frame before (trails,
  feedback, accumulation), with `fa_history_valid` for the frames where there is none (the first one, after a resize or a
  change of render scale or format, when the camera was not drawn the frame before, at a scene or clock cut, and after the
  new command `render.reset_post_history`, which takes an optional camera). Each camera and pass keeps two images that swap
  every frame, freed 120 frames after the last frame that used them; a history that does not fit the 1 GiB budget (256 MiB on
  the web) leaves the pass drawn without it. Using `fa_history` as a texture, `fa_history_valid` as a call, or either outside a
  post material is refused with the fix before sokol-shdc runs. See `factoria docs read shaders-post`, "History".
  **Games with custom post materials must re-export again** (the post template changed).
- **A sky material also lights the meshes (M72.3):** the sky that `SceneSettings.skyMaterial` draws is baked into two small
  cube images, so meshes now reflect it (a metal ball under a two-colour sky shows each colour on the side that faces it)
  and take its ambient light from it (`fa_ambient_light(n)`, which replaces `ambientLight` for those meshes), in `"pbr"`,
  custom and full materials. It is baked again when the material, its params or textures, the scene's sky colours or the sun
  change, and every 0.1 s of game time for a sky that reads `SkyInput.time` (no wall clock: a replay is the same). On Metal a
  frame that bakes takes about 2 to 3.5 ms longer (60 small passes); a scene without a sky material has the same pixels and the
  same draws, with a bit more work (a 1 x 1 black cube fills the slot, no pass bakes anything). A sun that turns bakes again a
  sky that reads it (`sun_dir`), not one that does not. GL, D3D11 and WebGL 2 (RGBA8 when the GPU cannot render to half floats) are not seen on a device yet. A helper of your own
  that calls a lighting function now gets a hint about the vertex stage and `#ifdef GL_FRAGMENT_SHADER`, `fa_environment`,
  `fa_env_brdf`, `fa_sky_reflection` and `fa_ambient_light` may be called from `surface()`, and a name of the API is never
  suggested for itself. **Games with custom mesh materials must re-export** (the mesh template changed).
- **Compute buffers (polish):** `compute.read_buffer` and `compute.write_buffer` also refuse a call of more than 4194304
  numbers (elements times the components of their fields) and say how many elements fit and to go on in chunks with
  `first`/`count`; floats read back are the same in every C locale.

- **Your own light loop and the sky light for custom lighting (M72.3):** a mesh material with `"lighting": "custom"` can
  define `vec3 lighting(in SurfaceInput i, in Surface s)` instead of `light()`: the engine calls it once per fragment in
  place of its loop and its ambient term, and you pick the lights with `fa_light_count()` (at most 32, the shadow caster
  first, then the other directional lights, then point and spot lights by relevance to the camera), `fa_light(n, i)`,
  `fa_light_unshadowed(n, i)` and `fa_light_shadow(n, i)`. The sky reflection (image-based lighting), off in a custom
  material until now, is one call away from `light()`, `ambient()` and `lighting()`: `fa_sky_light(i, s)`, or
  `fa_sky_reflection(n, v, f0, roughness)`, `fa_environment(direction, roughness)` and `fa_env_brdf(roughness, ndv)` in
  pieces; full shaders get the last three. Mistakes are found before the compiler runs (the hook without custom lighting,
  `lighting()` together with `light()`, the functions in a `"pbr"` material or in `surface()`) and a misspelled name gets
  a "did you mean". A custom material without the hook renders the same pixels. The page `factoria docs read
  shaders-lighting` has the functions, the order of the lights and a complete example. **Games with custom mesh materials
  must re-export** if they have not since the previous entry (the mesh template changed).
- **Full shaders and passes for mesh materials (M72.3):** `"mode": "full"` on a `"kind": "mesh"` material names a file
  with the vertex and the fragment stage (`@common`, `@vertex`, `@fragment`, each with its own `main`) instead of the
  `vertex()`/`surface()` snippet, and `"passes": [...]` draws the mesh up to four times in array order, each pass with its
  own `cull`, `depthTest`, `depthWrite` and `blend` (an inverted-hull outline, an x-ray behind walls, a glow shell). The
  engine still provides the model matrix (instancing, skinning), the instanced params, the declared `uv1`/`color1`
  channels, the camera, the time and the same params and textures as globals, plus `fa_light_count()`, `fa_light(i, ...)`,
  `fa_shadow(...)` and `fa_apply_fog(...)` to write your own lighting. `"shadow"` is `"depth"` (default), `"custom"` (the
  first pass again, from the light) or `"none"`; `"prepass": false` keeps the material out of SSAO and the depth fog.
  `lighting`, `alphaMode`, `doubleSided` and `graph` belong to snippets and are refused here. `shader.compile`,
  `factoria validate` and `factoria export` compile every pass for every dialect (a compiler error names your file and line,
  and a varying that one stage declares and the other does not is reported before the compiler runs); `material.info` lists
  the mode, the passes and their programs. The page `factoria docs read shaders-full` has the rules and a complete outline.
  **Games with custom mesh materials must re-export again** if they have not since the previous entry.
- **Graph panel preview, complete (M72 P13b-1):** the live preview of a material graph now has param sliders (float, vec2, vec3,
  vec4 and color: they change the PREVIEW only, nothing is written and nothing compiles again; **Reset** puts them back and
  **Set as default** writes the value as the param's `default` in the file, as one undo step), a **Compare** check box that
  draws the last saved version of the graph next to the current one, and a compiler error painted on the node whose generated
  line it names (the generator keeps the id of the node that wrote each line of the snippet). The panel draws `mesh`
  materials, and a `sky`, `post` or `compute` material says why it has no preview instead of drawing wrongly; the preview
  is also ready to draw a `sprite` material on a 2D quad for when the graph generator supports that kind (it does not
  yet, so no graph material reaches it today). New command `material.param.set_default {material, param, value, dryRun?}` writes one param's default
  (checked like the file; it returns the `previous` value). Two fixes: a preview that was redrawn after a shape change no longer
  turned an error back into "up to date", and a shader compile whose result could not be saved in `.factoria/shader-cache` is
  now an error in the panel instead of running sokol-shdc on the editor's thread. `.factoria/material-preview/` (the files the
  preview writes) is documented in the Graph panel section.
- **Params and textures from the Graph panel (M72 P13b-2):** the Graph panel makes, renames and deletes the params and
  textures of the material without leaving it (**+ Param**, **+ Texture**, **Rename**, **Delete** in the side list): the new
  entry is in the file at once, a `param` or `texture` node offers it immediately, a rename points the nodes that read it at the
  new name, a delete is refused while nodes read it (the panel names and selects them), and each is one undo step. Six new
  commands do the work, so an AI and the panel share the checks: `material.param.create`, `material.param.rename`,
  `material.param.delete`, `material.texture.create`, `material.texture.rename` and `material.texture.delete`
  (`{material, name, ...}`, all with `dryRun`; a name the material has, a GLSL word, `fa_` or the graph's `gn_` prefix is
  refused with the fix; `delete` refuses a used entry with error code `in_use` and the node ids, or removes those nodes and their
  links with `force: true`; rename and delete also take the editor's in-memory graph as `graph`; a shader snippet that was in
  sync is generated again). Three smaller fixes in the same panel: a link dropped on the input it already feeds is no longer an
  empty undo step, the checker does not run at every mouse move of a drag (the report is the one of the graph when the drag
  began), and a material file that lost its `graph` is reported once instead of being read again at every look.
- **Per-sprite values and vertex textures in sprite materials (M72.1):** a sprite material's param marked
  `"instanced": true` takes its value per quad: 100 sprites, shapes, tiles, glyphs or particles of one material with 100
  different `tint` values are one batch and one draw call, and the snippet reads `tint` by its name in `fragment()` and
  `vertex()`. Same rules as a mesh (at most 3 vec4, the error on `/params` lists them); a param that is not instanced
  still splits the batch; sky and compute materials still refuse `instanced` (`/params/<name>/instanced`). The values travel in a second
  vertex buffer (the four corners of a quad carry the same values: up to 192 bytes per quad at 3 vec4) and reach
  `fragment()` as `flat` varyings. A particle's instanced values are its emitter's `materialParams`, and the new
  `QuadInput.life` is how far the particle is through its life (0 for everything else; `QuadInput.custom` stays
  reserved). The `vertex()` of a sprite material can now sample the material's textures (mip 0, the same names as in
  `fragment()`). `material.info` reports `instanceLayout` for a sprite. **Games with sprite materials must re-export:** the
  sprite template changed (the engine's own sprites look the same), so older compiled twins are refused with the re-export
  hint until `factoria export` or `shader.compile` writes them again.
- **Per-instance params and vertex channels for mesh materials (M72.3):** a material param marked `"instanced": true`
  takes a value per entity inside one instanced draw call: 100 entities with 100 different `tint` values are one draw, and
  the snippet reads `tint` by its name in `vertex()` and `surface()` (also in the shadow and depth prepass programs, so a
  vertex moved by an instanced value casts its moved shadow). The values travel in the instance buffer, at most 3 vec4
  (12 floats) per material; more is an error on `/params` that lists them. A param that is not instanced still splits the
  batch. `"vertexAttributes": ["uv1", "color1"]` lets `vertex()` read a glTF mesh's second UV set and second vertex-color
  set (`vertex_uv1`, `vertex_color1`); a mesh part without a declared channel (any procedural mesh or built-in primitive)
  is drawn magenta and logged once with the material, the mesh and the glTF attribute. A material that uses neither gets
  the attributes it had. `material.info` and the twins list `instanced`, `instanceVec4` and `vertexAttributes`.
  **Games with custom materials must re-export again:** the mesh template changed (no built-in mesh looks different), so
  the compiled shader files an older export shipped are refused, with the re-export hint, until the game is exported
  again.
- **Compute materials (M72.4):** `"kind": "compute"` makes a `*.material.json` a GPU program over storage buffers: its snippet
  defines `void compute(in ComputeInput i)`, and the file declares `workgroupSize` (a multiple of 32, at most 256) and
  `buffers` (arrays of `float`, `vecN`, `int` and `uint` fields, std430), plus `params` and `textures` as for meshes.
  `shader.compile`, `factoria validate` and `factoria export` compile it to the HLSL 5, GLSL 4.30 and Metal twins and
  `material.info` lists the platforms it runs on (`runsOn`, `notOn`); an Android or Web export warns that it has no shader
  there. The new commands `compute.create_buffer`, `compute.write_buffer`, `compute.dispatch`, `compute.read_buffer`,
  `compute.destroy_buffer` and `compute.list_buffers` (and `Renderer::compute()` in C++) create buffers, run a material over
  them and read the result back. On GLES3, WebGL2, macOS OpenGL 4.1 and without graphics they fail with the code
  `unavailable`, naming the backend (`render.supports computeShaders`). Storage images are not available yet.

- **Material kinds (M72 base):** `*.material.json` takes an optional `"kind"`: `"mesh"` (default, what materials were so far),
  `"sprite"`, `"sky"`, `"post"` or `"compute"`. Every kind compiles and draws (the milestone's packages brought them one by
  one); `shader.compile` and `material.info` report the `kind`. Each kind hashes only its own template files (`fa::material_template_hash(kind)`), so
  a change to one template no longer makes the twins of the other kinds stale; the mesh hash did not change, so no export
  needs to be redone. The skeletons `quad_common.glsl`, `sky_common.glsl` and `post_common.glsl` declare each kind's snippet
  contract.
- **Sprite materials, the template and the tooling (M72.1):** `"kind": "sprite"` compiles. The 2D quad shader is now a
  template (`quad_common.glsl`) with a hook: a snippet defines `void fragment(in QuadInput i, inout QuadSurface s)` (and
  optionally `void vertex(inout QuadVertex v)`), `s.color` arrives holding what the engine draws for the item (texture,
  circle, glyph, lit picture, SDF shape) and the flash, the multiply conversion and the fog apply to what the snippet
  leaves. `QuadInput` carries `uv`, the tint, the world position, `screen_uv`, the time, the mode and a reserved
  `custom`. `shader.compile`, `material.info` (programs `quad` and `quad_plain`), `factoria validate` and
  `factoria export` (`<name>.material.json.<dialect>.shader`) work for it; `alphaMode: "clip"` is an error on a sprite.
  The engine's own pixels do not change (an empty `fragment()` is the built-in program). The renderer draws a `Sprite` with the
  compiled programs (next bullet); docs/SHADERS.md has the contract, the slots and an example with a dissolve and a
  hit flash. The sprite template hash covers `quad_common.glsl`, `color_space.glsl` and `light_shadow.glsl`.
  A sprite material cannot name a param or texture after a name of the 2D program (`color`, `uv`, `tex`, `smp`, `lit`,
  `params`...: the error names the JSON pointer and a rename), `noise` is refused for every kind (sokol-shdc cannot compile
  a texture called that) and a sprite `vertex()` cannot sample a material texture.
- **Sprites draw with their material (M72.1):** a `Sprite` with `material` (and `materialParams`) is drawn by the
  compiled `quad` / `quad_plain` programs of a `"kind": "sprite"` material, with the engine's blend and depth state. Sprites
  with the same material and equal values share a draw call; a different value, another material or no material splits the
  batch, and the draw order is unchanged. `fa_time` and `fa_target` are filled. A material that did not build (or is of
  another kind) draws the sprite magenta with the built-in shader and shows in `materialFallbacks`; a hot reload rebuilds it
  and a failed one keeps the last good version. A material with an empty `fragment()` draws the same pixels as none.
- **Every 2D emitter draws with its material (M72.5):** `Shape2D`, `Tilemap`, `Text`, `ParticleEmitter` and the background of
  every UI widget now draw with their `material` and `materialParams`, like `Sprite`. A Tilemap takes one material for all its
  tiles, an emitter one for all its particles and trails (they batch together), a `Text` for its glyph quads (the glyph atlas
  stays the main texture, so `fa_sample_main(uv)` reads the glyph coverage; the pictures of a rich text keep the built-in
  shader), and a widget for its background only (the `texture` as a 9-slice or the solid `color`): the label of a Button,
  Toggle or TextField, icons, knobs, the picture of a Chart, Video or CameraView, Captions and the tooltip stay on the
  built-in shader (field docs and docs/SHADERS.md say so). A material that did not build draws the item magenta and shows in
  `materialFallbacks`. The lookup of a material is made once per frame for every distinct material and set of values, not
  once per component (`RenderStats.materialResolves` counts them), so a thousand sprites with one material cost one lookup.
  `stats.materials` now counts each material once per frame (it counted once per quad group and camera), and the coverage
  pass of the sprite outline effect gives `fa_target` and `screen_uv` the size of its own image. A material whose params name a
  render target samples the missing-texture checker for the camera that renders into it (never the image it writes), and a
  texture that failed to load no longer destroys the shared checker when the asset cache is cleared.

- **Post-process materials (M72.2):** `"kind": "post"` compiles and draws. `PostProcess.customPasses` is a list (at most 8) of
  `{material, materialParams, enabled, position, name}`: each entry is a full-screen pass of the camera's stack drawn by a
  post material, placed before or after a named built-in effect (`"after:bloom"`, `"before:tonemap"` by default, `"after:ssr"`,
  `"before:depthOfField"`...; a position that is not a place is refused with the ones that work). A snippet defines
  `void post(in PostInput i, inout PostSurface s)` and reads the picture (`fa_scene_color`), optionally the linear depth and the
  view-space normal (`fa_depth`, `fa_normal`: the renderer draws the depth and normal prepass for a camera only when a pass reads
  them) and `fa_scene_rgb` for colours. Passes at one place run in list order, a split screen runs each camera's list over its
  own rectangle, and a volume adds its entries at strength 0.5. A pass whose material is missing, broken, not a post material or
  needs the depth on a GPU without it is skipped: the log says why once and `materialFallbacks` names it. `shader.compile`,
  `material.info`, `factoria validate` and `factoria export` work for the kind (`lighting`, `alphaMode` and `doubleSided` are
  refused with the reason); `postprocess.set` checks the entries with their JSON pointer; `postprocess.get {resolved}` lists the
  passes and the problems; `render.supports` has the feature `postMaterials`; the editor's Post-processing panel adds, switches,
  reorders, removes and edits the params of a pass, one undo step each; hot reload swaps the shader. The picture is read
  with a half-texel clamp at the edge of the camera's rectangle (a split screen never reads the neighbour's pixels).
  docs/shaders/SHADERS_POST.md.
- **Post passes between the screen effects (M72.2):** a custom pass can now sit after the tonemap and between the colour
  grading, vignette, sharpen, outline, posterize and film grain: `"after:tonemap"`, `"after:colorGrading"`, `"after:vignette"`,
  `"after:sharpen"`, `"after:outline"`, `"after:posterize"`, `"after:filmGrain"` (and the matching `"before:..."`, and
  `"before:colorFilter"`). There the pass reads the display-referred picture the effects before it made (tonemapped,
  sRGB-encoded; values above 1 survive on an HDR output) and the final pass is drawn in two pieces around it, only where an
  entry sits: a frame without one draws the same single pass as before. The editor's Position list offers the new places.
  `after:pixelate`, `before:pixelate` and `after:colorFilter` are refused with the reason. A camera and its volumes draw at
  most 32 custom passes; the entries past that are dropped and the log says so once (it was silent). The `postMaterials` row of
  `render.supports` says that the feature needs nothing of the GPU and only a pass that reads the depth or the normals needs
  `sampledDepth`.
  docs/shaders/SHADERS_POST.md.
- **Custom lighting and textures in `vertex()` (M72.3):** a mesh material with `"lighting": "custom"` defines
  `vec3 light(in SurfaceInput i, in Surface s, in LightSample l)`, which the engine's light loop calls once per light
  (the engine still picks the lights and applies attenuation, shadows, emission and fog), and optionally `ambient()`:
  toon ramps, cel bands, hatching. `LightSample` carries the direction, the color (attenuation and shadow already in
  it), the attenuation, the shadow factor, the distance and the light type. A material without `light()` gets an error
  naming its file and the fix. `vertex()` can now sample the material's textures (always mip 0), also in the shadow and
  depth prepass programs, so a height map displaces the mesh and its shadow. docs/SHADERS.md has the contract and four
  new worked examples. **Games with custom materials must re-export:** the mesh template changed (no built-in mesh looks
  different), so the compiled shader files an older export shipped for custom materials are refused, with the re-export
  hint, until the game is exported again.

- **Materials on every renderer (fields):** `Sprite`, `Shape2D`, `Tilemap`, `Text`, `ParticleEmitter` and every UI widget (`UiBox`) get `material` and `materialParams`, and `SceneSettings` gets `skyMaterial` and `skyMaterialParams`, like `MeshRenderer`; `factoria validate` checks that a `material` is an existing `*.material.json` and suggests the closest one, and the Inspector types the params of each entity's component by `material.info` (the params of `SceneSettings` are typed by the Scene settings panel, see Sky materials below).

- **Sky materials and the Scene settings panel (M72.1):** `"kind": "sky"` compiles and draws. A snippet defines
  `void sky(in SkyInput i, inout SkySurface s)` (`i.dir` the view direction, `i.sun_dir` the scene's sun, `i.time`; `s.color`
  arrives holding the engine's gradient, so an empty `sky()` is the built-in sky), and `SceneSettings.skyMaterial` and
  `skyMaterialParams` paint the background of every perspective camera with it. A material that is missing, of another kind
  or that did not build keeps the gradient and logs why once. The meshes' ambient and reflection light still follow `skyColor`
  and `horizonColor`. `shader.compile`, `material.info` (program `sky`), `factoria validate` and `factoria export` work for the
  kind; docs/SHADERS.md has the contract and an example with a dusk sky and a sun. `scene.set_component` now takes the
  component `SceneSettings` with no `id`, so the scene's settings can be edited (and undone) by the editor, scripts and AIs
  through one command. **View > Scene settings** is a new editor window with every setting in groups, the sky material's
  params typed by `material.info` with a Reset each, and one undo step per change.

- **Material node graphs (the document and the generator):** a `*.material.json` can hold a `"graph"` of nodes and links, and
  `material.graph.generate` writes the material's GLSL snippet from it (deterministic, readable text, one line per node, with
  `graphHash` recorded in the material file). A snippet edited by hand is never overwritten without `force`; deleting `graph`
  keeps the hand-written code. The library has 46 node types: constants, params, textures, uv, time, vertex colour and
  position and normal inputs, math, value, gradient, voronoi and fractal noise, dissolve, flow maps, fresnel, triplanar and
  parallax occlusion, and an output node (surface fields and a vertex offset). `material.graph.nodes` lists them and
  `material.graph.validate` checks a graph with the JSON pointer of every problem. The editor's canvas is the Graph panel (below).

- **Graph panel (M72.5):** View > Graph edits the node graph of a material on a canvas: drag nodes, link ports with the mouse
  (a link that would make a cycle or a type that does not fit is refused with the checker's sentence), a searchable palette
  of the library, copy, cut, paste and duplicate (the text pastes into another material), a lit sphere, cube or quad preview
  of the material the graph generates (compiled on a worker thread), the problems
  list, and Save, which runs `material.graph.generate` and asks before it overwrites a hand-edited snippet. Open a material
  by double-clicking it in the Project panel, with **Edit graph** in the Inspector, or start one with **New graph material**.
  Every kept edit is one step of the editor's Undo. The graph format takes an optional `version` and `editor` objects (the
  panel's own data, never part of the snippet); `material.graph.validate` and `generate` take an inline `graph`, names starting
  with `gn_` are refused for params and textures, and a link no longer reports a type mismatch again further down the chain.
