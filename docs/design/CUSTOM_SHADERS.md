# Design: custom shaders per material

Status: **accepted** (2026-10-18); packages 1-4 built. Closes the M18 item "Custom shaders per material: not built"
(feedback/ROADMAP.md, M18 "Left open"). Written against `m18/integration` (`7b5450a`): `mesh.glsl` with the PBR
`mesh` and `mesh_skin` programs, instanced batches (`mesh_batch.h`), `shadow.glsl`.

This is a design document for engine developers. It is not embedded documentation for game makers: that is
`docs/SHADERS.md`, written by package 5 below.

## The problem in one paragraph

Shaders are GLSL annotated for sokol-shdc, compiled offline by `tools/shaders/compile_shaders.sh` into committed C
headers (`engine/render/src/shaders/*.glsl.h`) for GL 4.3, GLES3/WebGL2, Metal (macOS, iOS, simulator), HLSL5 and WGSL.
The runtime has no shader compiler. A game (written by an AI) wants its own look for some meshes: water, dissolve,
holograms, wind on grass, toon lighting. It must write the shader once, see it in the editor at once, get errors that
point at its own lines, and have it work on every target an export makes, without a compiler in the shipped game.

## Decisions (summary)

| # | Question | Recommendation | Main alternative and why not |
|---|---|---|---|
| D1 | What the author writes | A **surface snippet**: a GLSL function `surface()` (and optionally `vertex()`, later `light()`) that the engine injects into its own mesh shader. The engine keeps instancing, skinning, shadows, lights, fog and IBL. | Full GLSL vertex + fragment shaders: the author must re-implement the instance matrix, skin palette, light arrays, shadow map and fog, all of which are engine internals that change between versions. An AI gets this wrong often and every engine change breaks games. Kept as a possible later escape hatch, if `ENGINE_FEEDBACK.json` asks for it. |
| D2 | How it is compiled | **sokol-shdc as a developer tool**, run by `fa_tooling` in the editor, `factoria run`, `factoria validate` and `factoria export`. The shipped game contains compiled shader **source per backend** plus reflection JSON; the GPU driver compiles that source at load time, exactly as it already does for the engine's own shaders. | SPIRV-Cross + glslang inside the runtime: several MB in every player (the web build included), compile time on phones, and errors found on the player's device instead of the author's machine. A hand-written translator: no. |
| D3 | Where sokol-shdc comes from | A **pinned** sokol-tools-bin commit, checked by SHA-256 (like the AppImage tools in `setup.h`): bundled next to `factoria` in the release downloads, and installable with `factoria setup shaders` for source builds. `compile_shaders.sh` uses the same pin. | Building sokol-shdc from source in CMake: it needs glslang, SPIRV-Tools, SPIRV-Cross and Tint; far more build time than the engine itself. |
| D4 | What the material is | A **material asset** `*.material.json`: the shader file, lighting model, alpha mode, typed parameters with defaults and doc strings, textures. `MeshRenderer.material` names it; `MeshRenderer.materialParams` overrides values per entity. | Parameters declared inside the GLSL with a custom annotation syntax: a second language to learn and parse; JSON already has schemas, JSON pointers in errors and the editor's widgets. |
| D5 | What ships | Per material and per backend dialect of the target, one twin file `<material>.json.<slang>.shader` (the `x.png` -> `x.png.ktx2` convention). The snippet `.glsl` itself does not ship. | Shipping the snippet and compiling at load: needs D2's rejected runtime compiler. |
| D6 | Hot reload | The existing `Engine::poll_hot_reload` sees the `.material.json` or snippet change, the injected compiler rebuilds it (host dialect only), the renderer swaps the program. A failed compile keeps the last good program and logs the teaching error once. | A file watcher in the editor only: `factoria run` and MCP sessions would not reload. |
| D7 | Instancing, skinning, shadows | Per material the generator makes up to four programs: `mesh`, `mesh_skin`, and when the material moves vertices or cuts holes `shadow` and `shadow_skin`. Materials join the batch key; per-entity overrides split batches only when they differ. | One program per material without shadow variants: displaced or cut-out surfaces would cast the wrong shadow. |

The user's choices on the open points are at the end ([Decisions taken](#decisions-taken)).

## What the author writes

### The material file

`materials/water.material.json` (schema `schemas/material.schema.json`, embedded like the others):

```json
{
  "format": "factoria.material/1",
  "doc": "Animated water: scrolling normal map, depth-tinted color, foam on the crests.",
  "shader": "shaders/water.surface.glsl",
  "lighting": "pbr",
  "alphaMode": "blend",
  "doubleSided": false,
  "params": {
    "deepColor":  { "type": "color", "default": [0.02, 0.15, 0.3, 0.9], "doc": "Color of deep water." },
    "waveHeight": { "type": "float", "default": 0.15, "min": 0.0, "max": 2.0, "doc": "Crest height in meters." },
    "flow":       { "type": "vec2",  "default": [0.05, 0.02], "doc": "Scroll speed of the normal map, UV per second." }
  },
  "textures": {
    "waves": { "default": "textures/water_normal.png", "sampler": "linearRepeat", "doc": "Tangent-space normal map." },
    "foam":  { "default": "textures/foam.png", "sampler": "linearRepeat", "doc": "Foam mask (r)." }
  }
}
```

- `lighting`: `"pbr"` (the engine's Cook-Torrance, what `MeshRenderer` draws today), or `"unlit"` (a later
  `"custom"` is sketched as package 6).
- `alphaMode`: `"opaque"`, `"clip"` (with an `alphaCutoff` param, default 0.5: `discard` below it, in the shadow pass
  too) or `"blend"` (drawn with the blended meshes, far to near).
- Parameter types: `float`, `vec2`, `vec3`, `vec4`, `color` (a `vec4` the editor shows as a color picker). Only float
  types, so that sokol-shdc can flatten the block for GL (it flattens uniform blocks of floats into `vec4` arrays; ints
  would need per-uniform reflection on GL). At most 16 parameters (each padded to a `vec4`: 256 bytes); they are laid out
  in **alphabetical order** so the C++ packer and the generated block agree without depending on JSON key order.
- At most 4 textures (fragment stage). The engine binds 6 already; 10 stays under the 16 texture units GLES3 and WebGL2
  guarantee. `sampler`: `linear`, `linearRepeat`, `nearest`, `nearestRepeat` (the engine's `SamplerKind`s).
- Every param and texture needs `doc` (the docs rule: the doc strings ARE what AIs read; `material.info` returns them).
- Names: GLSL identifiers, not starting with `fa_` and not a GLSL keyword; the error states the rule with a valid
  example.

### The snippet

`shaders/water.surface.glsl` is plain GLSL 450 (Vulkan style, what sokol-shdc reads), with no `@` tags and no `main`:

```glsl
// Moves the vertices (optional). Runs after instancing and skinning, in world space.
void vertex(inout VertexData v) {
    v.world_pos.y += sin(v.world_pos.x * 1.7 + fa_time.x * 2.0) * waveHeight;
}

// Changes the surface the engine lit (required). `s` arrives filled with the standard MeshRenderer result
// (texture * color, normal map, metallic/roughness maps, occlusion, emissive), so a snippet only changes what it needs.
void surface(in SurfaceInput i, inout Surface s) {
    vec2 uv = i.uv + flow * fa_time.x;
    vec3 n = texture(sampler2D(waves, waves_smp), uv).xyz * 2.0 - 1.0;
    s.normal = fa_tangent_normal(i, n);
    s.albedo = deepColor.rgb;
    s.alpha = deepColor.a;
    s.emission += vec3(texture(sampler2D(foam, foam_smp), uv * 3.0).r) * 0.2;
    s.roughness = 0.08;
}
```

The contract, defined once in the engine template (package 1) and documented in `docs/SHADERS.md`:

```glsl
struct SurfaceInput {           // read-only, per fragment
    vec3 world_pos;
    vec3 world_normal;          // interpolated geometric normal, normalized, flipped on back faces
    vec4 world_tangent;         // xyz tangent, w handedness
    vec2 uv;                    // after MeshRenderer.uvScale
    vec3 view_dir;              // surface -> camera, normalized
    bool front_facing;
};
struct Surface {                // what the lighting reads
    vec3 albedo;  float alpha;
    vec3 normal;                // world space, normalized by the engine after surface()
    float metallic; float roughness; float occlusion;
    vec3 emission;
};
struct VertexData {             // vertex(): world space, after instancing and skinning
    vec3 world_pos; vec3 world_normal; vec4 world_tangent; vec2 uv;
    vec3 object_pos;            // the model-space position (read-only by convention)
};
// Engine values a snippet may read (all start with fa_):
//   fa_time        x = seconds of game time since the scene started (paused with time.scale 0), multiply by 6.2831853 for radians
//   fa_camera_pos  xyz
//   fa_tangent_normal(i, n)   a tangent-space normal (-1..1) to world space
// Material params are globals named as in the JSON (`waveHeight`); textures are `texture2D <name>` with sampler
// `<name>_smp`.
```

Why the snippet starts from the standard result: the most common custom materials change one thing (an emission
pulse, a dissolve `discard`, a tint by height). They should be three lines, and they keep working with the
`MeshRenderer` fields and glTF materials an AI already set.

`fa_time` comes from the renderer's `update(world, dt)` (the same `dt` that steps `SpriteAnimator` and particles), so
headless screenshots are deterministic. Ceiling: a float of seconds loses sub-millisecond precision after a few hours of
play; documented, with the advice to use periodic functions.

## How it is compiled

### The template (engine side)

`mesh.glsl` becomes the template of every mesh program. Its code is split with sokol-shdc `@block`s and files that
`@include` each other:

- `mesh_common.glsl`: uniform blocks, varyings, `shade_vertex`, shadow lookup, environment, light loop. Every engine
  identifier is renamed to the `fa_` prefix (`fa_shadow_factor`, `fa_environment`, `FA_PI`, uniform members
  `fa_camera_pos`...), so the one rule "names starting with `fa_` are the engine's" replaces a list of reserved names.
  The renaming is mechanical (the generated C structs change field names in `renderer.cpp`).
- Hook points in `shade_vertex` (`vertex(v)` when `FA_HAS_VERTEX` is defined) and in the fragment `main`
  (`surface(i, s)` after the standard surface is computed, before lighting).
- `mesh_default.glsl`: the default `surface()` (does nothing) and the engine's programs. The built-in `mesh` and
  `mesh_skin` programs are this template with the default snippet, so **the engine and custom materials share one
  source of truth**: a custom material whose `surface()` is empty must render pixel-identical to a plain
  MeshRenderer (acceptance test).
- `shadow.glsl` gets the same treatment: a variant that runs `vertex()` and, for `alphaMode: "clip"`, outputs the
  varyings and runs `surface()` to `discard` below the cutoff.
- A `fa_time` member is added to `mesh_vs_params` and `mesh_fs_params`.
- The material uniform block is `layout(binding=5) uniform fa_material` in the fragment stage, and when the material
  has `vertex()` the same members again as `layout(binding=4) uniform fa_material_vs` in the vertex stage (a sokol
  uniform block slot belongs to one stage; bindings 0-3 are taken). Material textures use view bindings 6-9 and
  sampler bindings 2-5.

The template `.glsl` files are embedded in the `factoria` binary next to the docs and templates (the
`FA_EMBED_*` globs in `tools/common/CMakeLists.txt`), so an installed `factoria` has them without a checkout.

### The generator (tooling side)

For one material, `fa_tooling` writes into a temporary folder: the template files, the snippet, and a top file:

```glsl
@module fa_mat
@block fa_user
layout(binding=5) uniform fa_material {           // alphabetical, every param starts a new vec4
    vec4 deepColor;
    vec2 flow; float fa_pad0; float fa_pad1;
    float waveHeight; float fa_pad2; float fa_pad3; float fa_pad4;
};
layout(binding=6) uniform texture2D waves;   layout(binding=2) uniform sampler waves_smp;
...
<the snippet, verbatim>
@end
@include mesh_common.glsl
@program mesh vs fs
@program mesh_skin vs_skin fs
@program shadow shadow_vs shadow_fs          // only with vertex() or alphaMode "clip"
@program shadow_skin shadow_vs_skin shadow_fs
```

and runs `sokol-shdc --format bare_yaml --errfmt gcc --slang <dialects> --defines FA_HAS_VERTEX:...`. `bare_yaml`
writes the cross-compiled source of each program and dialect plus a YAML reflection file (binding slots per backend:
HLSL registers, MSL buffer/texture/sampler indices, GL names of uniforms and texture-sampler pairs, attribute
semantics). The tooling converts the YAML to JSON (a reader for exactly the structure sokol-shdc writes, tested on
fixtures; there is no YAML library in the engine and none is needed for anything else) and writes the twin.

The twin `materials/water.material.json.hlsl5.shader`:

```json
{
  "format": "factoria.shader/1",
  "engine": "0.2.0", "template": "<sha256 of the template files>",
  "slang": "hlsl5",
  "params": ["deepColor", "flow", "waveHeight"],
  "programs": {
    "mesh":      { "vs": "<source>", "fs": "<source>", "reflection": { ... } },
    "mesh_skin": { ... }, "shadow": { ... }, "shadow_skin": { ... }
  }
}
```

The runtime builds `sg_shader_desc` from it (`engine/render/src/custom_shader.cpp`). Attribute locations are the
template's, so `Gpu::mesh_pipeline` and `shadow_pipeline` keep their vertex layout code and only take the shader as a
new argument. A twin whose `engine` or `template` differs from the running player is refused with a teaching error
("re-export the game with this factoria version"); an export always makes players and twins of one version.

### Dialects per target

| Target | Backend | Dialects in the export |
|---|---|---|
| Windows | D3D11 | `hlsl5` |
| Linux | GL 4.3 core | `glsl430` |
| macOS | Metal | `metal_macos` |
| iOS | Metal | `metal_ios`, `metal_sim` (`build_ios.sh --simulator` uses the same export) |
| Android | GLES3 | `glsl300es` |
| Web | WebGL2 (sokol GLES3) | `glsl300es` |

Source, not bytecode: the engine's own shaders already ship as source (`compile_shaders.sh` does not pass `--bytecode`),
D3D11 compiles HLSL with `d3dcompiler_47.dll` (part of Windows 10+) and Metal compiles MSL with
`newLibraryWithSource`. `--bytecode` only works when the host matches the target (Windows for HLSL, macOS for Metal),
so it would make exports differ by host; it can come later as an optimisation of load time for both the engine's and
the game's shaders together. WGSL is not needed (the web export uses WebGL2).

### Where and when it runs

- **Editor, `factoria run`, MCP sessions** (anything started by `factoria`): the CLI and editor hand the `Engine` a
  `ShaderCompiler` callback (`EngineConfig::shaderCompiler`, a `std::function` like `VisualMeasure` is injected into
  `fa_scene`), because `fa_runtime` may not depend on `fa_tooling`. It compiles the **host dialect only**, synchronously
  at first use (so headless screenshots and tests are deterministic) and again on hot reload. Results are cached in
  `.factoria/shader-cache/<sha256>.<slang>.shader`; the key hashes the generated top file, the snippet, the template,
  the dialect and the sokol-shdc pin, so a cache hit runs no process. A compile takes a fraction of a second; a
  hitch of that size on save in the editor is accepted (an asynchronous compile can come if it is ever noticed).
- **`factoria validate`** compiles every material for **every dialect of every platform**, because some errors exist
  in one dialect only (a gradient inside a loop is fine in GLSL and refused by HLSL, the X3570 note in mesh.glsl).
- **`factoria export`**: a new asset step `convert_shaders(ea)` next to `convert_textures` and `convert_audio` in
  `prepare_game_assets` compiles the platform's dialects, adds the twins with `ExportAssets::replace` and drops the
  snippet `.glsl` files from the shipped list. A material that does not compile fails the export with the same error
  `validate` prints.
- **The exported player** has no `ShaderCompiler`: it reads the twins from `game/` or `game.pak` through `fa::fs`.
  A missing twin is a teaching error naming the material and the command that makes it.

### sokol-shdc: size, licence, distribution

- Prebuilt binaries from `github.com/floooh/sokol-tools-bin` (no release tags: a pinned commit). Sizes at
  `b975d56` (2026-10-11): Windows 7.7 MB, Linux x64 11.1 MB, Linux arm64 11.2 MB, macOS x64 11.8 MB, macOS arm64
  11.5 MB. One per host goes into each `factoria` download (+8-12 MB); nothing goes into games.
- Licence: sokol-tools is MIT. The binary statically links glslang, SPIRV-Tools, SPIRV-Cross and Tint, whose licences
  (BSD-3-Clause, Apache-2.0 and the others glslang lists) must be added to the notices of the **factoria** downloads.
  Package 2 copies the exact texts from those projects at the pinned versions. Games do not contain it, so
  `FACTORIA_NOTICES.txt` of exported games does not change.
- Lookup order: `$SOKOL_SHDC`, next to the `factoria` executable, `~/.factoria/tools/sokol-shdc/<commit>/`
  (installed by the new `setup` component `shaders`, SHA-256 checked per host). `compile_shaders.sh` uses that same
  folder instead of `.cache/sokol-tools-bin`, so engine developers and games share one pinned binary.
- The pin must produce code that matches `external/sokol/sokol_gfx.h` (the shader desc layout changes with sokol
  versions). `compile_shaders.sh` clones the default branch today, unpinned: package 2 pins it to the same commit and
  a test checks that the script and `setup.h` name the same one (like the AppImage pins).
- Hosts without a binary (none of the five desktop hosts lacks one today): validation and export say so and how to
  set `SOKOL_SHDC`.

## Errors that teach

- **Material JSON**: JSON-pointer errors through the schema and a checker (`/params/waveHeight/default: expected a
  number, got "0.15"`; `/textures: 5 textures, at most 4 (the engine binds 6 of the 16 units GLES3 and WebGL2
  guarantee)`; an unknown `lighting` with `did_you_mean`).
- **Snippet compile errors** come from glslang through sokol-shdc as `file:line:col: error: ...`. The generator maps
  them back to `shaders/water.surface.glsl:<line>` with the offending line quoted, through the generator's own table
  of where it put the snippet in the top file (a `#line` directive is not relied on: whether glslang honours it inside
  an sokol-shdc `@block` is unknown, and the table always works). An error outside the snippet (rare: the author broke the contract, e.g. redefined `main`) says so and
  names the rule.
- **Hints for the frequent mistakes**, matched on glslang's message: an unknown field of `Surface`/`SurfaceInput`/
  `VertexData` -> `did you mean s.albedo?` (`fa::did_you_mean` over the struct fields); an undeclared identifier that
  is a param or texture of another material, or a misspelled param -> did-you-mean over this material's params;
  `texture(waves, uv)` -> "textures and samplers are separate: `texture(sampler2D(waves, waves_smp), uv)`"; a missing
  `surface` -> the signature to write; an `fa_` name declared by the snippet -> the prefix rule.
- **Driver errors at load time** (D3DCompile, Metal, GL driver) refer to generated code. They should not happen when
  validation passed, but if one does, the renderer logs one error naming the material, the backend and the driver
  message, and draws the material with the **error material** (unlit magenta: an AI looking at a screenshot sees at
  once which mesh is wrong). The same error material is used for a failed compile without a last good program.
- **Where errors appear**: the log (once per material and change), `factoria validate`, the `shader.compile` command
  (below) and the editor console. `debug_state` / the render stats list materials that fell back to the error material.

## Runtime: MeshRenderer, batching, skinning, shadows

### Components

`MeshRenderer` gains two reflected fields (with doc strings, regenerated in COMPONENTS.md and the typings):

```cpp
std::string material;                 // "" = the standard material; else a *.material.json
Json materialParams = Json::object(); // per-entity overrides of the material's params and textures: {"deepColor": [0,0.2,0.4,1]}
```

All existing fields keep their meaning and feed the standard surface the snippet starts from (`texture`, `color`,
`normalMap`, `metallic`, `roughness`, `emissive`, `uvScale`). `unlit` true forces `lighting: "unlit"`.
`castShadows`/`receiveShadows` are unchanged. `alphaMode` of the material wins over `color.a < 1` (which today makes a
mesh blended).

Scripts change values through the reflected field (`mr.materialParams = {deepColor: [0, 0.2, 0.4, 1]}`), so a
change is saved, diffable and undoable like every other field. No extra JS helper.

### Assets

`Assets` gets a material cache (path -> `MaterialAsset`: parsed JSON, packed default params, texture assets, the
`sg_shader` of each program, a generation number). Loading a material: parse and check the JSON, then get the twin
for this backend's dialect from `fa::fs` or from the injected compiler, then make the shaders. `Assets::reload(path)` of
a `.material.json` or of a snippet used by a material rebuilds it in place (the `MeshRenderer` keeps the path; the
renderer looks the asset up every frame as it does for textures). On failure the previous programs stay.

### Pipelines

`Gpu::mesh_pipeline(blended, doubleSided, skinned)` and `shadow_pipeline(skinned)` take the material's shader. The
`PipelineKey` (a `uint32_t` today) gets the material's slot in the asset table; pipelines of a material are destroyed
when it reloads. Attribute layouts are unchanged (the template keeps every location).

### Batching

`material_key` in `mesh_batch.cpp` adds the material asset pointer and a hash of the entity's `materialParams`
(an entity without overrides hashes to 0). Many entities with one material and no overrides stay one instanced draw
per mesh part, as today. Per-instance custom data (a color per instance inside one draw) is not in this design: it
needs a wider instance buffer; listed under "Left open".

### Draw

For a batch with a material: the same bindings as today plus the material's textures (views 6-9, samplers 2-5;
an override texture from `materialParams` replaces the default) and `apply_uniforms` of `fa_material` (and of
`fa_material_vs` when the material has `vertex()`) with the packed params.
`fa_time` goes into the vertex and fragment params of every mesh draw.

### Skinning

Nothing special: `mesh_skin` of the material is generated with the same snippet; the `vertex()` hook runs after the
skin and instance matrices (in `shade_vertex`), so one snippet works on static, instanced and skinned meshes. A skinned
item already never joins a batch (its `Animator` is in the key).

### Shadows

- No `vertex()` and not `"clip"`: the material uses the engine's `shadow` / `shadow_skin` programs (the common case:
  no extra programs, no extra cost).
- With `vertex()`: the generated shadow programs run the same hook, so a wave casts the shadow of the wave.
- With `"clip"`: the shadow programs output the varyings and run `surface()` with the standard surface, then
  `discard` below `alphaCutoff`, so leaves cast leaf-shaped shadows. The shadow pass binds the material's textures
  for those draws.
- `"blend"` materials cast like blended meshes do today (solid).

## Commands and editor

- `shader.compile` `{material, platforms?}` -> `{ok, dialects: [...], errors: [{file, line, column, message, hint}]}`.
  Read-only; compiles every dialect of the given platforms (default: all) and is what `validate` calls. An AI uses it
  in a loop until `ok`, then takes a `game.screenshot`.
- `material.info` `{material}` -> lighting, alphaMode, params (type, default, range, doc), textures, which programs
  exist, compile state on this backend. Read-only.
- No `material.create`/`set` commands: materials are JSON files an AI writes directly, like scenes; the schema and
  `validate` check them.
- Editor: the MeshRenderer inspector shows the material's params with widgets by type (color picker, sliders when
  `min`/`max` exist) writing `materialParams`, a button to open the snippet, and the compile error under the field.
  Saving a snippet in an external editor reloads it through hot reload.

## Out of scope (recorded so nobody assumes it)

- Custom shaders for `Sprite`/`Shape2D` (quad.glsl), the sky, particles, and custom post-processing. The same
  machinery (template + snippet + twins) applies; each is its own package when a game asks.
- A full-GLSL escape hatch (D1).
- Compute shaders, tessellation, geometry shaders (not in sokol_gfx's common subset for these backends anyway).
- Vertex-stage textures (heightmaps sampled in `vertex()`): a texture in both stages needs a second binding; later.
- Per-instance material data inside one instanced draw.
- A node-graph shader editor.

## Work packages

Sizes as in ROADMAP.md (S under a day, M 1-3 days, L a week+). Order: 1, then 2; 3 and 4 in parallel once 2 has
fixed the twin format; 5 last. 6 is a sketch for when a game asks for it.

### P1. Template refactor of mesh.glsl and shadow.glsl (M, render)

- Split `mesh.glsl`/`shadow.glsl` into the template files with the hook points; `fa_` prefix for every engine
  identifier; `fa_time` uniform; material block/textures not declared by the default program. Regenerate the headers
  with `compile_shaders.sh` (which learns `@include` paths: `--input` of the top file, includes relative to it).
- Embed the template files in `fa_tooling` (`FA_EMBED_*`).
- Renderer: fill `fa_time` from the accumulated `update` dt.

Acceptance:
- Every existing render golden test passes unchanged (render3d, skinning, shadows, instancing).
- A doctest checks that the embedded template files equal the ones in `engine/render/shaders/` (no drift).
- A golden test with an emission driven by `fa_time` after `n` fixed steps is identical on two runs.

### P2. Shader compiler in tooling (M-L, tooling)

- sokol-shdc lookup and the `shaders` setup component (pinned commit, SHA-256 per host, docs/EXPORTING.md "Setting up
  this computer"); pin `compile_shaders.sh` to the same commit; add the licences to the factoria downloads' notices.
- `fa/tooling/shaders.h`: parse and check `*.material.json` (schema `schemas/material.schema.json`), generate the top
  file, run sokol-shdc through `ProcessRunner` (replaceable in tests, like setup), map errors and add hints, convert
  the YAML reflection to JSON, write twins, cache by hash.
- Commands `shader.compile`, `material.info`; `validate` compiles every material for all dialects.

Acceptance (doctests with real sokol-shdc where available, else skipped with a message; CI has it):
- A fixture material compiles to `hlsl5`, `glsl430`, `glsl300es`, `metal_macos`, `metal_ios`, `metal_sim`; the twins
  parse and list the four programs only when `vertex()` or `"clip"` is used.
- An error on line 7 of the snippet is reported as `shaders/bad.surface.glsl:7:<col>` with the line quoted, from both
  the vertex and the fragment stage (only once).
- `s.colour = ...` -> hint `did you mean albedo?`; `texture(waves, uv)` -> the separate-sampler hint; a snippet that
  declares `fa_foo` -> the prefix rule; 5 textures -> the limit error with its reason; `/params/x/default` of the wrong
  type -> a JSON-pointer error.
- A second compile of an unchanged material starts no process (the injected runner counts calls).
- A test checks that `compile_shaders.sh` and `setup.h` pin the same sokol-shdc commit.

Built (2026-10-18), with what the real tool showed:
- `fa_user` is included by both `@vs` and `@fs`, so the generated block is split with `GL_VERTEX_SHADER` /
  `GL_FRAGMENT_SHADER` (glslang defines one per stage): `fa_material_vs` (binding 4) and `vertex()` in the vertex stage,
  `fa_material` (binding 5) and `surface()` in the fragment stage, helpers in both (with `texture()`/`discard` shims in
  the vertex stage, undefined again after the snippet). A texture sampled in `vertex()` is an error (out of scope).
- `alphaCutoff` is implicit for `"clip"` (float, default 0.5, 0..1, counts toward the 16); a material may declare it to
  change default, range or doc. The generator defines `FA_ALPHA_CLIP`. **P3 must make the template read it**: `discard`
  below `alphaCutoff` after `surface()` in `fs`, and `shadow_fs` running `surface()` for clip materials (today the
  generated shadow programs equal the default ones).
- glslang reports column 0; the column is found from the quoted token. `fa_` names and a missing `surface()` are caught
  before sokol-shdc runs (glslang says nothing useful about them). `colour` is not near `albedo` by edit distance, so the
  hint uses a small alias table before `did_you_mean`.
- Windows Defender quarantines the pinned `sokol-shdc.exe` (`Trojan:Win32/Bearfoos.B!ml`, an ML false positive):
  the setup status, install and compile errors say how to restore it. Bundling sokol-shdc in the
  release downloads (D3) is not done yet: it changes `release.yml`.

### P3. Materials in the renderer and runtime (L, render + runtime + scene)

- `MeshRenderer.material`, `MeshRenderer.materialParams` (docs, COMPONENTS.md, typings).
- `MaterialAsset` cache, `custom_shader.cpp` (twin JSON -> `sg_shader_desc`), the error material, pipelines keyed by
  shader, `material_key`, bindings and uniforms, alpha modes, shadow variants, hot reload through `Assets::reload`.
- `EngineConfig::shaderCompiler`; the CLI and editor pass the tooling's compiler; render stats count materials and
  fallbacks.

Acceptance (headless GPU tests on D3D11 WARP and llvmpipe; goldens):
- A material with an empty `surface()` renders pixel-identical to the same MeshRenderer without a material.
- An emission-from-param material renders its golden; a `materialParams` override changes it.
- 100 cubes with one material and no overrides: one batch (`stats.meshBatches`); two different overrides: two batches.
- A skinned glTF with a material renders its golden and casts its shadow.
- A plane displaced by `vertex()` casts the displaced shadow; a `"clip"` material casts a shadow with the holes.
- A material whose snippet does not compile: the error material is drawn, one error is logged with file:line.
- Hot reload: changing the snippet on disk and polling gives the new image; a broken edit keeps the last good image and
  logs once; fixing it again recovers.
- A twin of another engine version is refused with the re-export hint.

Built (2026-10-19):
- The template hash is computed by CMake (engine/render/CMakeLists.txt, CRs stripped, the shaders are checked out with LF
  through .gitattributes) and returned by `fa::mesh_template_hash()`; the tooling's `shader_template_hash()` returns the
  same value, so the twins and the player cannot disagree across hosts.
- `fs` and the clip `shadow_fs` share `@block fa_fs_surface` (engine textures, `fa_mesh_fs_params`, the varyings,
  `fa_standard_surface`); sokol-shdc honours `@include_block` inside `#ifdef`. The clip shadow program declares
  `fa_mesh_fs_params`, `fa_material`, views 0 and 2-5 plus the material's, samplers 0 and the material's, and no
  `fa_lights` / `fa_shadow_tex`: the renderer records the slots each program declares and binds only those.
- Render tests use committed twins (engine/render/tests/data/materials, hlsl5 and glsl430) because sokol-shdc does not
  run everywhere; the tests stamp the running engine version into them, and a tooling doctest (real sokol-shdc only)
  fails when they no longer match the template (`FA_UPDATE_FIXTURES=1` rewrites them).
- `RenderStats` gained `materials` and `materialFallbacks`; `asset_report` lists every material with `ok`, `generation`
  and its last error. The sokol shader pool grew from 32 to 256 (four programs per material).
- The editor runs with hot reload off: saving a snippet in an external editor reloads it in `factoria run` and MCP
  sessions, not yet in the editor (package 5).

### P4. Shaders in exports (M, tooling)

- `convert_shaders(ea)` in `prepare_game_assets`, dialects per the table above; snippets dropped; export fails on a
  compile error; `ExportReport` lists the materials.

Acceptance:
- Exporting a fixture project for linux, windows, android and web: the output (folder, `game.pak`, APK assets, web
  pack) contains `materials/*.material.json.<slang>.shader` for exactly the target's dialects and no `.surface.glsl`.
- The exported player started headless on the fixture (D3D11 on Windows CI, GL on Linux CI) renders the P3 golden from
  `game.pak`. The web player renders it in headless Chrome (the M17 CI job).
- A project with a broken snippet fails the export with the same error `factoria validate` prints.

### P5. Docs, schema, editor, example (M)

- `docs/SHADERS.md` (game makers: material file, contract, every `fa_` value, five worked examples: pulse emission,
  dissolve with `"clip"`, scrolling water, wind on grass with `vertex()`, rim light), links from COMPONENTS.md,
  AI_GUIDE.md and the generated `AGENTS.md`; ARCHITECTURE.md "Rendering" section; EXPORTING.md; CHANGELOG.md in
  plain words.
- The editor inspector of `material`/`materialParams`, the error under the field, the editor autotest step.
- One example game uses a material (gem-roller: a pulsing gem), so CI smoke runs exercise it on every platform; its
  `ENGINE_FEEDBACK.json` records what was missing.

Acceptance: `factoria validate` passes on the examples; the schema accepts the docs' examples (a test reads them from
SHADERS.md); the editor autotest edits a param and the screenshot changes.

### P6. Custom lighting (M, when a game asks)

`"lighting": "custom"`: the snippet adds `vec3 light(in SurfaceInput i, in Surface s, in LightSample l)` (direction to
the light, color times intensity, attenuation, shadow factor), called by the engine's light loop instead of
Cook-Torrance; ambient, emission and fog stay the engine's, and the sky reflection (IBL) is off for custom lighting
(a toon look does not want it; a snippet can add its own term to `s.emission`). Like the full-GLSL escape hatch, it
waits for an `ENGINE_FEEDBACK.json` entry; the template's light loop is written so that the hook fits later. This is what toon and stylised
games ask for first.

Acceptance: a two-band toon material renders its golden with a directional and a point light, and its shadow.

## Risks

- **Driver differences** on targets CI does not run (Metal, GLES3 phones; M18 "Left open" already lists them for the
  engine's shaders). The cross-compiled code comes from the same sokol-shdc as the engine's own shaders, so a game's
  snippet adds no new class of risk, only more code.
- **sokol version coupling**: a sokol update needs the shdc pin, the committed headers and the twin `template` hash
  moved together; one test catches a mismatch, and twins carry the versions they were built with.
- **Compile time in validate**: all dialects of all materials. Cached by hash, so only changed materials pay.

## Decisions taken

The user took the five recommendations on 2026-10-18:

1. **Surface snippet only, no full-GLSL shaders in the first version** (D1). Some effects (a custom vertex layout,
   multi-pass) wait for a later escape hatch.
2. **sokol-shdc bundled in the factoria downloads (+8-12 MB per host), and the game ships cross-compiled source**
   (D2, D3), no compiler in the players.
3. **Material = a `*.material.json` file + per-entity `materialParams`** (D4), no shader/material split; a second
   material reusing a snippet repeats its param declarations.
4. **Custom lighting (P6, toon) waits for a game that asks** (an `ENGINE_FEEDBACK.json` entry); the template leaves
   room for the hook.
5. **Error material = unlit magenta**, never a silent fallback to the standard material.
