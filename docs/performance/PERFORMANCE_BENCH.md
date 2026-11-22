# Performance budgets, page 3 of 3

Part of [Performance budgets](../PERFORMANCE.md) (the entry page lists every page).

## Microbenchmarks (`fa_bench`)

The budgets above watch whole games. `fa_bench` watches the engine's own hot paths, so a change that makes the ECS, the
hierarchy, a physics step, the renderer's gather, a command call, the script bridge or the mixer slower is found in the
pull request that did it, not when an example later goes over its budget. It is a program of the engine's repository
(`tools/bench/`, target `fa_bench`, built with the tools); it has its own small harness and no dependency.

| Benchmark | What one run does |
| --- | --- |
| `ecs.each`, `ecs.each_skewed`, `ecs.entities_with`, `ecs.count`, `ecs.spawn_destroy` | `World::each` over 20000 entities (two, three and a small pool's worth of components), `World::each<Sprite, Collider2D>` with 20000 owners of the first type and 2500 of the second (it walks the smaller pool), `World::entities_with`, `World::count` and `any`, creating and destroying 30000 entities |
| `hierarchy.deep`, `hierarchy.wide` | `World::world_matrix` for every entity of a chain 400 deep, and `World::world_position` for 20000 leaves of a tree 4 levels deep (nothing changes between the reads: the hierarchy cache answers) |
| `hierarchy.moving`, `hierarchy.active` | The same tree, 4 passes with one change before each read of its 20000 leaves: one node of the middle level moves (a mutable `Transform`), or is switched off and on (`set_active`, then `active_in_hierarchy`) |
| `physics.step2d`, `physics.step3d` | 60 `Physics::step`s of 576 falling 2D bodies (Box2D) and 20 of 196 3D bodies (the engine's solver, which costs more per body); the scene is rebuilt before every run, because bodies fall asleep |
| `physics.step3d_mostly_asleep` | 20 `Physics::step`s of a world with 1000 boxes asleep in a pile on a floor and 20 bodies falling 30 m away (400 awake body steps): what a sleeping body costs while others are awake |
| `physics.raycast3d_1000`, `physics.overlap3d_1000` | 10 000 `Physics::raycast3d` rays and 2000 `overlap_sphere3d` queries (1.5 m) through a pit of 1000 bodies that has settled (most asleep): the scene queries ask the broad phase's tree for the bodies near the ray or the sphere instead of testing every body |
| `physics.step3d_1000`, `physics.step3d_stack100` | 10 `Physics::step`s of 1000 falling 3D spheres, capsules and boxes in a walled pit (the case the broad phase makes cheap: only bodies whose boxes are close are tested), and 60 steps of a column of 100 boxes on a floor (stacking: contacts and sleeping) |
| `nav.unreachable`, `nav.unreachable_astar` | 40 failed `NavGrid::search`es into a walled-in room of a 320 x 320 grid (with `closest`, as `nav.find_path` asks): answered from the reachability labels, and with the labels off so A* runs over the whole floor first |
| `physics.tilemap_edit` | 40 steps of a 256 x 256 Tilemap with 512 solid platforms where one cell changes before every step (`set_tilemap_tile`): the cost of keeping the colliders in step with an edit; it follows the number of edits (the array's version says nothing else was written), not the 65536 cells. The colliders are one decomposition of the solid cells (a long floor is one box) and an edit takes apart and stacks again only the boxes it touches, found through a cell-to-box index, so the cost follows the run and the boxes of the edit, not the map |
| `physics.heightfield_step` | 20 steps of 200 spheres, capsules and boxes falling onto a 256 x 256 `Heightfield3D` (3D): the contacts of the grid (only the cells under each body's bounds are tested, GJK per triangle) in the same step as the solver |
| `physics.heightfield_edit` | 40 steps of a 256 x 256 field with 100 bodies asleep on it, where one height changes before every step (`heights.set`): the cost follows the edit (the typed arrays' `dirty_since`), not the 65536 samples, and only the bodies near it wake |
| `physics.tilemap_edit_large` | The same on a 512 x 512 Tilemap (262144 cells): the number should be what the 256 x 256 case costs, whatever the size of the map |
| `nav.tilemap_edit` | 40 times: `setTile` on a 512 x 512 Tilemap, then `nav.findTilePath` across it: the kept cost grid is patched by the edit, not read again from the 262144 cells (a fresh read took 55.9 ms for the 40) |
| `render.frame2d`, `render.frame3d` | 8 headless frames of 5000 sprites and 120 texts, and of 1600 meshes with a sun and 4 point lights, at 640x360 |
| `command.call` | 20000 `CommandRegistry::call`s over 300 commands with a schema, every 50th with arguments that are refused |
| `schema.interpreted`, `schema.compiled` | The schema part of a command call on its own (defaults, then validation, 20000 argument sets, every 50th refused), against the schema as Json and as a `CompiledSchema` |
| `script.native_calls`, `script.component_access`, `script.behaviours` | JS to C++ calls, component fields read and written from JS, and 30 frames of 300 behaviours |
| `script.first_views` | 200 entities spawned from a script, the first read of `Transform.position.x` and `Sprite.layer` of each (the entity's JS object, its view cache and the view of each type are made then) and destroyed, one frame to flush them |
| `sprite.mesh_data` | `sprite_vertex_offsets` + `sprite_vertex_colors` for 1500 deformable sprites of 16 x 4 cells, 20 passes: the per-frame read of the typed arrays `Sprite.vertexOffsets` / `vertexColors` |
| `script.field_read`, `script.field_write`, `script.component_get` | One numeric field of one component read and written 100000 times from JS (a plain field and a vector's `x`), and `entity.get` of two components for 100 entities over 200 passes: the cost of the script bridge's component views |
| `audio.mix_voices`, `audio.mix_bus_fx` | Two seconds of the software mixer with 48 looping voices (pitch and pan), without and with a low-pass and a reverb on the buses (the null device, offline) |
| `jobs.tiny`, `jobs.for_small_grain`, `jobs.for_large_grain`, `jobs.graph`, `jobs.nested_wait`, `jobs.main_queue` | The job system's scheduling: 40000 tiny jobs submitted from one thread; `parallel_for` with 1250 small chunks per call and with 32 large ones; fan-out/fan-in rounds and a chain of dependent jobs; jobs that submit jobs and wait for them; 192000 main-thread tasks posted and run. Each job does almost no work, so the numbers are the queues' and waits' own cost. The baselines are `--jobs inline`; run `--jobs 4` to measure the pool (a baseline is only compared with a run made with the same `--jobs`). These six have wider warn and fail ratios than the others (x1.8 and x3), in every mode, the inline baselines too |
| `terrain.noise_fill`, `terrain.hydraulic_erosion`, `terrain.thermal_erosion` | The costs of terrain generation (`fa/core/noise.h`, `fa/core/erosion.h`): `fill_noise` of a 1024 x 1024 Perlin fBm grid with 6 octaves; `erode_hydraulic` with 50000 droplets on a 512 x 512 heightfield (serial, so the same result on every thread count); `erode_thermal` with 20 iterations on the same grid. The noise fill and the thermal pass run on the job system, so they are wider (x1.8 and x3) like the jobs benches; no baseline is committed yet |

Memory of the 2D tile colliders: the cell-to-box index (`boxAt`) holds 4 bytes per cell of every solid-collider Tilemap for as long as the map has a body, and the boxes it points at never shrink (an edit frees a box's slot for the next one, it does not return memory), so a 4096 x 4096 map costs 64 MiB of index. Editing a long run recreates its whole box (a floor cut in two: both halves are new shapes), so a body resting on the far end of it gets an End and a Begin collision event for that frame. The reachability labels of a nav grid cost 5 bytes per span (a label and a flag) and are made only after a search failed.

The 3D contact manifolds (M94.4d: up to four points per box pair with feature ids) and the soft contacts of the stacking
package (M94.4h: soft step, a Jacobi solve of each manifold, sleeping rules; docs/design/ARCHITECTURE_THREADS.md, "Jobs and
threads"; repository only, not in the binary) are measured by the scale tests (`engine/physics/tests/test_physics3d_scale.cpp`), which check the result and not
only the time: a column of 100 boxes (spacing 1.02) stands and falls asleep after 240 steps with a drift of 0 mm, a column
of 50 after 140 steps, a block of 5 x 5 x 4 boxes after 40, and the walled pit of 1000 spheres, capsules and boxes is asleep
after about 1600 steps (800 to 1600 in other runs; a Release test; before, none of them did, and the column of 100 collapsed). A step of that sleeping
pit costs 0.4 ms (a world with nothing awake skips the sub-steps and the broad phase). Medians in ms (Release, macOS,
15 runs, quiet machine), before and after M94.4h: `physics.step3d` 12.8 / 12.5, `physics.step3d_1000` 100.6 / 100.2 (a
falling pit has the same work), `physics.step3d_stack100` 52.7 / 16.8 (the column of 100 now falls asleep after 4 s instead
of keeping every body awake, and sleeping steps are nearly free). The baselines of the three `physics.step3d*` entries of
`macos-clang.json` were refreshed.

Sleeping bodies (M94.4e): `physics.step3d_mostly_asleep` (1000 boxes asleep, 20 awake elsewhere) takes 167 ms before
and 4.6 ms after (Release, macOS, 15 runs, inline jobs), 20 steps each: 8.3 ms to 0.23 ms per step, where the 20 awake
bodies alone take 0.05 ms; with 10 000 boxes asleep it takes 34 ms (1.7 ms per step, linear in the pile). What is left
is `sync` (it reads the components of every body each step, about 0.15 ms for 1000) and the tree queries of the pair
rows. The doctest "1000 bodies asleep and 20 awake step in about the time of the 20 awake alone"
(`test_physics3d_asleep.cpp`) measures about 5 to 9 times the CPU time of the awake-only world (its awake-only world is
smaller) and fails above 25 times, in optimized builds only. The three other `physics.step3d*` entries were not
refreshed. The numbers of llvmpipe and D3D11 were not measured.

Heightfields (M94.4f): `physics.heightfield_step` takes 19.3 ms for 20 steps (200 bodies on 256 x 256 samples), and
`physics.heightfield_edit` 3.8 ms for 40 one-sample edits with their steps (Release, macOS, 15 runs, inline jobs). The doctest "one
cell of a field of a million samples is edited well under a millisecond" (`test_heightfield3d.cpp`) edits one sample of a 1025 x 1025
field and syncs the physics: about 0.003 ms of CPU time; it fails above 1 ms, in optimized builds only. The end-of-step cover of the
broad phase now walks only the awake bodies: `physics.step3d_mostly_asleep` went from 4.64 to 4.61 ms (within noise). The numbers
of llvmpipe and D3D11 were not measured.

3D polish (M94.4g): the step's working vectors are members of the solver (cleared, not freed) and `sync` takes the list of
entities once for the bodies and the joints, so a settled step makes a fixed number of allocations that does not grow with the
bodies (the doctest `test_physics3d_alloc.cpp` checks that; on libc++ and libstdc++ it counts about 2 per step, the entity
list of each physics backend, on MSVC an empty map or set allocates too). Medians in ms (Release, macOS,
2 runs of 5, inline jobs), before and after: `physics.step3d` 9.3 / 9.2, `physics.step3d_1000` 80.5 / 81.2,
`physics.step3d_stack100` 14.4 / 14.0, `physics.step3d_mostly_asleep` 4.6 / 3.0 (the allocations of the sleeping pile's
steps), `physics.raycast3d_1000` 12.8 / 12.8, `physics.overlap3d_1000` 3.8 / 4.0 (within noise), `physics.heightfield_step`
19.1 / 18.8, `physics.heightfield_edit` 3.8 / 3.7. The numbers of llvmpipe and D3D11 were not measured.

Memory of a heightfield: physics keeps its own scaled copy of the heights next to the component's (4 bytes per sample
each) and of the holes (1 byte per cell each), so a 4096 x 4096 field (the largest the component accepts) takes about 64 MiB
for `heights` + 64 MiB for the copy + 16 MiB for `holes` + 16 MiB for its copy, about 160 MiB, plus 1/256 of that for the
blocks. The first sync of a field, and every rebuild (another size, spacing, scale or array object), is O(N): it reads and
converts every sample (tens of milliseconds for the 4096 x 4096 field), so build a big field at load and edit it afterwards;
an edit of a few samples costs what it touches. More than 8 writes to an array between two syncs also fall back to comparing
every sample of that array (O(N), no copy).

Every input is built from a fixed seed (`fa::Rng`), so two runs do the same work (the report says when the repeats did not).
A run takes about 1 to 110 ms (macOS, Release). The render benchmarks need a graphics context (EGL with Mesa on Linux, Metal, D3D11) and are
skipped, with the reason, when there is none; the others need nothing.

```bash
fa_bench                            # all of them: median, spread (p75 - p25 over the median), min, max and CPU time of 9 runs
fa_bench --filter ecs,physics.step3d   # the benchmarks whose name contains one of these words; --list shows them
fa_bench --repeats 21 --warmup 3 --out numbers.json   # more runs; --json prints the file instead of the table
```

The job system runs inline by default (`--jobs inline`, one thread: the steadiest numbers); `--jobs auto` or `--jobs 4`
measures the pool (big physics steps use it, see "Job threads"), and a baseline is only compared with a run made with the same
`--jobs`. A benchmark that fails the comparison is measured up to two more times (`--retries`) and the best run counts, so a
slow second on a shared machine does not fail it.

### Baselines

`tools/bench/baselines/<runner>.json` (format `factoria.bench/1`) holds the medians of one kind of machine. The runner id is
`<os>-<compiler>`, with `-debug` at the end for a build without `NDEBUG` (no graphics part, unlike the ids above: these
benchmarks do not measure the GPU): `linux-gcc`, `windows-msvc`, `macos-clang`. `FACTORIA_BENCH_RUNNER=name` sets your own.
A baseline from a Mac's own CPU is not the baseline of GitHub's Linux runner, so each runner has its file, and only the
Linux one is enforced by CI.

```bash
fa_bench --compare                # against tools/bench/baselines/<this runner>.json, found from the working directory upwards
fa_bench --baseline other.json    # against this file
fa_bench --update-baseline        # write (merge into) the baseline file of this runner; --filter updates one benchmark
```

The limit of a benchmark is its baseline median times a ratio, or the baseline plus a few tenths of a millisecond when that
is more (a time under a millisecond moves by more than a ratio from one run to the next). Past the **warning** ratio (x1.4;
x1.6 for the render benchmarks, which run a GPU driver beside the engine) the run passes and prints a warning, in CI an
annotation; past the **fail** ratio (x2, render x2.5) `fa_bench --compare` exits with status 1 and the message names the
benchmark, the baseline, the measured value and how to refresh the baseline. A run under 70% of the baseline passes and
says that the baseline can be refreshed. An entry can carry its own `"warnRatio"` and `"failRatio"`; `--update-baseline`
keeps them. The bands are wide on purpose: the check is for a regression of a half or more, which a shared machine cannot
fake, not for a few percent.

A benchmark with no entry in the baseline, a runner with no baseline file, a file of another format and a file measured with
another `--jobs` are not failures: the comparison says so, the numbers are printed and `--out` still writes them.
`--require-baseline` turns a missing entry into a failure.

### In CI

The `bench` job of `.github/workflows/ci.yml` builds `fa_bench` in Release on the Linux runner, runs it under Xvfb with
Mesa's llvmpipe like the tests, compares with `tools/bench/baselines/linux-gcc.json` and uploads `measurements.json` and
`comparison.json` as the artifact `bench-linux` (the job summary has the table). It is part of `CI result`. While
`linux-gcc.json` does not exist it only warns and uploads the numbers.

Refreshing a baseline is a decision, not a way to make a check pass: do it when the code got slower or faster on purpose.
The Mac, Windows PC or runner of that baseline measures it: on your machine `fa_bench --update-baseline` from a Release
build; for the CI runner, "Run workflow" with **benchBaselines** ticked builds nothing else and runs the `Bench baselines`
job on Linux, Windows and macOS, whose artifacts `bench-baselines-<os>` hold the files to copy into `tools/bench/baselines/`.
The first `linux-gcc.json` is made that way, or from the `measurements.json` of a `bench-linux` artifact (`fa_bench --out`
writes the baseline format).
