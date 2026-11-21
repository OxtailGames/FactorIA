Part of [custom shaders](CUSTOM_SHADERS.md): the work packages P1 to P14 the design was built in, with their sizes, order and what each delivered. The decisions and the design itself are on that page.

# Custom shaders: the work packages

Sizes as in ROADMAP.md (S under a day, M 1-3 days, L a week+). Order: 1, then 2; 3 and 4 in parallel once 2 has
fixed the twin format; 5 last. 6 is a sketch for when a game asks for it.

## P1. Template refactor of mesh.glsl and shadow.glsl (M, render)

- Split `mesh.glsl`/`shadow.glsl` into the template files with the hook points; `fa_` prefix for every engine
  identifier; `fa_time` uniform; material block/textures not declared by the default program. Regenerate the headers
  with `compile_shaders.sh` (which learns `@include` paths: `--input` of the top file, includes relative to it).
- Embed the template files in `fa_tooling` (`FA_EMBED_*`).
- Renderer: fill `fa_time` from the accumulated `update` dt.

Acceptance:
- Every existing render golden test passes unchanged (render3d, skinning, shadows, instancing).
- A doctest checks that the embedded template files equal the ones in `engine/render/shaders/` (no drift).
- A golden test with an emission driven by `fa_time` after `n` fixed steps is identical on two runs.

## P2. Shader compiler in tooling (M-L, tooling)

- sokol-shdc lookup and the `shaders` setup component (pinned commit, SHA-256 per host, docs/EXPORTING.md "Setting up
  this computer"); pin `compile_shaders.sh` to the same commit; add the licences to the factoria downloads' notices.
- `fa/tooling/shaders.h`: parse and check `*.material.json` (schema `schemas/material.schema.json`), generate the top
  file, run sokol-shdc through `ProcessRunner` (replaceable in tests, like setup), map errors and add hints, convert
  the YAML reflection to JSON, write twins, cache by hash.
- Commands `shader.compile`, `material.info`; `validate` compiles every material for all dialects.

Acceptance (doctests with real sokol-shdc where available, else skipped with a message; CI has it since P5, not before):
- A fixture material compiles to `hlsl5`, `glsl430`, `glsl300es`, `metal_macos`, `metal_ios`, `metal_sim`; the twins
  parse and list the shadow programs (besides `mesh`, `mesh_skin`, `prepass` and `prepass_skin`) only when `vertex()` or `"clip"` is used.
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
  the vertex stage, undefined again after the snippet). A texture sampled in `vertex()` was an error at this point; M72.3 (P6 below) built it.
- `alphaCutoff` is implicit for `"clip"` (float, default 0.5, 0..1, counts toward the 16); a material may declare it to
  change default, range or doc. The generator defines `FA_ALPHA_CLIP`. **P3 must make the template read it**: `discard`
  below `alphaCutoff` after `surface()` in `fs`, and `shadow_fs` running `surface()` for clip materials (today the
  generated shadow programs equal the default ones).
- glslang reports column 0; the column is found from the quoted token. `fa_` names and a missing `surface()` are caught
  before sokol-shdc runs (glslang says nothing useful about them). `colour` is not near `albedo` by edit distance, so the
  hint uses a small alias table before `did_you_mean`.
- Windows Defender quarantines the pinned `sokol-shdc.exe` (`Trojan:Win32/Bearfoos.B!ml`, an ML false positive):
  the setup status, install and compile errors say how to restore it. Bundling sokol-shdc in the
  release downloads (D3) came later, see "D3 built" after P5.

## P3. Materials in the renderer and runtime (L, render + runtime + scene)

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
  through .gitattributes) and returned by `fa::mesh_template_hash()` (since M72 one hash per kind, see "Kinds (M72)"); the
  tooling's `shader_template_hash()` returns the same value, so the twins and the player cannot disagree across hosts.
- `fs` and the clip `shadow_fs` share `@block fa_fs_surface` (engine textures, `fa_mesh_fs_params`, the varyings,
  `fa_standard_surface`); sokol-shdc honours `@include_block` inside `#ifdef`. The clip shadow program declares
  `fa_mesh_fs_params`, `fa_material`, views 0 and 2-5 plus the material's, samplers 0 and the material's, and no
  `fa_light_tex` / `fa_shadow_tex`: the renderer records the slots each program declares and binds only those.
- Render tests use committed twins (engine/render/tests/data/materials: hlsl5, glsl430 and metal_macos, one per backend
  the render tests run on; the macOS job failed without the Metal ones) because sokol-shdc does not run everywhere; the tests stamp the running engine version into them, and a tooling doctest (real sokol-shdc only)
  fails when they no longer match the template (`FA_UPDATE_FIXTURES=1` rewrites them).
- `RenderStats` gained `materials` and `materialFallbacks`; `asset_report` lists every material with `ok`, `generation`
  and its last error. The sokol shader pool grew from 32 to 256 (four programs per material), then to 384 for the six programs of the depth prepass.
- The editor runs with hot reload off: saving a snippet in an external editor reloads it in `factoria run` and MCP
  sessions, not yet in the editor (P5 added it: `EngineConfig::hotReloadAssets`).

## P4. Shaders in exports (M, tooling)

- `convert_shaders(ea)` in `prepare_game_assets`, dialects per the table above; snippets dropped; export fails on a
  compile error; `ExportReport` lists the materials.

Acceptance:
- Exporting a fixture project for linux, windows, android and web: the output (folder, `game.pak`, APK assets, web
  pack) contains `materials/*.material.json.<slang>.shader` for exactly the target's dialects and no `.surface.glsl`.
- The exported player started headless on the fixture (D3D11 on Windows CI, GL on Linux CI) renders the P3 golden from
  `game.pak`. The web player renders it in headless Chrome (the M17 CI job).
- A project with a broken snippet fails the export with the same error `factoria validate` prints.

## P5. Docs, schema, editor, example (M)

- `docs/SHADERS.md` (game makers: material file, contract, every `fa_` value, five worked examples: pulse emission,
  dissolve with `"clip"`, scrolling water, wind on grass with `vertex()`, rim light), links from COMPONENTS.md,
  AI_GUIDE.md and the generated `AGENTS.md`; ARCHITECTURE_RENDERING.md "Rendering" section; EXPORTING.md; CHANGELOG.md in
  plain words.
- The editor inspector of `material`/`materialParams`, the error under the field, the editor autotest step.
- One example game uses a material (gem-roller: a pulsing gem), so CI smoke runs exercise it on every platform; its
  `ENGINE_FEEDBACK.json` records what was missing.

Acceptance: `factoria validate` passes on the examples; the schema accepts the docs' examples (a test reads them from
SHADERS.md); the editor autotest edits a param and the screenshot changes.

Built (2026-10-19):
- `docs/SHADERS.md` with the five examples; `shaders_docs_test.cpp` writes every block that follows a ``File `path`:``
  line into a scratch project, checks the materials against the schema and compiles all five for every dialect with the
  real tool. Linked from AI_GUIDE.md, the generated AGENTS.md, README.md, EXPORTING.md and the `MeshRenderer.material`
  doc string (COMPONENTS.md); ARCHITECTURE_RENDERING.md has a "Rendering" section.
- The editor had no inspector then (built in M20: the material inspector and the error under the field are in
  docs/EDITOR.md, Hierarchy and Inspector). Instead the editor runs with `EngineConfig::hotReloadAssets`: the engine polls only what the
  renderer rebuilds in place (materials, snippets, textures, fonts, models), while edit mode and Play, and leaves scenes,
  scripts and locales to the editor. The error is the one log line with file:line (Console, `game.logs`). The editor
  autotest changes `materialParams` through the Console (and undoes it), rewrites, breaks and fixes the snippet, and
  compares the viewport pictures.
- CI never had sokol-shdc: the real-compiler doctests skipped there. The Linux, Windows and macOS jobs (and
  `ci-local.sh`) now run `factoria setup shaders` after the build and ctest with `FA_REQUIRE_SHDC=1`, which turns those
  skips, and the editor autotest's material section, into failures. That failure found that the autotest's own
  FACTORIA_HOME hid the installed compiler: the editor hands it over through SOKOL_SHDC before switching homes.
- gem-roller's gems use `materials/gem.material.json` (emission pulsing with `fa_time`); its test checks
  `renderStats.materialFallbacks` after a screenshot, and its FB-0012 (how a test sees that a material draws) is answered
  in SHADERS.md and AI_GUIDE.md.
- sokol-shdc in the factoria downloads: see "D3 built" below.

D3 built (2026-10-19): the factoria downloads carry sokol-shdc next to `factoria`, so makers never run
`factoria setup shaders` (it stays for source builds, and to get the file back).
- `scripts/bundle-sokol-shdc.sh` (a `release.yml` step) reads the commit and the per-host SHA-256 from `setup.h` with `sed`,
  so the engine's pin is the only one; a file that does not match, or a `setup.h` it cannot read, fails the release. A
  tooling doctest checks the exact lines the script reads, so a reformat of `setup.h` fails CI before a release.
- Windows and Linux ship the pinned file byte for byte, unsigned (it is not ours, and its SHA-256 stays the one the docs
  print). macOS ships one universal file made with `lipo` from `bin/osx` and `bin/osx_arm64` (both thin), each slice
  compared with its pinned file before signing; it is then signed and notarized with `factoria`, because Gatekeeper blocks
  an unsigned program that a notarized `factoria` starts from a downloaded (quarantined) package. The installer, the
  editor's updater (it swaps every file of the package) and the AppImage (`usr/bin/sokol-shdc`) carry it too.
- `setup.status` says `found next to factoria`. The package smoke test checks that with an empty `FACTORIA_HOME`, compiles
  gem-roller's material for all six dialects with the bundled file, runs the x86_64 slice under Rosetta, and checks the
  notices; the installer and AppImage tests check the file is there and found.
- Windows Defender: the `Bearfoos.B!ml` detections were on 2026-10-18 (the unpinned clone `compile_shaders.sh` used then).
  On 2026-10-19 with signatures 1.461.102.0 and real-time protection on, the pinned `sokol-shdc.exe`, a zip holding it and
  a run of it were not flagged (`MpCmdRun -Scan -ScanType 3 -DisableRemediation`). An ML verdict can come back, so the
  docs keep saying what to do (restore from Protection history, `factoria setup shaders`, `SOKOL_SHDC`, the SHA-256 to
  check, where to report a false positive) and nothing changes antivirus settings. `sokol-shdc.exe` stays unsigned even
  once the Windows certificate exists: a signature would change the SHA-256 makers can check.

## P6. Custom lighting and textures in `vertex()` (M72.3, built)

`"lighting": "custom"`: the snippet adds `vec3 light(in SurfaceInput i, in Surface s, in LightSample l)`, called by the
engine's light loop once per light instead of Cook-Torrance, and optionally `vec3 ambient(in SurfaceInput i, in Surface s,
vec3 ambientColor)`. The engine keeps choosing the lights, their attenuation and the shadow, and adds emission and fog;
the sky reflection (IBL) is off for custom lighting (a toon look does not want it; a snippet adds it with
`fa_sky_light()`, M72 P14 below). `LightSample` holds `direction`, `color` (the light's color times intensity times attenuation times
shadow: what reaches the surface), `attenuation`, `shadow`, `distance` and `type`. What was built:

- **Template.** `mesh_common.glsl` has the `LightSample` struct in the contract block and, under `FA_CUSTOM_LIGHT`, the
  light loop calls `light()` and sums; `FA_HAS_AMBIENT` makes the ambient term the snippet's. In `"pbr"` the loop is
  the old code (`atten *= shadow` instead of a later multiplication: identical result, so the built-in meshes and every
  existing golden did not change), but the template text changed, so the mesh template hash did, and every committed
  twin (the renderer's test fixtures; a game's exports) must be rebuilt: games with custom materials re-export.
- **Generator.** `light` and `ambient` are entry points (and reserved names) only when `lighting` is `"custom"`; they are
  wrapped in the fragment stage like `surface()`. The defines are `FA_CUSTOM_LIGHT` and `FA_HAS_AMBIENT`. A material
  without `light()` stops with an error that names the material file and shows the signature, before the compiler runs.
- **HLSL gradients.** The loop forbids gradients (`texture()`) in HLSL (X3570), so the docs tell `light()` to use
  `textureLod`.
- **Textures in `vertex()`** (decision): sokol-shdc refuses one name in both stages ("conflicting texture definitions")
  and a view or sampler slot belongs to one stage. So each material texture `t` is declared twice: in the fragment stage
  as `t` at view 6.. and sampler 2.. (what it always was), in the vertex stage as `fa_vs_t` at view 10.. and sampler 6..,
  with `#define t fa_vs_t` (and `t_smp`) only while the vertex stage compiles the snippet, so the author writes one name.
  The renderer binds both slots from the same image; each program's `viewMask` / `samplerMask` keeps only what its stage
  declares, so a material with no `vertex()` pays nothing. The shadow and prepass programs run the same `vertex()` with
  the same bindings, so the displacement is identical in the three. The `texture()` shim of the vertex stage reads mip 0.
  The normal is not recomputed (documented).

Tests: tooling (the generated top file, the missing-`light()` error, reserved names, the twins' per-stage bindings with
the real sokol-shdc, the doc examples), renderer ("materials: ..." cases: a toon shows two bands with the lit side
brighter, a `light()` returning 0 leaves the ambient term, `ambient()` replaces it, a texture in `vertex()` lifts the mesh
and its shadow like a mesh standing there).

## P14. The whole light loop and the sky light (M72, built)

`vec3 lighting(in SurfaceInput i, in Surface s)` in a `"custom"` material replaces the engine's loop, `light()` and
`ambient()` (user guide: docs/shaders/SHADERS_LIGHTING.md). What was built:

- **Template.** `mesh_common.glsl` was reordered so the snippet can call the engine's lights: the blocks `fa_env_funcs`
  (`fa_environment`, `fa_env_brdf`, new `fa_sky_reflection`: the one copy of the IBL, also included by
  `mesh_full_common.glsl`) and `fa_light_shared` (`fa_sky_light`, `fa_no_light`) come first, then `fa_fs_light` (the
  light uniform block, the shadow, `fa_light_count`, `fa_light`, `fa_light_unshadowed`, `fa_light_shadow`, all under
  `FA_CUSTOM_LIGHT`), then the snippet, then the rest. sokol-shdc needs a block defined before it is included, which fixes
  the order. `fa_fs_surface`, the head of the shadow and prepass fragment programs (which also compile the snippet), gets
  `fa_fs_nolight`: the same names with `fa_light_count() = 0`, so a helper that calls them compiles there and never runs.
- **`main()`.** With `FA_HAS_LIGHTING` the light loop, the ambient term and the sky term are replaced by
  `lit = lighting(i, s)`; `s.emission` and the fog come after, as before. Without it the loop is the old code over the
  new `fa_light_shadowed()` (the same arithmetic as before, so a custom material that does not use the hook renders
  the same pixels). The sky reflection is added only when `FA_CUSTOM_LIGHT` is not defined.
- **Generator and checks.** `lighting` is an entry point when its first parameter list names `SurfaceInput` (a helper
  with another signature is not the hook); `GeneratedShader::hasLighting` / `lightingWithoutCustom`. Before sokol-shdc
  starts, `precheck_snippet` refuses: the hook without `"lighting": "custom"` (pointer `/lighting`), the hook together with
  `light()` or `ambient()`, the functions in a `"pbr"` or `"unlit"` material and in `surface()` or `vertex()`; a misspelled
  `fa_` function after the compile gets a did-you-mean over the documented functions first.
- **Lights.** Since M73.1a the cap is 1024 lights per view (`kMaxLights`), 32 of them directional, ordered by `select_lights`: the
  shadow caster, the other directional lights, then point and spot by relevance to the camera; a fragment reads the lights of its
  cluster (ARCHITECTURE_RENDERING_LIGHTING.md, "Clustered lights"). Only light 0 has a shadow map.
- **Template hash.** The template text changed, so every committed twin was regenerated (`FA_UPDATE_FIXTURES=1`), with three
  new fixtures: `lightloop` (a toon from the brightest light only, plus the sky), `skylit` (`ambient()` returns
  `fa_sky_light`) and `full_sky` (a full shader that reflects the sky).

Tests: tooling (the generator, the errors with their pointers, the did-you-mean, the fixture twins with the real
sokol-shdc, the doc example), renderer (two lights give the frame of the brightest alone, unlike the per-light toon; the
sphere reflects blue sky on one end and the orange horizon on the other through `lighting()`, `ambient()` and a full
shader, and shows no sky with `skyAmount` 0).

