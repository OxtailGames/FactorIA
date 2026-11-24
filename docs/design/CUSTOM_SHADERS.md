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
| D1 | What the author writes | A **surface snippet**: a GLSL function `surface()` (and optionally `vertex()`, later `light()`) that the engine injects into its own mesh shader. The engine keeps instancing, skinning, shadows, lights, fog and IBL. | Full GLSL vertex + fragment shaders: the author must re-implement the instance matrix, skin palette, light arrays, shadow map and fog, all of which are engine internals that change between versions. An AI gets this wrong often and every engine change breaks games. Built later as an opt-in escape hatch, `"mode": "full"` ([CUSTOM_SHADERS_FULL.md](CUSTOM_SHADERS_FULL.md)). |
| D2 | How it is compiled | **sokol-shdc as a developer tool**, run by `fa_tooling` in the editor, `factoria run`, `factoria validate` and `factoria export`. The shipped game contains compiled shader **source per backend** plus reflection JSON; the GPU driver compiles that source at load time, exactly as it already does for the engine's own shaders. | SPIRV-Cross + glslang inside the runtime: several MB in every player (the web build included), compile time on phones, and errors found on the player's device instead of the author's machine. A hand-written translator: no. |
| D3 | Where sokol-shdc comes from | A **pinned** sokol-tools-bin commit, checked by SHA-256 (like the AppImage tools in `setup.h`): bundled next to `factoria` in the release downloads, and installable with `factoria setup shaders` for source builds. `compile_shaders.sh` uses the same pin. | Building sokol-shdc from source in CMake: it needs glslang, SPIRV-Tools, SPIRV-Cross and Tint; far more build time than the engine itself. |
| D4 | What the material is | A **material asset** `*.material.json`: the shader file, lighting model, alpha mode, typed parameters with defaults and doc strings, textures. `MeshRenderer.material` names it; `MeshRenderer.materialParams` overrides values per entity. | Parameters declared inside the GLSL with a custom annotation syntax: a second language to learn and parse; JSON already has schemas, JSON pointers in errors and the editor's widgets. |
| D5 | What ships | Per material and per backend dialect of the target, one twin file `<material>.json.<slang>.shader` (the `x.png` -> `x.png.ktx2` convention). The snippet `.glsl` itself does not ship. | Shipping the snippet and compiling at load: needs D2's rejected runtime compiler. |
| D6 | Hot reload | The existing `Engine::poll_hot_reload` sees the `.material.json` or snippet change, the injected compiler rebuilds it (host dialect only), the renderer swaps the program. A failed compile keeps the last good program and logs the teaching error once. | A file watcher in the editor only: `factoria run` and MCP sessions would not reload. |
| D7 | Instancing, skinning, shadows | Per material the generator makes up to six programs: `mesh`, `mesh_skin`, `prepass` and `prepass_skin` (the depth and normal prepass of the effects that read the depth, run with the same `vertex()` and, for `"clip"`, `surface()`), and when the material moves vertices or cuts holes `shadow` and `shadow_skin`. Materials join the batch key; per-entity overrides split batches only when they differ. | One program per material without shadow variants: displaced or cut-out surfaces would cast the wrong shadow. |

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
- At most 4 textures, readable in both stages (M72.3: a texture is declared once per stage, see "Textures in `vertex()`").
  The fragment stage binds 6 engine textures already, so the material's go to view 6.. (10 in all, under the 16 texture
  units GLES3 and WebGL2 guarantee); the vertex stage adds 4 more at view 10.. (and 4 samplers at 6.., 10 samplers in all,
  under sokol's 12). `sampler`: `linear`, `linearRepeat`, `nearest`, `nearestRepeat` (the engine's `SamplerKind`s).
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
    vec4 vertex_color;          // interpolated vertex color (glTF COLOR_0), white without; already in the standard surface
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
    vec4 color;                 // the vertex color (white without)
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
  The renaming is mechanical (the generated C structs change field names in `renderer_*.cpp`).
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
@program prepass prepass_vs prepass_fs       // the depth and normal prepass, always
@program prepass_skin prepass_vs_skin prepass_fs
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
    "mesh_skin": { ... }, "shadow": { ... }, "shadow_skin": { ... }, "prepass": { ... }, "prepass_skin": { ... }
  }
}
```

The runtime builds `gpu::ShaderDesc` from it (`engine/render/src/custom_shader.cpp`). Attribute locations are the
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

**`spirv_vk` (M77, the Vulkan backend).** A seventh dialect, `spirv_vk`, is SPIR-V, which our own Vulkan backend consumes; the D3D12
backend compiles the `hlsl5` source it already has with `D3DCompile` (DXBC, no DXIL), so it needs no dialect of its own. It is not in
`shader_dialects()`: `validate` and an export do not compile it, because nothing in the player reads it yet. `shader_dialects_all()` lists
it, `ShaderCompileOptions::dialects` asks for it, and `shader_dialects_for(platforms, vulkan)` adds it for the platforms that can run
Vulkan (`shader_platform_has_vulkan`: windows, linux, android), which is what `ExportOptions::vulkan` does: macOS, iOS and the web never
ship it, and an export without the option ships what it always shipped. The twin of `spirv_vk` has the same keys as the others with
three differences: `"binary": "base64"` (each `vs`, `fs` or `cs` is the module's bytes in base64, a multiple of four, starting with the
magic number `0x07230203`), no source text, and the reflection's `spirv_set0_binding_n` (uniform blocks) and `spirv_set1_binding_n`
(views and samplers) as integers (sokol-shdc writes `0;`, with a semicolon; the tooling removes it). Compute materials and
meshes with storage buffers have a `spirv_vk` twin too. The material inspector reads `params` and `textures` only, which every dialect
has the same.

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
- **Too many textures in one program** (load time, the same on every backend: D3D11 and Metal could bind more, but a game
  must load everywhere): a stage reads at most 16 image-sampler pairs (the units GLES3 and WebGL2 guarantee), the two
  stages together at most 32 (sokol's cap). A program past the limit is refused with `the program '<material> <program>'
  reads too many image-sampler pairs for one stage ...: 17 in its fragment stage (the engine's own bindings take 8 (tex,
  ...), the material's own textures 9 (...))`: both stages when both are over, each with who takes how many. The material's
  own textures are told from the engine's by what the material declares (a vertex copy is `fa_vs_<name>`). The hint
  offers only what applies: drop the texture sampled in `vertex()` (when a vertex copy takes units), do not call
  `fa_scene_color()` (when the program reads the scene copy), merge maps into the channels of one texture.
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
per mesh part, as today. A value that differs per entity inside one draw is a param marked `"instanced": true`: its
name is left out of the hash, so entities that differ only in those values share the batch (see "Per-instance params and
vertex channels" below).

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

### The depth and normal prepass

Every material has the programs `prepass` and `prepass_skin` (docs/RENDERING.md, "Depth and normals"): the same vertex stage as `mesh`
(instancing, skinning, `vertex()`), and a fragment stage that runs `surface()` and writes the view depth and the view-space normal
(`s.normal`, so a normal map is in it). With `"clip"` it also discards below `alphaCutoff`, as the shadow programs do, so a cut-out
leaf is as cut in the depth as in the picture. Blended materials are not drawn in the prepass at all. The programs are optional in a
twin (a twin without them draws its meshes with the engine's prepass program: no `vertex()`, no holes); a twin that lists one that
does not build is an error, like a broken shadow program.

### Per-instance params and vertex channels

(M72.3, built.) Two additions of the mesh template; a material using neither gets exactly the program and the attributes it
always had, and the engine's own mesh programs are unchanged except for the template hash (the text of the template changed,
so every committed twin is rebuilt and games with custom materials re-export).

**Instanced params.** A param with `"instanced": true` is not in `fa_material` / `fa_material_vs`; each entity's value is
written into a per-instance buffer (vertex buffer 3, `vec4Count * 16` bytes per instance, step per instance) next to the
matrix buffer. Layout (`instance_layout`): alphabetical, first fit, in floats of a vec4 (a vec3 or vec4 never straddles
two vec4; a vec3 and a float share one); at most 3 vec4 (`kMaterialMaxInstanceVec4`, 12 floats), and the error on `/params`
names the instanced params and the fix. The 16-param limit counts only the params of the block. The twin lists
`"instanced": [{name, vec4, offset, components}]` and `"instanceVec4"` (absent when there are none; `"params"` lists only
the block's names). The attribute locations follow the matrix (9, or 11 after the joints and weights of a skinned program):
the instance vec4s, then uv1, then color1, so a skinned program with everything uses 16 attributes, sokol's limit. The
pipeline key needs no extra bits: the shader of a material fixes its layout.

The vertex shader copies the values to `flat` varyings and `fa_inst_begin()` unpacks them into plain globals named like the
params (`fa_instance_unpack`, generated); the fragment shader unpacks the varyings (`fa_inst_load()`); the snippet reads
`tint` in `vertex()` and `surface()` as it reads any param. The shadow and prepass programs run the same unpack when they
run `vertex()` (or clip), with their own attribute locations, so a vertex displaced by an instanced value is displaced the
same in all three passes.

Batching: the hash of `materialParams` ignores the instanced names (`MaterialHashCache`, keyed by the material's
`instancedKey` so a reloaded material invalidates it), so `build_batches` is unchanged; `pack_instance_extras` then packs
each batch's values, in the order of its matrices (visible and shadow-casting items), after the culling. A non-instanced
param still splits the batch.

**Declared vertex channels.** `"vertexAttributes": ["uv1", "color1"]` makes the generator declare `vertex_uv1` (vec2) and
`vertex_color1` (vec4) as globals of `vertex()` (copy them into `v.uv` / `v.color` to reach `surface()`), and the template
declare the attributes after the instance data (vertex buffers 4 and 5, per vertex; `color1` is 4 normalized bytes). Only
glTF meshes have them (`TEXCOORD_1`, `COLOR_1` as vec3 or vec4): a procedural mesh or a built-in primitive has neither.
A part without a declared channel is drawn with the error material, `note_failure("material-mesh", ...)` logs once per
material and mesh, naming the material, the mesh, the part and the glTF attribute, and the path joins
`stats.materialFallbacks`; the other meshes of the material draw normally.

Tests: tooling (the layout, the limits and their pointers, the generated top file, the six dialects with the real
sokol-shdc, the twin's keys), renderer ("materials: ..." cases: 100 entities with different instanced values are one batch
and one draw call with the right colours, a non-instanced param still splits, `vertex()` reading an instanced value moves the
shadow like a mesh standing there, a skinned glTF, a declared channel is drawn, a missing channel is magenta and logged
once).

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

## Kinds (M72)

M72 (custom shaders for everything) applies the same machinery (template + snippet + twin) to more than meshes. A
material says what it is for with the optional key `"kind"` of its `*.material.json`:

| `kind` | What it will be | Template file | Package |
|---|---|---|---|
| `"mesh"` (default) | the surface of a `MeshRenderer`: everything in this document | `mesh_common.glsl` | built |
| `"sprite"` | the 2D quad path: `Sprite`, `Shape2D`, `Tilemap`, `Text`, particles and trails, UI images | `quad_common.glsl` (+ `color_space.glsl`, `light_shadow.glsl`) | M72.1: template, tooling and the `Sprite` draw built (M72-P1, P3); `Shape2D`, `Tilemap`, `Text`, particles and UI built (M72-P5) |
| `"sky"` | the background of a 3D scene (`SceneSettings.skyMaterial`), also baked into the cubes that light the meshes ([P15](CUSTOM_SHADERS_KINDS.md#the-sky-material-lights-the-meshes-m72-p15)) | `sky_common.glsl` (+ `color_space.glsl`) | M72.1: built (M72-P6) |
| `"post"` | one pass of a camera's post-processing stack (`PostProcess.customPasses`) | `post_common.glsl` | M72.2: built (M72-P7a) |
| `"compute"` | compute shaders (storage buffers and storage images) | `compute_common.glsl` | built (M72.4); storage images M72.17 |

Built by M72.0 (the shared base): the key, its check, the per-kind template hash and the skeletons. Every kind compiles now.
A `kind` that is not one of the five is an error with "did you mean" and the
pointer `/kind` (`parse_material`, `schemas/material.schema.json`).

- **One template hash per kind.** `fa::material_template_hash(kind)` (the tooling's `shader_template_hash(kind)` returns
  the same value) hashes only the template files of that kind, as listed explicitly in `engine/render/CMakeLists.txt`
  (`FA_TEMPLATE_FILES_<KIND>`) and in `template_file_names()` of `tools/common/src/shaders_generate.cpp`; a doctest checks
  that both lists give the same hash and that every `*_common.glsl` is in one list. Editing the sprite template leaves
  every mesh twin valid. The mesh list is `mesh_common.glsl` plus the shared `light_data`, `light_loop`, `shadow_common` and `brdf_layers` files (M73-P0
  moved the lights out of it, M73.6a added the material layers, so every twin was regenerated each time). `compute` hashes `compute_common.glsl`
  (`FA_TEMPLATE_FILES_COMPUTE`).
- **The twin names its kind.** A twin of any kind other than mesh carries `"kind": "<kind>"`; a twin without the key is a
  mesh twin (so every twin made before M72 stays valid, and mesh twins are written as they always were).
  `build_material_checked` compares the twin's kind with the material file's and refuses a mismatch with the re-export
  hint, then checks the `engine` and `template` fields against the hash of that kind.
- **One contract per kind.** Each template declares its own structs, so a top file includes the template of one kind
  and the error hints read the fields from the right one: mesh `SurfaceInput`, `Surface`, `VertexData`; sprite
  `QuadInput`, `QuadSurface`, `QuadVertex`; sky `SkyInput`, `SkySurface`; post `PostInput`,
  `PostSurface`.
- **Programs per kind.** `MaterialAsset` stores its `kind` and `kMaxMaterialPrograms` (8) program slots; the programs a
  kind's twin carries are named by `material_program_names(kind)` (the six of a mesh material, `quad` and `quad_plain`
  of a sprite one, `sky`, `post`, `compute`).
- **Commands.** `shader.compile` and `material.info` return `kind`; `material.info` lists the programs of the kind
  and `compile.state` (`compiled` or `not_compiled`).

### Sprite and sky materials (M72.1)

The template, the tooling and the draw of the `"sprite"` and `"sky"` kinds are on the page
[custom shaders: the sprite, sky and post kinds](CUSTOM_SHADERS_KINDS.md): the template files and the generated top file, the slots of
textures and params, what the tooling refuses, the `Sprite` draw (`MaterialUse`, the error material) and the sky draw
(`Renderer::Impl::sky_material`, the editor's Scene settings panel).

### Post materials (M72.2)

The template, the tooling, the custom-pass entry (`PostProcess.customPasses`), the render pass and the editor panel of the
"post" kind are in [custom shaders: the sprite, sky and post kinds](CUSTOM_SHADERS_KINDS.md), "Post materials (M72.2)".

## Node graphs

A `*.material.json` may hold an optional `"graph"` (docs/SHADERS.md, "Node graphs"): nodes with typed inputs and outputs and the
links between them. The snippet is then GENERATED from the graph, so everything downstream (the top file, sokol-shdc, the
cache, hot reload, export, the runtime) is unchanged: a graph material is a material whose snippet a tool wrote.

- **One document.** The graph lives in the material file; the generated snippet is written to the file `shader` names and the
  material file records `"graphHash"`, the SHA-256 of the generated text (CRs removed, like the cache key). `material.graph.generate`
  compares the snippet on disk with `graphHash` before writing: a mismatch means a hand edit and the command refuses unless
  `force`. The author's way out is deleting `graph`, which turns the generated code into a hand-written snippet. Both writes
  (snippet, then material) are undone if the second fails, so the two files never disagree about a hash.
- **Params and textures** a node uses are the material's own, so nothing about packing, `materialParams` or the inspector
  changes; a node names one (`"param": "dissolve"`), the checker reports a name the material lacks with the names it has.
- **The file is rewritten.** `material.graph.generate`, `material.param.set_default` and `material.param|texture.create|rename|delete`
  write the whole `*.material.json` again as 2-space JSON: the keys keep their order, hand formatting (alignment, blank lines) is
  lost (the JSON writer keeps the key order only), and the command descriptions say so. `create` takes an optional `index` (the
  position in `params` or `textures`; the order of textures decides the slots) and `delete` returns the `index` it had, so undo
  is `create` with the returned `entry` and `index`. `create`, `rename` and `delete` load a file whose graph reads an undeclared
  param (the very error `create` fixes) and check the patched file instead; `rename` and `delete` return `warnings` when the
  snippet is not the generated one (hand-written or edited) and still uses the name. A constant on a `vecN` input is an array of N
  numbers, like a param's default; a bare number is accepted by `float` and `gen` inputs only (it widens).
  `shader.compile` and `factoria validate` say "run material.graph.generate" when the graph's snippet is missing or out of date.
- **Library in code, not data.** `tools/common/src/material_graph_lib.cpp` holds one table row per node type: ports (type,
  default, doc), the material kinds it works in, whether it needs the fragment stage and the GLSL expression of each output;
  the noise and parallax functions are helpers (`gn_` prefix, `fa_` is reserved for the engine) pasted only when used. Ports are
  `float`, `vec2`, `vec3`, `vec4` or `gen` (a float or the vector size the linked inputs agree on); a float widens, nothing
  else converts silently.
- **Generation** (`material_graph.cpp`) walks the graph from the output node's inputs, dependencies first, so the text depends
  on the graph and not on `pos` or the order of the arrays. Variables are `n_<id>_<output>`; one line per node ends with
  `// <id> (<type>)`; the output node's fields become assignments to `s.` in `surface()` and the vertex offset an addition to
  `v.world_pos` in `vertex()`. Nodes the output does not reach are left out with a warning.
- **Kinds.** The checker reads the material's `kind` when the file has one (the rest of the pipeline adds it separately) and
  refuses a kind it cannot generate (`graph_supported_kinds()`: `mesh`, `sprite` and `post`); every node type lists its kinds. A kind
  is a `KindProfile` row in `material_graph.cpp` (the function headers and what `uv`, `time`, `tint`, ... read there) plus an
  `output` node of its own in the library (same type name, one entry per kind, chosen by the material's kind; its ports carry
  the statement each one writes, `assign`). A node that does not work in the kind carries an `instead` text per kind, and
  the error for it names the node's JSON pointer, why and what to use (`fresnel` in a sprite: `math.smoothstep` of a
  distance). Mesh output is unchanged byte for byte.
- **Sprite graphs** (`"kind": "sprite"`, snippet `shaders/<name>.fragment.glsl`) write the sprite snippet contract:
  `fragment(in QuadInput i, inout QuadSurface s)` and, when `vertexOffset` is linked, `vertex(inout QuadVertex v)`. The output
  has `color` (vec4, assigned to `s.color`), `rgb`, `alpha` and `vertexOffset` (`v.world_pos`); the sprite nodes
  (`sprite.color`, `sprite.tint`, `sprite.texture`, `sprite.life`, `sprite.custom`, `sprite.position`) read what the engine
  drew so far (`s.color`), the tint, the item's main texture, a particle's life, `QuadInput.custom` (zero today) and the
  position; `uv`, `time`, noise, `dissolve`, `flow` and math work as in a mesh. `fresnel`, `triplanar`, `parallax`,
  `normal.world`, `view.dir`, `position.view`, `texture.normal`, `vertex.color` and `position.world` are refused. A sprite is always blended (the material file
  refuses `alphaMode: clip` on its own).
- **Post graphs** (`"kind": "post"`) write `post(...)` into `shaders/<name>.post.glsl`: [CUSTOM_SHADERS_KINDS.md](CUSTOM_SHADERS_KINDS.md), "Post graphs".
- **Cost of the canvas.** The editor's graph canvas edits the same JSON and calls the same generator, so a graph made by an AI
  opens in the editor and the reverse; its New graph material takes a kind (mesh, sprite or post) from the combo next to it.

## Out of scope (recorded so nobody assumes it)

- ~~A full-GLSL escape hatch (D1)~~: built in M72.3 for mesh materials, see [CUSTOM_SHADERS_FULL.md](CUSTOM_SHADERS_FULL.md).
- Compute on GLES3/WebGL2 (refused with the CPU path named), tessellation, geometry shaders (not in sokol_gfx's common subset for these backends anyway).
- Per-instance material data inside one instanced draw.
- The node-graph editor canvas (the graph document, its generator and the node library exist: "Node graphs").

## Work packages

P1 to P14 (the template refactor, the compiler in tooling, the renderer and runtime, exports, docs and editor, custom
lighting, the whole light loop) with their sizes and order are on [CUSTOM_SHADERS_PACKAGES.md](CUSTOM_SHADERS_PACKAGES.md).

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
   room for the hook. (Built in M72.3 together with textures in `vertex()`, see P6.)
5. **Error material = unlit magenta**, never a silent fallback to the standard material.
