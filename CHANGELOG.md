# What's new in FactorIA

The editor shows these notes when it offers an update, and each release on GitHub uses its section. Newest first.

Older versions, one file per minor version with its patch releases: [0.25](changelog/0.25.md), [0.24](changelog/0.24.md), [0.23](changelog/0.23.md), [0.22](changelog/0.22.md), [0.21](changelog/0.21.md), [0.20](changelog/0.20.md), [0.19](changelog/0.19.md), [0.18](changelog/0.18.md), [0.17](changelog/0.17.md), [0.16](changelog/0.16.md), [0.15](changelog/0.15.md), [0.14](changelog/0.14.md), [0.13](changelog/0.13.md), [0.12](changelog/0.12.md), [0.11](changelog/0.11.md), [0.10](changelog/0.10.md), [0.9](changelog/0.9.md), [0.8](changelog/0.8.md), [0.7](changelog/0.7.md), [0.6](changelog/0.6.md), [0.5](changelog/0.5.md), [0.4](changelog/0.4.md), [0.3](changelog/0.3.md), [0.2](changelog/0.2.md), [0.1](changelog/0.1.md).

## Unreleased

- `Sprite.vertexOffsets`, `Sprite.vertexColors` and `SpriteSkin.bindPose` are float arrays (`fa::ArrayF32`) instead of
  `Json` (M94.2d): the JSON on disk is the same flat list of numbers, a script reads a `Float32Array`, and the renderer,
  `entity.bounds()` and the skinning read floats instead of walking JSON values for every deformable sprite every frame
  (new `fa_bench` entry `sprite.mesh_data`). One difference: an element that is not a number (`"x"`, `null`) used to count
  as 0 (offsets), 1 (colours) or left the skin unbound; it is now a load error that names the element's index.
- Navigation: a path query whose goal is in another connected area (a walled-in room, an island, a passage closed by a
  moving obstacle) fails at once from reachability labels instead of running A* over the whole map (M94.5a). The labels
  follow moving obstacles, walkable bodies and links, and are recomputed only after a search has failed since the last
  change; the answers, `closest` included, are the same bits as before (a randomized test compares both paths). New
  `fa_bench` entries `nav.unreachable` and `nav.unreachable_astar`.
- `World::each<A, B, ...>` walks the pool with the fewest owners in place, instead of copying the first type's owner list and looking the others up for each entity: `each<Sprite, Collider2D>` costs what the colliders cost. With several types the order is therefore the smallest pool's insertion order, not always the first type's (use `entities_with(type)` when one type's order matters; no engine system depends on it). Adding or removing components of any type (the walked one too), `destroy()` and a nested `each` over the same type stay safe inside the callback; the pool holds its compaction back until the walk ends. Entities that gain the walked component during the walk are not visited. The UI autosize, camera lookup, `vfx.list`, `anim.list`, bone and IK2D loops use it.
- `World::count<T>()` / `any<T>()` (and `count(type)` / `any(type)`) answer "how many / is there any entity with this component" in O(1) from the pool, instead of copying every owner with `entities_with(...).size()`; the UI, 2D render and validation checks use them.
- Command arguments are checked against a schema compiled at registration (M94.3a): `fa::CompiledSchema`
  (core/json_schema.h) resolves the `$ref`s, reads the keywords, collects the defaults and compiles each `pattern` once, and
  `CommandRegistry::call` uses it instead of walking the JSON schema on every call; it also copies the arguments only when
  it has to remove `_meta` or fill defaults. The errors are the same, byte for byte (the tests and the `json_schema` fuzz
  target compare both paths). The validator's depth limit of 64 levels is exact now: a schema position that
  holds a value that is not a schema (for example `"properties": {"a": "string"}`) used to lower the depth counter by one
  for the rest of the validation.
- Component fields can now be typed number arrays (`FieldKind::ArrayI32`, `ArrayF32`, `ArrayU8`, C++ `fa::ArrayI32`
  etc. in `core/typed_array.h`): the JSON on disk is a flat array of numbers, in memory it is contiguous and counts its
  writes (`version()` and a dirty index range, so a system rebuilds only what changed), and in scripts it reads as an
  `Int32Array`, `Float32Array` or `Uint8Array` (a copy) and takes a typed array or a plain array, checking every
  element. No component uses them yet.
- Job system (M94.5b2): every worker has its own queue of ready jobs and steals from the others when it runs out,
  instead of one queue under one lock that every thread took for every job. A job with no dependency and no dependent
  never takes the pool's graph lock, a worker runs the first job a finished job releases itself, and a wait for a job
  still queued runs it at once. With several worker threads, small jobs, dependency graphs and nested waits run faster
  than before, nested waits about four times faster, and use less CPU (`fa_bench --filter jobs.`). Same contracts as
  before: waits run only what they need, a wait that can never end still returns an error, idle workers still sleep.
- Script component access is cheaper (M94.3b): `entity.get("Sprite")`, `entity.transform` and `entity.position` give the
  same view object every time (kept on the entity's JS object; a view is only a handle, so it never goes stale: after
  `remove` or `destroy` its fields still throw the same teaching errors), a view no longer sits behind a Proxy (the fields
  are accessors with their index fixed once per type, and only a name that does not exist reaches the Proxy that says
  "did you mean"), the views of vector and colour fields are kept too, and `entity.get` asks the engine for the
  component by type index instead of by name. `Object.keys`, spread, JSON and the debugger's variables show the same
  fields as before. New benchmarks `script.field_read`, `script.field_write` and `script.component_get`. Measured
  before and after on the same loaded MacBook (Release, two A/B runs each, medians in ms): 100000 field reads 13 -> 8.7,
  100000 field writes 18 -> 10.6, 40000 `entity.get` + read 29 -> 17, 10000 entity passes of `script.component_access`
  43 -> 17 and 300 behaviours for 30 frames (`script.behaviours`) 42.5 -> 30.3.

## 0.26.0

FactorIA 0.26.0 (M93) adds the checks that find bugs before users do. `FA_SANITIZE` builds run the Debug suite
under AddressSanitizer + UndefinedBehaviorSanitizer and the threaded tests under ThreadSanitizer, both in CI; fuzz
targets cover the JSON, scene, pack, MCP and file decoder entry points (replayed by ctest, fuzzed weekly); CI builds
with warnings as errors on every compiler and checks formatting and clang-tidy on changed files; `FA_COVERAGE` and
`scripts/coverage-report.sh` measure test coverage; and `fa_bench` measures the hot paths against a baseline. The
bugs these found are fixed: use-after-free in two editor inspectors, a race in a test, decoder crashes on damaged
images, fonts, glTF, audio, MIDI and SoundFonts, and JSON input that ended the program instead of giving an error.
The whole C++ code base is formatted with `.clang-format` (the commit is listed in `.git-blame-ignore-revs`).


- The editor's MCP endpoint closes a connection gently after any answer that ends it (`Connection: close`, an error, a
  stream): it stops sending, reads what the client still sends (for up to 500 ms, which keeps its connection slot that
  long) and then closes, as it did after 413 only. On Windows and macOS closing a socket with unread input sends an RST
  that can wipe the answer from the client's receive queue. This covers the case of input the server never read; the
  intermittent "read 0 bytes" instead of the `204` of a cancelled request has no unread input and stays open (ROADMAP).
- Coverage (M93.4): `-DFA_COVERAGE=ON` (Clang) instruments the build for llvm-cov and `scripts/coverage-report.sh <build-dir>` turns the profiles of a ctest run, the editor autotest included, into a table per module (Markdown and JSON) and an HTML report. The new informative CI job `coverage` uploads both and writes the table to its summary. docs/BUILDING.md, "Coverage".
- Warnings as errors in CI (M93.3a): the CI jobs (Linux, Linux sniper, Windows, macOS, iOS, Android and Web, and
  `scripts/ci-local.sh`) configure with `-DFA_WARNINGS_AS_ERRORS=ON`, so a compiler warning in the engine, the tools, the
  player or the test programs fails the build (`-Werror` on GCC and Clang, `/WX` on MSVC); `external/` stays out. The
  warning set is the same as before and the option stays OFF in the presets, so local builds and `release.yml` are not
  affected (docs/BUILDING.md, "Strict builds"). The plugin test program `fa_test_plugin_example` now links `fa_warnings` too.
  The warnings the CI logs of 0.25.0 showed are fixed: unused functions, constants, captures and members (some now only
  compiled where they are used: the GPU timer ring, the iOS Simulator helpers, the folder picker's glob list), a trigraph in
  `classify_path`, date buffers too small for GCC's range analysis, loop variables bound to temporaries, locals and
  parameters that hid a member or an outer variable (MSVC C4456-C4459), narrowing conversions, an unhandled `Tileset` case
  in the image panel's layer badge, `''` in the web HTTP script (Emscripten) and a 32-bit shift of the texture seed
  (`>> 32` of a 32-bit `long` on Windows, now taken from a 64-bit value).
- First strict CI run (M93): the formatting commit had split `===`, `!==` and `=>` in the JavaScript of the `EM_JS` blocks of
  the web player (`== =`, `= >`), which broke the web build at link time; those blocks are back as they were, between
  `// clang-format off` and `// clang-format on`. Also fixed: GCC's false `maybe-uninitialized` in the vendored stb_vorbis
  (silenced around its `#include` only), a missing `<algorithm>` in a core test, `if constexpr` for the build-time
  constants the MSVC compiler reports as constant conditions, and Apple's linker warning about the repeated libraries of
  `fa_bench` and `fa_test_tooling`.
- Second strict CI run (M93): MSVC's flow-analysis warnings in the vendored dr_wav, qoa, stb_vorbis and nanosvg
  (every vendored implementation compiled in an engine file is now between `#pragma warning(push, 0)` and `pop` for
  MSVC, around its `#include` only) and a truncating cast in a font test; the fuzz targets' stale-folder cleanup kept a reference into a temporary
  file name (GCC `-Wdangling-reference`, a real bug); the audio tests' allocation counter, which replaces the global
  `operator new`, is off in sanitizer builds, whose runtimes define it too (the TSan link failed); and
  `scripts/tidy-changed.sh` leaves out the files only a commit of `.git-blame-ignore-revs` changed, so the reformat
  does not make clang-tidy check every file. The first TSan run: the MCP HTTP test read the names its command handler
  recorded on the server's threads without a lock (now behind a mutex), and Mesa llvmpipe's own races on the headless
  runner are suppressed in `tools/ci/sanitizers/tsan.supp` with the reason.
- First ASan run (M93): `register_ai_commands` leaked on every registry it filled (the command hooks' state owned the interceptor
  whose lambdas own that state, an ownership cycle, so the hooks' configuration loader and everything it captured was never freed;
  the interceptor is now held weakly, with a test that the state goes when the registry does). That one cycle was the thousands of
  LeakSanitizer reports of the `ai`, `cli` and editor tests, and it made every child `factoria` the editor and the scripts start
  exit with code 1 (`cli_plugin`, `cli_integration`, `agent_cost_script`, the editor autotests' "printed no result" steps). The
  editor autotest's fake GitHub sign-in code now lasts far longer than the autotest takes to approve it on a slow build. The
  `-fsanitize=function` findings in tinysoundfont and xatlas (a function stored under another function type, vendored) are in
  `tools/ci/sanitizers/ubsan_ignorelist.txt` with the reason, and so is tinysoundfont's `NULL + 0` (`-fsanitize=pointer-overflow`,
  a preset with no regions). Neither ninja nor ccache read the ignorelist's contents, so the compilers now get a copy named
  after its MD5 and an edit to it reconfigures and rebuilds. The coverage job links two executables at a time (it ran out of memory). The `_perf` budget tests are registered `DISABLED` in
  sanitizer builds (no baseline can exist for them). MSVC's C4702 in nanosvg comes from the optimizer, which ignores
  `#pragma warning`, so it is off with `/wd4702` on the two files that compile nanosvg.
- Formatting and lint (M93.3): `.clang-format`, `.clang-format-ignore` and `.editorconfig` describe the code style; `scripts/format.sh [--check] [--changed <base>]` formats or checks first-party C and C++ with a pinned clang-format (a pip wheel in `build/lint-venv`), and `.clang-tidy` with `scripts/tidy-changed.sh <base>` runs a few bug-finding checks over the changed sources. A new `lint` CI job runs both on what a change touches. docs/BUILDING.md, "Formatting and lint".
- **Sanitizer builds.** `FA_SANITIZE` (`address;undefined` or `thread`) builds the engine, the tools, the tests and `external/` with
  AddressSanitizer + UndefinedBehaviorSanitizer or ThreadSanitizer; the presets `linux-asan`, `linux-tsan` and `macos-asan` set it,
  and the suppression files live in `tools/ci/sanitizers/`. Two new CI jobs, `Linux (Clang, ASan + UBSan)` (the whole Debug suite)
  and `Linux (Clang, TSan, threaded tests)`, are part of `CI result` (docs/BUILDING.md, "Sanitizers").
- **Fixed, found by the first ASan run.** The editor's Particles inspector and Image layer inspector kept a reference into a
  document that a row edited in the same frame (use after free while dragging a value or adding an adjustment); a
  `tooling` test read a temporary after its end; the editor autotest's `scroll_to` kept a `const char*` into a local string.
- Microbenchmarks (M93.5): `fa_bench` measures the engine's hot paths (ECS queries, the transform hierarchy, 2D and 3D physics steps, a headless render frame, command dispatch, the JS bridge, the audio mixer) from fixed seeds, with warm-up, repeats, median and spread. `--compare` checks a run against `tools/bench/baselines/<runner>.json` with a warning band and a fail limit (x2 on the median) and a teaching message; a new `bench` CI job runs it on Linux, and a `benchBaselines` run of the workflow refreshes the baselines. docs/PERFORMANCE.md, "Microbenchmarks".
- Editor autotest: the 9900-line `autotest_tools.cpp` is split by section into `autotest_<group>.cpp` files (one
  `Editor::at_section_<id>` per section, the shared helpers in `autotest_common.{h,cpp}`); no change in what it checks.
- Fuzzing (M93.2): `tools/fuzz/` has fuzz targets for `parse_json`, `validate_json` and the schema helpers, `load_scene`, `entity_from_json`, the game pack reader, the MCP JSON-RPC server (read-only capabilities, empty project) and the translation tables (`read_csv`, `read_xliff`), each one `.cpp` plus a corpus folder. Every desktop build with `FA_BUILD_TESTS` (the default) replays the corpus as the ctests `fuzz_<name>` (label `fuzz`); `-DFA_FUZZ=ON` with Clang builds them as libFuzzer programs with AddressSanitizer and UBSan (`tools/fuzz/run.sh`), and the CI job `linux-fuzz` runs each for a minute. docs/BUILDING.md, "Fuzzing", says how to add a target and a crash.
- Fuzzing the file decoders (M93.2b): new targets `image`, `ktx2`, `gltf`, `font`, `audio`, `midi` and `soundfont`, with seed files from the test fixtures. The decoders wrap code in `external/` that trusts file headers, so the engine now checks before it calls it: an image that claims more than 134 million pixels (a KTX2 texture also a side over 16384), an audio file with more than 32 channels, and a header that promises a huge length no longer decide how much memory is asked for; every glTF reader (skeletons, meshes, the model importer, the renderer) runs `cgltf_validate` first, so an accessor that reaches past its buffer is an error that names the file instead of an out-of-bounds read, and nodes that share one big mesh cannot place more than a mesh can hold; a TrueType font is walked table by table before stb_truetype reads it, and is refused as damaged only when its tables, glyph offsets or cmap lie outside the file or its cmap format is not read (a format 4 search header that differs from the specification still loads when the lookup stays inside the subtable); a glyph that includes itself or nests too deep, is placed by matching points, has contours that do not rise or ends in a lone point off the curve is drawn as the `.notdef` box while the rest of the font works; a KTX2 level whose stored size differs from its unpacked size, a picture with no rows, an Ogg Vorbis file whose comment lengths lie (one whose comments are over 16 MB is told apart from a damaged one) and a SoundFont whose preset, instrument or sample numbers point outside its tables are errors instead of an assert or an out-of-bounds read. New API: `decode_ktx2` (`fa/render/ktx2.h`, KTX2 to RGBA8 on the CPU), `read_gltf_mesh_bytes`, `rasterize_text` with a font in memory. docs/BUILDING.md, "Fuzzing", lists what stays inside `external/`.
- The weekly fuzz run (`.github/workflows/fuzz-weekly.yml`) fuzzes every target for 25 minutes and leaves the minimized corpus and any crash as artifacts; the one-minute random run of the `linux-fuzz` CI job no longer blocks a pull request (it warns), and UBSan ignores `external/`.
- Text that other programs write (script `JSON.parse` results, saved script storage, AI transcripts, feedback server answers, hook input, DAP messages, the MCP update hand-over) is now read through `parse_json` / `parse_json_lenient`, so the 256-level nesting limit applies to it too.
- `PackReader::open_memory` opens a game pack from bytes in memory (the fuzz target of the pack format uses it) and gives the same errors as `open` for a damaged one.
- A JSON number outside the range of a double (`1e999`) is now an `invalid JSON` error with its line and column and a hint instead of an exception that ended the program (found by the `json` fuzz target); it affected every file the engine parses with `parse_json`.
- JSON nested more than 256 levels deep (`kMaxJsonDepth`) is now an `invalid JSON: nesting deeper than 256 levels` error with its line and column, from `parse_json` and from the MCP server's message readers, instead of a stack overflow when the value is printed or copied (found by the fuzz targets; a 64 KB file of `[` crashed the process). Real files nest a dozen levels. `json_nesting_overflow` and `parse_json_lenient` are the checks for code that reads untrusted text with `Json::parse` directly.
- ThreadSanitizer over the threaded tests (M93.1): the job system, background loading, the audio mixer and its streams,
  the MCP server, platform HTTP, scripts, services, tooling and AI test programs ran clean under TSan (macOS arm64) with
  `halt_on_error=1`; the one race found was in a test (`process: onStart gives the pid...` read a pid written by another
  thread without synchronization) and is fixed. `tools/ci/sanitizers/tsan.supp` is the suppressions file for races inside
  `external/` (none needed so far).
