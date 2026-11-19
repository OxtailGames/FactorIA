# What's new in FactorIA

The editor shows these notes when it offers an update, and each release on GitHub uses its section. Newest first.

Older versions, one file per minor version with its patch releases: [0.30](changelog/0.30.md), [0.29](changelog/0.29.md), [0.28](changelog/0.28.md), [0.27](changelog/0.27.md), [0.26](changelog/0.26.md), [0.25](changelog/0.25.md), [0.24](changelog/0.24.md), [0.23](changelog/0.23.md), [0.22](changelog/0.22.md), [0.21](changelog/0.21.md), [0.20](changelog/0.20.md), [0.19](changelog/0.19.md), [0.18](changelog/0.18.md), [0.17](changelog/0.17.md), [0.16](changelog/0.16.md), [0.15](changelog/0.15.md), [0.14](changelog/0.14.md), [0.13](changelog/0.13.md), [0.12](changelog/0.12.md), [0.11](changelog/0.11.md), [0.10](changelog/0.10.md), [0.9](changelog/0.9.md), [0.8](changelog/0.8.md), [0.7](changelog/0.7.md), [0.6](changelog/0.6.md), [0.5](changelog/0.5.md), [0.4](changelog/0.4.md), [0.3](changelog/0.3.md), [0.2](changelog/0.2.md), [0.1](changelog/0.1.md).

## Unreleased

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

## 0.31.0

The scene is lit in linear light and drawn into a float target, and every camera gets a post-processing stack: tonemap and exposure (manual or automatic), bloom, colour grading with LUTs, vignette, lens effects, grain, sharpen, outline, pixelate and posterize, ambient occlusion, screen-space reflections, distance and height fog, sun shafts, depth of field and camera motion blur, plus transient screen effects (shockwave, heat haze, radial blur, flash, fade) and HDR display output on macOS and Windows. A `PostProcess` component and volumes set the stack, `render.supports` says what each GPU draws, and the editor's Post-processing panel shows it live with an A/B switch.

### M71: linear HDR and a post-processing stack

- **Scene effects polish:** screen-space reflections now default to `ssrIntensity` 0.5 and never mix in more than 75 % of the
  reflection, and the hit thickness grows with distance so the fp16 prepass bias no longer lets rays through. Bloom, depth of
  field, SSR and sun shafts treat NaN and Inf as 0 and clamp to 65504 like the post pass. Sun shafts no longer light the picture
  when the sun is off screen. Ambient occlusion and the shafts use single-channel `R16F` images where the GPU can, and the
  SSAO, SSR, depth of field and fog passes probe the target pool once per shape instead of every frame. Depth of field and motion
  blur no longer draw the prepass when nothing would be blurred, motion blur tells a camera cut by the world frame, and a
  planned fog pass that was not drawn is logged once. `render.supports` names its rows by effect and reports depth of field and
  sun shafts as needing half floats and depth. The passes table moved from RENDERING.md to its own page (`docs.read
  rendering-passes`), and the editor's post-processing panel calls `supports_report` directly and no longer has a "planned" state.

- **Final pass polish:** the automatic exposure keeps its adapted value in an RGBA16F pixel as two numbers (a coarse step and the
  remainder), so it no longer stops short of its target at a slow speed and a high frame rate, and it needs no 32-bit target (iOS,
  WebGL2); a failed target is tried again after 300 frames instead of for ever, and a `capture_world` between two frames no
  longer makes the exposure jump. A finite value up to 65504 in the picture is white, not black (NaN and Inf are black). The film
  grain of the second camera of a split screen differs from the first, and its cells no longer depend on how the GPU rounds. The
  lens edge fades over one pixel. The dither is top-left-origin on every backend. A `.cube` file read half-written is read again
  on the next frame, and `title` is read in any case. A camera that has `Camera.bloom` or `colorFilter` and a PostProcess of its
  own logs once that the deprecated fields are ignored. The doc strings of `tonemapMode`, `vignetteRoundness` and `sharpenEnabled`
  say what they do.

- **Output polish:** the mips of a colour texture made as sRGB in a linear scene are averaged in linear light (`mip_chain(image, true)`;
  small sprites no longer come out dark when minified; an exported `.ktx2` twin keeps the mips of the export). A CameraView, render
  target or world capture drawn in R11G11B10 (no alpha) logs one warning that its background is opaque. The editor viewport shows the
  unencoded image, not "No render target", while the encoded copy of a linear scene does not exist yet. A second renderer starts from
  what the window shows (HDR status), the status says that an R11G11B10 scene holds the final picture in 8 bits, and Windows asks for
  the swapchain's colour space again after a resize at most eight frames in a row.
- **Last polish:** a texture that was decoded in the background before the first frame of a linear scene is adopted with its mips
  averaged in linear light too (the chain is made again on the main thread when the colour space changed meanwhile). The editor
  viewport test covers the fallback before the encoded copy exists. The automatic exposure warns once when its measuring target
  could not be made on a frame (it was skipped silently), and a scene change clears the "deprecated Camera.bloom ignored" warnings
  so they can be said again. Windows: the colour space retry count starts again for each new window size during a resize drag, and a
  WebSocket peer that answers our close with empty messages ends the wait after 1000 of them, not at the deadline. Larkspur Lodge's
  colour filter cycle is wrapped under 120 columns and Kindlewatch's filter test reads the bloom of the scene instead of pinning it.
- **Screen-space reflections:** `PostProcess.ssrEnabled` is drawn: opaque 3D surfaces reflect what the camera shows. Each pixel marches
  its reflected ray across the screen in the depth prepass (`ssrSteps` steps with a deterministic jitter, a thickness test of
  `ssrThickness`, six bisections to refine the hit, a longest ray of `ssrMaxDistance`) and takes the scene colour there, before the
  exposure, so a bright object reflects bright. Reflections fade at the screen border, toward the end of the ray and on the back of a
  surface. There is no roughness or metalness image: every surface reflects by a fresnel term (more at a grazing angle) times
  `ssrIntensity`. Each camera of a split screen traces its own rectangle; a frame without the effect (or with `ssrIntensity` 0) adds no
  pass, no image, no prepass and draws the same bytes as before. The passes are `ssr-trace` and `ssr-copy` in `render.frame_graph`;
  `render.supports` answers `ssr` true where the GPU has float targets and the sampled depth. Docs: docs/rendering/RENDERING_EFFECTS.md, "Screen-space reflections".

- **Ambient occlusion (`ssao`):** `PostProcess.ssaoEnabled` now darkens creases and contact points of 3D meshes (GTAO from the depth and
  normal prepass, at half resolution for `low` and `medium`, full for `high` and `ultra`, a blur that follows the surfaces, no random
  numbers: the same picture every run). `ssaoRadius` is in world units, `ssaoIntensity` the power of the occlusion, and each camera of a
  split screen has its own passes over its own rectangle. It works in place on the game picture, on the opaque meshes only (see "Effects
  before the transparent things" below); off, at intensity 0, or without opaque meshes it adds no pass and no prepass.
  `render.supports {"feature": "ssao"}` is true where the GPU has RGBA16F targets that blend, and `render.debug_view {"view": "ao"}`
  shows the occlusion alone.

- **Fog and sun shafts:** `fogEnabled` and `sunShaftsEnabled` of `PostProcess` are drawn now (`render.supports` is true for `fog` and
  `sunShafts`). The fog is exponential from `fogStart` plus an exact height fog (`fogHeightDensity`, `fogHeightBase`,
  `fogHeightFalloff`) along the view ray from the depth; the sky is not fogged, and a camera whose stack fog is drawn does not also draw
  `SceneSettings.fogDensity` (never twice). The shafts scatter the bright sky (above `sunShaftsThreshold`) toward the sun's place on the screen (the shadow-casting or
  brightest directional light) with 48 jittered taps at half resolution, tinted and added, fading out as the sun leaves the screen or
  goes behind the camera (perspective cameras). Each camera of a split screen fogs and traces its own rectangle (`shafts-*` passes);
  off adds no pass and no prepass. See docs/rendering/RENDERING_EFFECTS.md.

- **Effects before the transparent things:** the ambient occlusion and the stack's fog are applied in the camera's main pass, right
  after the sky and the opaque meshes and before the blended meshes, sprites, particles and 3D text. Before, both were passes after the
  whole main pass, so glass, sprites and particles were darkened by the occlusion of the opaque meshes behind them and fogged with that
  surface's distance (and a blended mesh against the sky got no fog). Now they keep their colour under the occlusion and fog
  themselves by their own distance with the same law (a blended mesh in front of a far, fogged wall shows its own fog, one over the sky
  is fogged). The occlusion passes (`ssao-ao`, `ssao-blur-h`, `ssao-blur-v`) come before the main pass; `ssao-apply`, `ssao-view` and
  `fog-blend` are gone from `render.frame_graph` (they are draws inside the main pass); the interface is neither darkened nor fogged.
  A frame with neither effect draws the same bytes as before. Custom materials are recompiled (their shaders carry the fog numbers).

- **Depth of field and camera motion blur:** `depthOfFieldEnabled` and `motionBlurEnabled` of `PostProcess` are drawn now (`render.supports`
  says so, `postprocess.apply_preset` no longer lists them in `notDrawn`). Both read the depth prepass and work on the scene colour,
  before the bloom and the final pass; each camera has its own passes (split screen). The depth of field blurs by a circle of confusion
  from the view depth, with a near and a far blur in design pixels, a half-size disc gather and an optional bokeh weighting; the
  autofocus follows `depthOfFieldTarget` by `depthOfFieldFocusSpeed` on the engine clock (the same frames give the same focus on every
  machine) and falls back to `depthOfFieldFocusDistance` with no target. The motion blur smears along the camera's own movement with a
  fixed jitter, up to 8% of the picture's larger side, and never on the first frame or after a camera cut. With both off nothing is
  declared and the picture is unchanged (docs/RENDERING.md, "Depth of field and motion blur").

- **Screen effects: radial blur and transient effects.** The `radialBlur` effect of `PostProcess` is drawn now (`render.supports
  {"feature": "radialBlur"}` is true). Five short effects of the camera, drawn by its post pass over the finished picture:
  `camera.shockwave` (a ring that expands and bends the picture), `camera.heatHaze` (a ripple over a region), `camera.radialBlur` (a
  pulse of the blur), `camera.flash` (the screen in one colour, fading) and `camera.fadeOut` / `camera.fadeIn` (a fade to a colour
  that is held, and back). Commands `feel.shockwave`, `feel.heatHaze`, `feel.radialBlur`, `feel.screenFlash` and `feel.fade`; the
  same names are feel actions (animation clip events, effect documents) and `feel.state` lists them. They run on the game clock
  (deterministic, `time.scale 0` holds them), belong to one camera or to all of them (a split screen shows one on its half), need no
  `PostProcess`, honour reduce motion and reduced effects, are bounded (16 alive, a camera draws 4 shockwaves and 2 hazes) and cost
  nothing when none is alive. See docs/rendering/RENDERING_SCREEN_EFFECTS.md.

- **Post-processing costs and a graphics page:** `render.frame_graph` returns `postProcess`: the post-processing passes with their
  summed CPU and GPU time (`gpuMs` is `null` with `gpuStatus` `"unavailable"` and a reason where the backend has no GPU timer; the effects
  folded into the `post` pass are not timed one by one), and the editor's Profiler panel has a "Post-processing" tab with the same table.
  The menu kit's options panel gets a Graphics tab: effects quality (high, medium, low, off), bloom, film grain, vignette, chromatic
  aberration and outline switches, and HDR output where the display can show it; it writes the scene's `PostProcess` fields and is saved in
  `settings.graphics`.

- **Prepass follow-ups:** the new command `render.debug_view` (`none`, `depth`, `normals`; no argument reports the current view) shows the
  depth or normals of the prepass in a screenshot; the written depth is clamped to 60000 (`a` is the coverage); a custom material whose
  shader has no prepass programs logs a warning at load.
- **Test tooling polish:** `render.debug_view` declares its three views as an `enum` in its argument schema, so a wrong view is
  an `invalid_arguments` error with a "Did you mean" hint (it was `invalid_argument` from a hand-written check). On a Mac whose
  displays sleep, a test run that ends itself with exit code 77 now also kills its child processes first (an orphan holding
  ctest's pipe kept ctest waiting), and `scripts/agent-build.sh` blames display sleep only for the window tests (a test that
  ctest skips for another reason is listed apart, with no cause). `cli_mcp_update` has a wall-clock watchdog and timeouts on
  every child program, and kills the servers it started on every way out.
- **Linear colour:** `SceneSettings.colorSpace` (`gamma`, the default, or `linear`) now works. In a linear scene lighting and
  blending happen in linear light: the colours you pick (tints, lights, ambient, fog, sky, clear colour, particles) are converted for
  you, colour textures (sprites, albedo, emissive) are read as sRGB (`SRGB8A8`, and the sRGB variants of BC7, ASTC and ETC2) and data
  textures (normal maps, masks) as plain numbers, the game target holds linear light (`RGBA16F`, else `R11G11B10`, else `SRGB8A8`,
  else `RGBA8`) and the picture is encoded to sRGB when it is shown. A gamma scene is drawn exactly as before. Switching at run time
  keeps the textures and leaks no GPU image. `render.supports` says `linearColor` and `r11g11b10` are available; `FA_SCENE_FORMAT`
  accepts `r11g11b10` for tests. Exposure, tonemap and the display-space HUD come with the post-processing stack (below); a linear scene
  without them is encoded by the copy to the screen, so values above 1 clip and bloom works on linear values (docs/RENDERING.md,
  "Color space"). The editor's viewport shows what the game shows (`Renderer::set_editor_view`). `SceneSettings.hdrOutput` (`off` or `auto`) and
  `paperWhiteNits` (200) are stored and saved; they change nothing yet. The mesh shader template changed: the compiled shader of a custom
  material made by an earlier build is refused with a message that asks to export the game again (`factoria run` compiles them itself).
- **PostProcess component:** one reflected component for a camera's own post-processing stack or for a volume (shape `global`, `box`,
  `circle` or `sphere`, `size`, `blendDistance`, `priority`, `weight`), with 20 effects (`ssao`, `ssr`, `fog`, `sunShafts`,
  `exposure`, `depthOfField`, `motionBlur`, `radialBlur`, `lensDistortion`, `chromaticAberration`, `bloom`, `tonemap`,
  `colorGrading`, `vignette`, `sharpen`, `outline`, `pixelate`, `posterize`, `filmGrain`, `colorFilter`). All are off by default and
  only the ones listed below are drawn yet: the other fields are stored and saved. The renderer resolves the volumes at each camera on the CPU
  (docs/design/ARCHITECTURE_RENDERING.md, "PostProcess").
- **Commands:** `render.supports` says what the renderer can do on this graphics backend and GPU (float targets, R11G11B10, sampled
  depth, compute shaders, linear colour, HDR output and each post effect; false for what is not drawn yet); `postprocess.get`,
  `postprocess.set`, `postprocess.presets` and `postprocess.apply_preset` read and write the PostProcess component.
  `postprocess.get {"resolved": true}` answers with the stack a camera really draws and where each value comes from (its own
  PostProcess, a volume, or the deprecated Camera fields). The seven looks (`neutral`, `cinematic`, `retro`, `noir`, `dreamy`, `vivid`,
  `horror`) are data in `engine/runtime/data/postprocess_presets.json`; a look that names an effect the renderer does not draw yet
  still applies and says which parts will show later (`notDrawn`).
- **Post-processing panel:** View > Post-processing shows the stack of a camera in the order its effects run: each effect's switch,
  whether this renderer draws it (`planned` or `unsupported`, with the reason), its fields with the source of each value, a button
  per look and a **Stack off (A/B)** check that draws the game without post-processing to compare (`Renderer::set_post_bypass`; it
  changes no data). Edits go to the camera's own PostProcess or to a volume you pick through `postprocess.set` and
  `postprocess.apply_preset`, one undo step each (docs/EDITOR.md, docs/RENDERING.md, AI_GUIDE recipe 9.20).
- **Exposure, bloom, tonemap and colour filter are drawn.** The stack of the camera that draws first is now a set of frame-graph
  passes: bloom (with a new soft `bloomKnee`, a `bloomLensDirt` texture and a `bloomThreshold` that may exceed 1), exposure (manual
  `exposureEv`, or `exposureMode` auto: a 32x32 brightness reduction and a 1x1 adaptation on the GPU, deterministic from the frame
  time, no read back, between `exposureMinEv` and `exposureMaxEv`), tonemap (`none`, `neutral`, `aces`, `agx`, `reinhard`) and the
  colour filter, with a final pass that fuses exposure, tonemap, filter and the encode for the display and dithers by one 8-bit step.
  The screen-space HUD is drawn over the final picture in display colours (never exposed or tonemapped; the colour filter still
  covers it). A frame without any stack still declares no pass and makes no render target. `render.supports` answers true for these
  four effects. docs/RENDERING.md ("Post-processing") has the order and the cost of each; AI_GUIDE recipe 9.20 is rewritten to
  PostProcess.
- **Colour grading, vignette, chromatic aberration, lens distortion, sharpen and film grain are drawn.** They run in the final `post`
  pass (a stack with only these effects now gets one full-screen pass; a stack without them draws exactly what it did). The lens and
  the aberration bend how the scene is read (the bloom glow bends too; outside the lens the picture is black, `lensDistortionScale`
  hides it); the rest work in display space and do not clip above white: white balance (`colorGradingTemperature`, `Tint`),
  lift/gamma/gain, contrast, saturation, the new `colorGradingHueShift` and a 3D LUT from a `.cube` file (`colorGradingLut`, mixed
  by `colorGradingLutContribution`), a vignette (new `vignetteCenter`), a contrast-adaptive sharpen and a film grain seeded by
  the engine's frame counter (the same on every run; new `filmGrainLuminanceResponse`, new `lensDistortionCenter`). `assets.import`
  takes a `.cube` into `assets/luts/` and checks it. `render.supports` answers true for the six effects; the
  `colorGradingCurve*` fields are still only stored (docs/RENDERING.md, "The effects of the final pass").
- **Outline, pixelate and posterize are drawn.** Three more looks of the final `post` pass. `pixelateSize` makes blocks of that many
  design pixels, each showing the colour at its centre; `posterizeLevels` cuts each display channel to that many levels (after the
  grading, with the dither off). `outlineEnabled` draws lines of `outlineWidth` design pixels in `outlineColor` (its alpha is the
  opacity): in `depth` mode (3D) at the silhouettes, the depth jumps (`outlineDepthThreshold`) and the surface creases
  (`outlineNormalThreshold`) found in the depth and normal prepass, which the effect turns on; in `sprite` mode (2D) around the
  border of the sprites, tiles, shapes, text and particles (`outlineAlphaThreshold`), found in a coverage image of the 2D world that is
  drawn once more while the effect is on (the new `sprite-coverage` pass, RGBA8). An effect at its neutral value (width 0,
  alpha 0, block 1, 256 levels) draws no pass and the frame is byte for byte the one without it. `render.supports` answers true
  for the three, so the `retro` look is now drawn whole, and `postprocess.apply_preset` lists fewer effects under `notDrawn`
  (docs/RENDERING.md, "The outline").
- **Every camera has its own post-processing stack, in a split screen too.** Until now only the camera that draws first had a
  stack. Now each camera's `PostProcess` (or the volumes it is inside) is drawn by its own final `post` pass over that camera's
  rectangle of the picture, and the effects work in the camera's own pixels (the pixelate grid, the lens, the vignette, the grain and
  the dither start at the corner of the rectangle), so two players side by side can have a `retro` look on one half and none on the
  other. The depth prepass and the sprite coverage image of an outline are made per camera, the size of its rectangle, and the
  automatic exposure measures and adapts per camera; the outline no longer skips a split screen or a partial viewport (and no
  longer warns). Where the rectangles do not tile the picture a `post-base` pass draws the plain picture first. The bloom and the
  colour filter stay one per frame, from the camera that draws first. A frame without stacks, or with all effects off, is the same
  frame, byte for byte, with no extra pass. The prepass, coverage and exposure-luma images are now named `camera:<n>/prepass`,
  `camera:<n>/sprite-coverage` and `camera:<n>/exposure-luma` in `render.frame_graph` (docs/RENDERING.md, "Post-processing").
- **Deprecated:** `Camera.bloom`, `bloomThreshold`, `bloomIntensity`, `bloomRadius`, `bloomScreenSpace` and `Camera.colorFilter`
  keep drawing exactly the same picture (they stand in for a PostProcess on a camera that has none), but warn once and will be
  removed two minor versions after the release that ships them. Migration: add a `PostProcess` to the camera's entity and set
  `bloomEnabled`, `bloomThreshold`, `bloomIntensity`, `bloomRadius`, `bloomScreenSpace`, and `colorFilterEnabled` with
  `colorFilterMode`. A camera with a `PostProcess` of its own ignores the old fields.
- **HDR display output, platform side:** with `SceneSettings.hdrOutput` `auto`, a Mac or iPhone (iOS 16+) window on a screen with
  extended dynamic range switches its swapchain to 16-bit float EDR (extended linear sRGB), and back when the window moves to a
  screen without it. Windows reads the monitor's HDR state and luminances (DXGI 1.6) and switches to scRGB, or to HDR10 where
  the driver refuses scRGB. The new `render.output` command says what the window shows (encoding, swapchain format, peak nits, paper white,
  headroom) and why not HDR; `render.supports` answers `hdrOutput` from the display the window is on (docs/RENDERING.md,
  "HDR output").
- **HDR display output, the picture:** on an HDR output the tonemap of a camera's `PostProcess` goes above paper white, up to
  the display's headroom (the SDR curve below its shoulder, then a roll-off toward the headroom that meets it smoothly), and
  the present pass encodes the frame for the swapchain: extended linear sRGB on Metal (EDR), scRGB (`paperWhiteNits / 80`)
  or HDR10 (PQ, Rec.2020) on D3D11, which now switches too. The HUD, a camera without exposure or tonemap and a
  colour-filtered frame stay at paper white, and `render.output`'s `status` says when the picture does. A game that asks for
  HDR builds the 16-bit present pipeline before its first frame; a game in the standard range asks the display every 120
  frames instead of every frame (docs/RENDERING.md, "What goes above white").
- **Depth and normal prepass:** the opaque meshes of the camera can be drawn once more into a float image of their own (view depth,
  view-space normal, coverage; never multisampled) for the effects that will need the depth (ambient occlusion, reflections, fog, sun
  shafts, depth of field, motion blur, outline). A frame without such an effect makes no image, declares no pass and draws the same
  number of times as before. Only the depth outline reads it so far; you also see it with `FA_RENDER_DEBUG_VIEW=depth` or `normals`
  (C++: `Renderer::set_debug_view`). Custom materials get `prepass` and `prepass_skin` programs (six programs a material instead of
  two to four): their `vertex()` and `alphaMode` `"clip"` apply there too, so the compiled shaders of custom materials must be made again
  (`factoria validate`). `render.supports` answers `sampledDepth` from the formats this GPU renders to and samples (docs/RENDERING.md,
  "Depth and normals").
