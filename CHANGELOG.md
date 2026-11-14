# What's new in FactorIA

The editor shows these notes when it offers an update, and each release on GitHub uses its section. Newest first.

Older versions, one file per minor version with its patch releases: [0.25](changelog/0.25.md), [0.24](changelog/0.24.md), [0.23](changelog/0.23.md), [0.22](changelog/0.22.md), [0.21](changelog/0.21.md), [0.20](changelog/0.20.md), [0.19](changelog/0.19.md), [0.18](changelog/0.18.md), [0.17](changelog/0.17.md), [0.16](changelog/0.16.md), [0.15](changelog/0.15.md), [0.14](changelog/0.14.md), [0.13](changelog/0.13.md), [0.12](changelog/0.12.md), [0.11](changelog/0.11.md), [0.10](changelog/0.10.md), [0.9](changelog/0.9.md), [0.8](changelog/0.8.md), [0.7](changelog/0.7.md), [0.6](changelog/0.6.md), [0.5](changelog/0.5.md), [0.4](changelog/0.4.md), [0.3](changelog/0.3.md), [0.2](changelog/0.2.md), [0.1](changelog/0.1.md).

## Unreleased

- 3D heightfield colliders (M94.4f): a `Collider3D` with shape `heightfield` plus a `Heightfield3D` component (`rows` x
  `columns` samples, `cellSize`, `heightScale`, `heightOffset`, `heights` as a plain array of numbers row by row, `holes`
  as one 0 or 1 per cell) is static terrain, the data a terrain editor can write later. Spheres, capsules, boxes and convex
  bodies rest, roll, slide and sleep on it with up to four contact points for a box, and a ball sliding over the seams
  between triangles does not bump (a contact on an edge or corner only counts when its normal lies between those of the
  triangles that meet there). A hole cell has no collision: a body over it falls and one beside it is held. Only the cells
  under the other body's bounds are tested. `raycast3d`, `raycast3dAll` (the ray walks the grid cell by cell),
  `shapeCast`, `overlapSphere`, `isTouching` and `moveCharacter` work on it and go through the broad phase's tree like any
  collider. Editing the `heights` or `holes` array (assigning it again from a script, a brush, a bulk write) updates only
  the samples that differ, in a time that follows the edit and not the size of the grid (one sample of a 1025 x 1025 field: about
  0.003 ms), and wakes only the sleeping bodies near it. A grid that cannot be used (wrong array length, a sample that
  is not a number, fewer than 2 rows or columns, a heightfield on a moving body, no `Heightfield3D`) is reported once with
  how to fix it and has no collider. The NavMesh bake sees the field as ground. New `fa_bench` entries
  `physics.heightfield_step` (200 bodies on 256 x 256 samples) and `physics.heightfield_edit`. Ride-along: the end-of-step
  cover of the broad phase walks only the awake bodies (`physics.step3d_mostly_asleep` 4.64 -> 4.61 ms, within noise).
  The ground is solid 8 m deep: a body that ends up wholly under a solid cell (the terrain was raised under it in one edit,
  or it was put there) within 8 m of the surface is pushed back up; under a hole cell, outside the grid or deeper it keeps
  falling. The collider's bounds reach 8 m below its lowest sample for that.
- Typed arrays (`ArrayI32`, `ArrayF32`, `ArrayU8`) track changes per consumer (M94.4f fix): `dirty_since(seen, begin, end)`
  replaces `dirty_begin()`, `dirty_end()`, `has_dirty()` and `acknowledge()`. The array remembers its last 8 writes, every
  consumer keeps the version it last read, and false means "compare everything", so two readers (physics and a renderer or
  a nav cache) never hide an edit from each other. Engine C++ only: scripts and files are unchanged.
- 3D scene queries use the broad phase's tree (M94.4c2): `physics.raycast3d`, `raycast3dAll`, `shapeCast`, `overlapSphere`,
  `isTouching` (3D) and `moveCharacter` no longer test every body. A ray walks the tree nearest first and is
  cut at the best hit so far; the other queries test only the bodies near the query's box. The answers are the same as
  before (same hit, same order of equal distances; a randomized test compares both with sleeping, static, trigger,
  disabled and just-spawned or just-teleported bodies). New `fa_bench` entries `physics.raycast3d_1000` and
  `physics.overlap3d_1000`.
- 3D physics: bodies asleep cost almost nothing while others are awake (M94.4e). The solver walks lists of the awake
  bodies in every stage and skips pairs of two bodies at rest (their contact state is kept aside and comes back when a
  body wakes). A world with 1000 boxes asleep and 20 awake steps in 0.23 ms instead of 8.3 ms (new `fa_bench` entry
  `physics.step3d_mostly_asleep`; the 20 awake alone: 0.05 ms; 10 000 asleep: 1.7 ms, which is `sync` reading every
  body's components). Results change in these cases: (1) the position pass after a time-of-impact stop now only runs
  for the islands that had the stop, so a fast ball hitting a wall far away no longer re-solves, or nudges, a box or
  a pile resting elsewhere (before, any stop touched every body: this changes worlds with two independent groups
  and a stop in one, also when nothing sleeps); (2) inside a stop's island the order in which a static body with a
  lower index is solved against the island's bodies can differ; (3) a sleeper woken by contact with a woken body
  moves one phase later; (4) a force applied to a disabled body is dropped instead of firing when it is enabled.
  Worlds without these cases give the same bits as before.
- `Sprite.vertexOffsets`, `Sprite.vertexColors` and `SpriteSkin.bindPose` are float arrays (`fa::ArrayF32`) instead of
  `Json` (M94.2d): the JSON on disk is the same flat list of numbers, a script reads a `Float32Array`, and the renderer,
  `entity.bounds()` and the skinning read floats instead of walking JSON values for every deformable sprite every frame
  (new `fa_bench` entry `sprite.mesh_data`). One difference: an element that is not a number (`"x"`, `null`) used to count
  as 0 (offsets), 1 (colours) or left the skin unbound; it is now a load error that names the element's index.
- Hierarchy cache (M94.1c): `World::world_matrix`, `world_position`, `drawn_matrix` and `active_in_hierarchy` keep their result per entity and recompute only what a write dropped, instead of walking every ancestor on every call; `pending_destroy` is O(1). Any mutable access invalidates: the non-const `get`/`get<Transform>`/`get<EntityInfo>`, `add`, `info`, `each` over Transform or EntityInfo, `set_parent`, `set_active`, `set_world_position`, so scripts, reflection, commands, the inspector and animation need no code of their own; a write drops the entity and what hangs below it. Code that only reads must use the const `get` / `std::as_const(world)` (a read through a mutable reference counts as a write; the script bridge's `transform.x` reads and `getName`/`getTags`/`getActive` now do). A `Transform&` kept from an earlier `get` and written after a `world_matrix` read is not seen: get it again after the read (docs/ARCHITECTURE.md, "The hierarchy cache"). Jobs may read the cache at the same time (the fill is lock-protected). `World::hierarchy_version()` counts the invalidations. The world matrix is now the product taken from the root down (`parent_world * local`), which can differ in the last bit from earlier versions at depth 2 or more; the state hash does not read matrices and replays are unchanged. A randomized test compares the cache bit for bit with the plain calculation through every write path. `fa_bench` on macOS, Release, median: `hierarchy.deep` 32.9 ms -> 0.006 ms, `hierarchy.wide` 22.6 -> 0.21 ms, new `hierarchy.moving` (one subtree moved per pass) 43.2 -> 0.4 ms and `hierarchy.active` 1.03 -> 0.15 ms; `ecs.each` and `ecs.spawn_destroy` stay where they were.
- Navigation: a path query whose goal is in another connected area (a walled-in room, an island, a passage closed by a
  moving obstacle) fails at once from reachability labels instead of running A* over the whole map (M94.5a). The labels
  follow moving obstacles, walkable bodies and links, and are recomputed only after a search has failed since the last
  change; the answers, `closest` included, are the same bits as before (a randomized test compares both paths). New
  `fa_bench` entries `nav.unreachable` and `nav.unreachable_astar`. A failed query answered from the labels keeps them
  being recomputed, so an obstacle that moves every frame while queries fail has its labels every frame (and does not run
  A* every other frame); the labels cost 5 bytes a span, and a failing query is answered from the labels without running A* over the whole map.
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
  still queued runs it at once. With several worker threads, small jobs, dependency graphs and nested waits ran faster
  than before in one measurement of `fa_bench --jobs 4 --filter jobs.` on a quiet Apple-silicon Mac, with less CPU time
  (docs/PERFORMANCE.md, "Job threads", has the numbers and says how much they move with the load). Same contracts as
  before: waits run only what they need, a wait that can never end still returns an error, idle workers still sleep.
  Polish (M94): a wait drops the queue entry of the job it took (with 0 workers every job a wait ran stayed allocated
  until the frame end), `Owner::wait` scans the queues under their locks without copying their entries, a worker told
  that a job is queued that it cannot find naps after 64 looks instead of yielding for as long as it takes, and the
  `jobs.*` benchmarks do two to three times the work per run, so a run lasts a few milliseconds.
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
- 3D physics: contact manifolds with several persistent points (M94.4d). Two boxes in face contact are clipped (the
  incident face against the side planes of the reference face) and touch in up to 4 points, reduced in a way that depends
  only on the geometry; two crossing edges give one point. A box on a mesh or a static box has one point per low corner, a
  capsule lying on a surface or on another capsule two (one per end). Every point carries the id of its feature (a corner of
  the clipped face, an end of a capsule), and the warm start gives each point the impulses its id carried in the previous
  sub-step, so the load stays at the right corner while a box slides or turns. The position pass is per point and also turns
  a tilted body back flat (it only translated the pair before). A block of 100 boxes (5 x 5 x 4) falls asleep after
  40 steps (it was still moving after 600); tall stacks are fixed by the next entry.
- 3D physics: tall stacks and big piles stand still and fall asleep (M94.4h). The contacts are soft (Box2D v3's soft step:
  a 60 Hz spring with damping ratio 10 per contact, push-out at up to 3 m/s before the sub-step's motion, a relax pass
  after it), and the points of one manifold are solved together (all from the same velocities, each update scaled by the
  manifold's coupling), so the result no longer leans a stack toward the first corner of its manifolds. A soft contact sags
  under load by weight / stiffness (about 1.5 cm per joint at the bottom of a column of 100 boxes, 0.8% of its height). A
  column of 100 boxes (spacing 1.02) stands and sleeps after 240 steps, one of 50 after 140 (neither leans: drift 0.000),
  and a walled pit of 1000 spheres, capsules and boxes is asleep after about 1600 steps (the scale tests no longer
  `may_fail`). Three more changes made the pit sleep: a slow rotating body pressed against another dynamic body loses
  speed (`kRestDamping`), so a capsule rolling on a pile stops (a body alone on the ground keeps its motion); a pile of N bodies may fall asleep with up to N / 64 of them still creeping slower
  than 0.3 m/s (a pile of a thousand never stops completely); and a capsule no longer wakes itself every step (the
  signature that detects an edited collider compared its length exactly, and it wobbles in the last bits while the capsule
  turns a hair, which reset its sleep timer). A world with nothing awake skips the sub-steps and the broad phase (unless gameplay created or teleported a static or
  kinematic body in that step, which wakes the pile it lands in): a step of
  the sleeping pit costs 0.4 ms (it cost 16 ms). `FA_PHYSICS_REPLAY_HASH` and the `physics3d` hash of
  `tools/cli/tests/determinism_expected.txt` changed on purpose (the same inline and with 1, 2, 4 and 8 job threads); the
  examples' graphics hashes and perf budgets did not. Measured (Release, macOS, medians in ms, before / after):
  `physics.step3d` 12.8 / 12.5, `physics.step3d_1000` 100.6 / 100.2, `physics.step3d_stack100` 52.7 / 16.8.
- 3D physics: the solver has a broad phase. A dynamic AABB tree with fat boxes finds the candidate pairs of the
  sub-step, the first impacts, the contact events, the sleeping bodies a mover wakes, the bodies a moving platform
  carries and the movers that share a time-of-impact island, instead of testing every pair. The result of the
  simulation is the same (the replay hash does not change). A scene of 1000 bodies steps about 4.5 times faster
  (macOS, Release, quiet machine: `physics.step3d_1000` 471 ms to about 100 ms), and the cost of a step now grows with
  the bodies that are close to each other: a pit of 1000 falling bodies costs about 6 times a pit of 250 (testing every
  pair costs about 16 times). The pair scan of 64 or more rows runs in chunks of 16 rows on the job threads.
  element. `Tilemap.tiles` is the first (M94.2b).
- `Tilemap.tiles` is a flat `ArrayI32` (M94.2b). Scene and prefab files may still write an array of rows: the loader
  flattens it (the rows set `width` and `height`; a ragged row, a different `height` or a tile that is not an integer is
  an error with a JSON pointer) and the file is always saved flat. Consumers compare `tilemap_stamp()` (array id, version
  and size) or the array's dirty range instead of hashing every tile, so a script's `Tilemap.tiles` reads as an
  `Int32Array` copy (`const t = comp.tiles; t[3] = 5; comp.tiles = t`; `comp.tiles[i] = x` writes only into the copy) and
  `nav.tileVersion` no longer reads the tiles. `TypedArray::id()` tells two arrays apart where `version()` cannot (a
  copy starts again at 0). The inspector no longer builds the JSON of a big array every frame
  (`component_to_json(..., summarizeArraysOver)`).
- Tilemap colliders and tile paths follow edits (M94.2c). 2D physics keeps a Tilemap's static colliders as one
  decomposition of the solid cells whatever the edits that led there (every row cut into its maximal runs, identical runs
  of consecutive rows stacked, so a long floor is one box and has no seam for a body to catch on), and an edit takes apart
  and stacks again only the boxes it touches, found through a cell-to-box index (4 bytes per cell), keeping the boxes that
  did not change and with them the contacts of bodies standing on them; the boxes and the collision are the ones a fresh
  build gives (a randomized test compares overlaps, ray hits and the boxes). `Tilemap::edits` (empty in a copy, kept by a
  move) is a
  log that consumers read with `tilemap_edits_since(tm, stamp, edits)` and nobody empties; it is bounded, ties to the
  array's id and proves it covers every version step, so a whole-array write, a write that bypassed `set_tilemap_tile` or
  `tm = other` is detected and the consumer reads the map again instead of replaying edits that do not explain the change.
  The stamp is refreshed even when an edit changed no collider, and a map without `solidTiles` no longer hashes its tiles
  every step. `nav.findTilePath`, `findTilePaths` and `flow_field` on a Tilemap of 1024 cells or more keep the cost grid
  between calls and patch the cells written since (`nav_tile_cache_stats()`). New `fa_bench` entries
  `physics.tilemap_edit_large` (512 x 512: 0.43 ms before, 0.075 ms) and `nav.tilemap_edit` (55.9 ms before, 0.16 ms).
  Editing a long run recreates its whole box, so a body resting on the other end of that floor gets an End and a Begin
  collision event that frame. The boxes of a map that was edited are the ones a fresh build makes but are created in a
  different order in Box2D, so a replay recorded on an edited world and one on a freshly loaded world can differ in the last
  bits of contacts (each is deterministic on its own). Stacking the runs of consecutive rows is one sweep a row instead of
  every run against every run (a 4096 x 16 checkerboard builds in 11 ms, 20 ms before). A Tilemap that moves keeps correct
  debug boxes after an edit, `Physics::reset` (a scene load) lets go of the kept nav cost grids, and a rows form with
  whole numbers written as floats (`3.0`) loads. `comp.tiles = [[...]]` from a script is refused (flat only).

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
