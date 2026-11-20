# FactorIA architecture: the game loop, jobs and loading

Part of [FactorIA architecture](ARCHITECTURE.md) (the entry page lists every page).

## Game loop
See `engine/runtime/include/fa/runtime/engine.h`. Fixed-step simulation
(default 60 Hz) + variable render. Headless `Engine::step(n)` advances exactly
`n` fixed frames — deterministic given seed + input.

Input has two views (`engine/platform/include/fa/platform/input.h`, "TWO VIEWS"): the frame's (UI, `onUpdate`,
`onLateUpdate`, timers, Back) and the fixed step's (`onFixedUpdate` and what a step dispatches). Holds are shared; an edge
(press, release, wheel, mouse motion, text, Back, paste) is kept for each view until it has been read: a frame closes
the first with `begin_frame()`, and every fixed step closes the second with `end_fixed_step()` (`Engine::run_frame` opens
an `Input::FixedScope` per step). So an edge is taken by one step whether the frame ran 0, 1 or 5, and one that
arrives in a frame with no step waits for the next. Every writer (`on_key`, `on_mouse_*`, `on_touch_*`, replays,
`game.input`) marks both views, so the recorder and replays need no change (`timing` still records `[dt, steps]`).
A paused engine only redraws and keeps the edges (`discard_idle_motion` drops wheel, motion and text, not presses). A new
system that runs inside a fixed step and reads input needs nothing: it answers for the step's view.

### GPU frames in flight and the CPU's writes
The GPU runs one or two sokol frames behind the CPU (`SG_NUM_INFLIGHT_FRAMES` = 2). Two kinds of data have a copy per frame in
flight, and the rule for each is what keeps the CPU from overwriting what the GPU still reads:
- **Uniforms** (`sg_apply_uniforms`) are written inside a pass, after the frame's command buffer exists, so they are safe.
- **Write-transient buffers and images** (`Gpu::acquire_transient`, `Gpu::write_light_image`, the video textures, the staging
  buffers of the procedural meshes) are written by the CPU OUTSIDE a pass, usually while the frame is planned. The write of frame N
  goes into the copy that frame N-2 read. sokol's Metal backend waits for N-2 only when it makes the frame's command buffer (the
  first pass or copy of the frame), after those writes. So every writer calls `Gpu::begin_transient_writes()` first: on Metal it
  makes the frame's command buffer with an empty copy, which moves the wait sokol does anyway to before the writes (no extra
  synchronisation); on the other backends it does nothing. A new place that writes a write-transient resource calls it too. Without
  it a frame whose data differs from the frame before (every face of a time-sliced probe capture has other visible instances)
  drew with the data of another frame whenever the GPU was behind, which a static scene never shows.
- Everything else the GPU reads (images, meshes, the frame graph's targets) is written by the GPU in submission order, or made new
  for the frame; sokol's Metal backend keeps what a destroyed resource held for `SG_NUM_INFLIGHT_FRAMES + 1` commits.

## Jobs and threads
See `engine/core/include/fa/core/jobs.h`. One process-wide pool of worker threads (`fa::jobs`) that engine code hands
pieces of work to: `submit(name, fn, deps)` returns a `Handle` to `wait` for, `Group` waits for several,
`parallel_for(name, count, grain, fn, seed)` splits `[0, count)` into chunks, `parallel_map_chunks` and
`parallel_reduce` merge per-chunk results, `post_main` hands a task back to the main thread (the engine runs those at
the start of the next frame). The Engine starts the pool in `init()` and stops it in `shutdown()`; the pool is
reference counted, so a second engine in the same process (the editor) shares it, with the first one's setting, and
the last `stop()` joins the workers. `start()` returns a `Result`: it is refused from a thread other than the one that
started the pool and from inside a job, so an `Engine::init` on another thread fails while the pool runs: create and
run every engine on the main thread. A second `Engine::init` of the same engine fails without touching the pool.

- **Owners**: each Engine has a `jobs::Owner`. The jobs and main-thread tasks queued while its `OwnerScope` is open
  (init, each frame, each scene load, each command call) or by one of its jobs belong to it. `Engine::shutdown` waits
  for its own jobs before its scripts and systems go away and drops its main-thread tasks still queued; a frame runs
  only its own engine's tasks (and the shared ones, posted with no owner), so the editor and a preview never run each
  other's results. `Owner::wait` (shutdown) runs only its owner's queued jobs and what they depend on. With several
  engines, the first one to end a frame closes the job statistics (`jobs.info`), until it closes or its engine stops
  drawing frames (8 frames of the others without one of its own hand them over).

- **How many threads**: `runtime.jobThreads` in factoria.json: `"auto"` (the default: hardware threads - 1, at most 8
  on desktop and 4 on phones), an integer 0..32, or `"inline"`, exactly (lowercase, the count not in quotes).
  `FA_JOB_THREADS` overrides it and `EngineConfig::jobThreads` overrides both; those two are text and accept any case,
  spaces around and the count as digits. With 0 workers a job runs on the main thread when something waits for it,
  or at the end of the frame. `"inline"` runs every job at once on the thread that submits it, in submission order: use
  it to debug a job with a plain call stack. Before the pool starts (tools, tests) jobs also run inline. The web build
  has no threads (compiled without `-pthread`): every setting gives 0 workers there.
- **Determinism (the rule every job follows)**: threads never change what the game computes. A job reads shared data
  and writes only its own slot; it never touches `world.rng()` or the World's entity list. Random numbers come from a
  seed drawn on the main thread and `Chunk::rng()` (a stream that depends only on the seed and the chunk index). Chunk
  bounds depend only on `count` and `grain`, and results are merged in chunk order, never in the order chunks finish.
  `game.state_hash` (one 64-bit hash of every entity, component, field, the clock and the random generator) is how a
  test checks it: the same game with 0, 1, N threads and inline gives the same hash every frame
  (engine/runtime/tests/jobs_engine_tests.cpp).
- **Waiting**: `wait()` on the main thread (or in a job) runs only what the job needs: the job itself and its
  dependencies (and theirs) while they are still queued; while those run on other threads it sleeps. It never picks up
  an unrelated job, and `parallel_for` runs only its own chunks on the calling thread (and never returns while one of
  its chunks still runs elsewhere), so a long background load never lands in the middle of the main thread's frame.
  With 0 workers a wait still ends (it runs what it needs itself). A wait that can never end returns an error instead
  of hanging: the job (or one it needs) is running on this thread under the wait, or on another thread that waits,
  directly or through more waits, for a job running on this thread.
  Only waits through `wait`, `Group`, `parallel_for` are seen: a job that blocks on its own mutex, condition variable or
  future can still hang. A job that throws is caught and logged with its name; `wait()` returns the error, and jobs
  that depend on it do not run and report it.
- **Logging from jobs**: `FA_LOG` and friends work on any thread. A log sink (`add_log_sink`) runs on the thread that
  logs, a worker too, and may still run once just after `remove_log_sink`: it locks what it writes and owns it (a
  `shared_ptr` captured by value), never a reference to a local.
- **Cost**: idle workers sleep on a condition variable (no CPU while nothing is queued). Each worker has its own queue
  of ready jobs: it runs the jobs it queues itself (and the first dependent a finished job releases) in order, and an
  idle worker steals the oldest job of another worker's queue; the main thread deals its jobs out to the workers in
  turn. A job costs one allocation and a short lock of one queue; the dependency graph's lock (`Pool::mu`) is taken by a
  job that has dependencies or dependents (or that a `wait` or a `parallel_for` join looked at), by a `submit` whose
  dependency is still running, by a wait that has to sleep (`wait`, `Owner::wait`, `parallel_for`'s join), by the end
  of an owner's last job when an `Owner::wait` sleeps for it, by a thread's first lane lookup after a start or stop,
  and by `start`, `stop` and `settings`; a job nobody looks at and a wait for a job still queued never take it. A wait
  for a job still queued runs it at once, and a wait that took a job drops its queue entry, so with 0 workers the
  entries do not pile up until the frame ends. A worker that is told a job is queued and finds none (the thread that
  took it has not counted it yet) looks again 64 times and then naps for about 200 microseconds (at least the timer resolution on Windows; a new job ends the nap at once). Give a parallel_for a grain of at least a few hundred cheap items. The design is described at the
  top of `engine/core/src/jobs.cpp`. Each worker thread is named (`fa-job-1`..)
  in debuggers and profilers; its stack is the platform default (512 KB on macOS and iOS, 1 MB on Windows, 8 MB on
  Linux): keep big buffers on the heap.
- **What it reports**: `jobs.info` (workers, mode, the setting and where it came from, jobs run and queued last frame,
  how busy each thread was, threads waiting now, this engine's unfinished jobs) and, with the profiler on, a `threads` section per thread in `perf.profile` and
  `play.report` (docs/PERFORMANCE.md) and the Threads tab of the editor's Profiler panel.
- **Physics, navigation and audio on jobs (M70.2b)**: the results are the same inline and with any number
  of workers (tests hash a whole simulation with `inline`/1/2/8 threads; `game.state_hash` is the check for a game). All of
  it is skipped when the work is small (a job costs a few microseconds), by a count of items, never by the clock, so
  which path runs is the same on every machine.
  - *2D physics* (`engine/physics/src/physics2d_tasks.cpp`): Box2D's task system (`enqueueTaskCallback`) runs on
    `fa::jobs`. A step is "wide" when it has at least 1536 awake bodies or 4096 contacts (`physics_job_thresholds()`,
    measured: below that the jobs cost more than they gain); only then its tasks (broad-phase pairs, contact update, constraint solver, finalize, sensors) are
    queued; any other step, a step outside the main thread and the `inline` mode run them on the calling thread. The world
    is always made with the fixed `B2JobTasks::kWorkers = 4`, so a task is cut into at most 4 pieces by item count and
    minimum range only, never by the pool's size: more than 4 threads are not used by 2D physics. A wide step cuts every task into
    the same pieces whatever runs them (a stopped pool, `inline`, no workers or a step off the main thread run the pieces one
    after the other on the calling thread, each with its own worker index), because what each worker finds is merged in
    worker order: Box2D picks the island to split next among the candidates of the workers, and when two have the same
    sleep time the winner depends on how the task was cut. A step below the thresholds is one piece, as before. So a world
    this big (1536 or more awake bodies or 4096 or more contacts) can settle differently than the engine did before M70
    when islands tie; smaller worlds are unchanged. Box2D merges what its
    pieces wrote in bit sets (OR), and its solver colours constraints so that no two pieces touch the same body, so the
    merge order is fixed by the data, not by who finishes first. Joints, the sleeping rules, the callbacks into scripts and
    the write-back to the components stay on the main thread.
  - *3D physics at scale* (overview of M94.4; the bullets below have the details). A step of a world of a thousand bodies
    costs what the bodies that are near each other and awake cost, not the number of bodies squared: (1) the broad phase
    is a dynamic AABB tree of fat boxes, and every pair loop asks it for the partners of a row instead of testing all
    pairs; (2) a rigid contact is a manifold of up to four points with feature ids, so a box lies flat and the warm start
    follows a corner from step to step; (3) the contacts are soft (a spring per point, Jacobi over a manifold, relax
    pass), so a column of 100 boxes stands without bouncing; (4) islands sleep: a pile is asleep when every body was calm
    for half a second, except that up to N / 64 bodies of a big pile may still creep below 0.3 m/s, and a rotating body
    that presses on another dynamic body and moves slower than 0.5 m/s is damped, so a pit of a thousand shapes comes to
    rest (a straggler must rest on something: a body with nothing under it is never one); (5) sleeping bodies stay out of the
    solver: every loop walks the lists of awake bodies, a pair of bodies at rest is `frozen_` and not visited, and a world
    with nothing awake costs the sync only; (6) the scene queries (raycasts, shape casts, overlaps, the character
    controller) walk the same tree; (7) a heightfield is one static body whose contacts read only the cells under the
    other shape. Every one of them gives the bits of the all-pairs loop it replaced, with 0, 1 or N job threads
    (`kReferenceHash` and `determinism_expected.txt` pin it). The step keeps its working vectors in `Physics3D::sc_`
    (cleared, not freed), so a settled step makes a fixed number of allocations that does not grow with the bodies (the list of entities
    that `sync` takes once, and what the standard library allocates for an empty container; the test
    `test_physics3d_alloc.cpp` checks that the count is the same with 50 and with 300 bodies). What stays linear in the number of bodies is `sync`: `World` has no change
    stamps on a component (a mutable `get` is all a script has), so physics reads the pose, the enabled state and the
    shape of every body to see what gameplay edited; it is the 0.15 ms per 1000 bodies measured below.
  - *3D physics* (`physics3d.cpp`): the pair loops are sequential, because a contact changes the bodies the next
    pair sees, and each row of a pair loop asks the broad phase (`broadphase3d.h`, "3D broad phase" below) for its
    partners. Two read-only scans run as `parallel_for` jobs when they have 256 or more rows (`kMinParallelRows`,
    chunks of 16 rows; measured at 64 and 256 in M94.4g: with fewer than about 256 bodies the jobs cost more than the
    scan): the rigid-body contact test that builds the manifolds before the solver, and the contact-event pass. A chunk
    only reads positions and the tree and writes its own slots; the main thread then replays the slots in
    `(chunk, row, k)` order, which is the order of the sequential loop. The iterative solver, the time-of-impact
    islands, waking, sleeping, joints and character controllers stay sequential (the islands of a sub-step are still built on one thread, but from the tree).
  - *3D contact manifolds* (`physics3d.cpp`, `physics3d_shapes.cpp`): a rigid contact has up to `kMaxPts` = 4 points, each with a
    depth and a feature id. Two boxes that are not aligned go through `box_box_sat` (15 axes; a face axis wins over an edge axis unless the edge
    axis is clearly shallower, and a face of the first body over one of the second unless that one is clearly shallower, so a
    pair keeps its reference face from step to step); a face contact (`face_manifold`) clips the incident face against the side planes of
    the reference face and keeps the corners not more than `kManifoldGap` (3 mm) above the reference plane, and two crossing
    edges give one point. `reduce_manifold` merges points closer than 0.1 mm and keeps at most 4: the deepest, the
    one farthest from it and the two that span the largest triangles, with every comparison tolerant and falling back to the
    lowest index, so the choice depends on the geometry and not on float noise or thread order. A capsule lying flat (on a box,
    a mesh or another capsule) gets one point per end, a box on a mesh one per low corner. The id (`mix_id`, an FNV-style hash of
    the reference face, the incident face and the corner or edge crossing that made the point) is the same while the corner
    keeps touching, and the warm start gives each point the impulses its id carried in the previous sub-step (`WarmEntry`), or,
    for an id that is new, those of the nearest unmatched point within `kWarmRadius` (5 cm).
  - *3D contact solver, stacking* (`solve_manifold`, M94.4h): the contacts are SOFT, as in Box2D v3's soft step. Each
    sub-step (h = dt / 4) builds the contacts at the current poses (`held`), runs `kBiasIterations` (2) velocity passes
    whose normal constraint is a spring of `kContactHertz` (60 Hz; 2x against a static body) with damping ratio
    `kContactDamping` (10), pushing a penetration out at up to `kPushOut` (3 m/s) and letting a gap close exactly, then
    the sub-step's motion (turning the push-out speed into a position change, swept for impacts as before), then a relax
    pass (`iterate(held, true)`) with the same constraints and no push-out, which takes that speed out again, the simple
    pairs and the joints. A point's depth follows the bodies' motion since the build (its anchors live in each body's
    frame), so no position projection is needed for resting contacts. A soft contact sags under load by weight / stiffness
    (about 1.5 cm per joint at the bottom of a column of 100 boxes, 0.8% of its height), which is what lets a stack settle
    without bouncing. The points of one manifold are solved together (Jacobi: every point from the same velocities, applied
    at once) with each update scaled by 1 / the Gershgorin bound of the manifold's coupling matrix (`RigidContact::omega`),
    so the result does not depend on the order of the points: a column of boxes is an inverted pendulum (a lean grows by e
    every ~1.7 s), and the one-point-after-another order of a Gauss-Seidel pass leaned every stack to the side of its first
    corner. A time-of-impact stop (`resolve(false)`) still solves hard (the speeds only), and a sub-step that had impacts
    ends with the old position pass (`correct_position`, per point, at most `kMaxCorrection` = 0.2 m, two passes) because
    a body that spins fast can overlap at the end of a sub-step by what its last sweep missed. A rotating
    rigid body that presses (normal impulse) on another dynamic body and whose centre is slower than `kRestSpeed`
    (0.5 m/s) loses speed at `kRestDamping` (1/s), so a capsule rolling on a pile comes to rest. A body alone on the
    ground is not damped (a frictionless puck keeps its speed, a ball rolls down a gentle slope, a spin goes on): damping
    those too made the pit never sleep. Sleeping: a body is calm below `kSleepSpeed` (an
    arcade sphere, `rollWithMotion`, counts only its linear speed), an island sleeps when all its bodies were calm for
    `kTimeToSleep`, EXCEPT that in a big pile up to N / `kStragglers` (64) bodies may still creep, each slower than
    `kStragglerSpeed` (0.3 m/s), because a pile of a thousand spheres, capsules and boxes never stops completely. A
    world with nothing awake skips the sub-steps and the broad phase (a step costs the sync only, about 0.4 ms for the
    pit of 1000); a static or kinematic body that gameplay created or teleported in this step counts as awake for that
    check, because only the contact build wakes the sleeping bodies its new place touches. (`Body::Sig`, the "was this body edited" signature that wakes a body, compares the capsule's `segHalf`
    with a tolerance like the other sizes: its last bits wobble when a body turns a hair, and each wobble used to reset
    the sleep timer of every slowly rotating capsule.) Measured on the scale tests: the column of 100 sleeps after 240
    steps and the column of 50 after 140, neither leans (drift 0.000), and the walled pit of 1000 bodies is asleep after
    about 1600 steps (how long a pile creeps depends on the scene: 800 to 1600 steps measured). A straggler is a body
    at or above `kSleepSpeed` that rests on something from below (a contact whose normal is within about 45 degrees of straight up, `normal.y > 0.7`) and is slower than `kStragglerSpeed`; a body with
    nothing under it counts as at least that fast, so one that starts to fall or rolls off the pile never is one.
    Sleeping bodies cost almost nothing while other bodies are awake (M94.4e). Before the sub-steps a classification
    pass lists the awake bodies, the moved static or kinematic ones, the platforms and the characters (`Rows`); every
    loop of the step (integration, the time-of-impact sweep, contact build, solver, settling, rolling, sleep checks,
    write-back) walks those lists and not all the bodies, and a pair loop walks the rows of the awake bodies, asking
    the tree for the partners (an awake body sees every partner except an awake one with a lower index, whose row finds
    the pair; the records are replayed sorted by (i, k), so the order of the Gauss-Seidel passes and of the warm-start
    lookups is that of a loop over every body). A pair of two bodies at rest (asleep or static) is not visited at all:
    its state moves from `touching_` to `frozen_` and comes back when a body wakes, is edited, or a body is created or
    destroyed. A sleeping body keeps a tight, still-margin box in the tree. In the solver's position pass a sleeping or
    static body below an awake one is an extra row only to find the awake dynamic bodies near it (a floor under a big
    sleeping pile does not return the pile). A sleeping pile an awake body touches takes part in the step as a unit
    (its sleep group wakes together, as before); a pile nothing awake is near is not an island mover.
    What differs from before (every other world gives the same bits; `kReferenceHash` and `determinism_expected.txt`
    did not change, none of their scenes has these cases):
    1. The position pass after a time-of-impact stop (`correct_position`, then the relax pass) now runs only for the
       bodies of the islands that had a stop in the sub-step. Before it ran for every body whenever any body had one,
       so a ball hitting a wall far away also re-solved the contacts of a box resting on the ground, and a resting
       pile was nudged. This changes any world that has two independent groups of bodies in contact and a stop in one
       of them, also when nothing sleeps (the test "a far time-of-impact stop does not move an awake box" pins it).
    2. Inside such an island, the pairs of a body with a static or sleeping body of a LOWER index are visited in
       global (lower index, higher index) order (`replay_sorted`); the old loop visited them with the row of the
       higher body, so the order of the passes differs for an island that touches a static body with a lower index.
    3. A sleeping body that `wake_touched` wakes is a row only from the next phase or sub-step, not in the same call.
    4. A force applied to a disabled body is dropped (and the force a body had when it was disabled is cleared) instead
       of waiting for it to be enabled.
    What is still O(number of bodies) per step is `sync`, which reads every body's components (pose, enabled state,
    shape signature) to see what gameplay edited: about 0.15 ms for 1000 bodies. Measured (Release, macOS, inline jobs):
    1000 asleep + 20 awake steps in 0.23 ms, 10 000 asleep + 20 awake in 1.7 ms (the sync), against 0.05 ms for the 20
    awake alone and 8.3 ms with 1000 asleep before (`physics.step3d_mostly_asleep`).
  - *3D broad phase* (`broadphase3d.h`): the 3D solver keeps a dynamic AABB tree with one leaf per enabled collider with a
    shape (created, removed and renumbered after every `sync`). A leaf holds a FAT box: the collider's bounds plus a margin
    (0.1 m when it moves, 0.02 m at rest) and, for a body in motion, its velocity over two steps; the leaf stays where it is
    while the boxes a phase asks about fit inside it. Before each phase that looks for pairs (the time-of-impact sweep,
    the contact test, the position pass of the solver, the contact events and the wake-up check) the solver makes
    every fat box contain the box that phase asks about (`cover`: for the sweep the bounds of the whole move, a turning
    body as its bounding sphere; elsewhere the body's bounds), and the position pass also puts a body back in the tree the
    moment a contact pushes it out of its box. A row of a pair loop then asks the tree for the bodies whose fat box overlaps
    its own box grown by the phase's reach (0 for contacts, the 0.05 m end margin for events, `kRiderGap` for waking) and
    takes the answer sorted by index. A body the tree does not return is further than the reach, so the narrow phase would
    have said no: the partners and the order are those of the old all-pairs loop, whatever the shape of the tree, the
    order bodies were added in or the number of threads, and the simulation result did not change. Pairs that keep their
    state because both bodies are asleep or static are not geometry: they stay in `frozen_` (see Sleeping) until a
    body wakes. Besides the pair loops, the tree answers which bodies are near
    a platform (the riders it carries) and which movers are close enough to share a time-of-impact island; a mover whose
    reach is over 2 m, or whose centre is outside its box, is tried against every mover instead, and a platform finds the
    characters it carries among the few that can be carried.
    The scene queries use it too (M94.4c2): `raycast3d`, `raycast3d_all`, `shape_cast3d`, `overlap_sphere3d`, `is_touching`
    and the character controller's sweeps and depenetration no longer walk every body. A ray goes down the tree with a slab
    test against each fat box (the nearer child first, the ray clipped to the best hit so far, so a subtree beyond it is
    skipped); the other queries take the bodies whose fat box overlaps the query's box (the swept bounds of a shape cast or
    of a character's move, the sphere's box) sorted by index, and run the old per-body tests on them. Equal distances keep
    the old order (`raycast`: the highest body index wins, as the last one of the old loop; `raycast_all`: distance, then
    index; `overlap_sphere`: index order), so the answers are the same bits whatever the tree looks like. The queries run
    between steps, called by scripts and commands after `Physics::sync`, so the tree has to be complete by then: `sync`
    itself creates the leaves of new bodies, renumbers the payloads and covers the box of every body it marked stale
    (teleported, resized, enabled), a character move covers the capsule where it ended, and the end of each step covers every
    body that can have moved since its last cover (position corrections and joints run after the last phase). A sleeping body
    keeps a box at least as big as its bounds (the fat box shrinks to the bounds plus 0.02 m, never below them), triggers
    have leaves like any collider (the options filter them), a disabled body has none and is not a candidate. The queries only
    read the tree and the bodies, like before (they are called from the thread that steps the world, never during a step).
    Measured (Release, macOS, 15 runs): `physics.raycast3d_1000` (10 000 rays in a settled pile of 1000 bodies)
    318 ms before, 13.4 ms after; `physics.overlap3d_1000` (2000 spheres) 21.8 ms before, 3.9 ms after.
  - *3D heightfield* (`heightfield3d.h`, `physics3d_heightfield.cpp`, M94.4f): `Collider3D.shape = heightfield` with a
    `Heightfield3D` on the same entity (rows x columns samples, `cellSize`, `heightScale`/`heightOffset`, `heights` and
    optional `holes` as typed arrays, `fa/core/typed_array.h`; plain arrays in scene files) is one static body of kind
    `Heightfield`. Model space has the grid centred on the entity origin: sample (r, c) is at x = x0 + c dx, z = z0 + r dz,
    y = raw * heightScale + heightOffset, and cell (r, c) is the triangles (r,c) (r+1,c) (r+1,c+1) and (r,c) (r+1,c+1) (r,c+1),
    both facing up; a hole cell has neither. The body keeps its own scaled copy of the heights, so the solver and the
    queries never read the component that gameplay writes, and 16 x 16-cell blocks keep the lowest and highest sample (the
    field's bounds come from them). `update_heightfield` brings the copy in line: if the arrays have the id and version it
    built from it costs two integer compares; otherwise it asks each array `dirty_since(version it built from)` (the array keeps the last 8 writes; more than that, or
    a copy of another array, means "compare everything"), copies only the samples whose value differs, recomputes the
    blocks they touch and reports the edited cells and the heights they span (old and new). A changed size, spacing,
    scale or array object rebuilds all of it (the first sync of a field and every full rebuild read all N samples).
    Nothing is acknowledged or consumed: the copy remembers the version it took, so any other reader of the arrays (a
    renderer, a nav cache) keeps its own last-seen version and never hides an edit from physics, or the other way round.
    The collider's bounds are the field's, extended `kHeightfieldSolidDepth` (8 m) below its lowest sample so the ground is
    solid there (`boxStale` only when the lowest or highest sample moved, so the tree leaf is kept for most edits), and the `Sig` of the
    body leaves out the height of the box, so an edit does not wake the contacts of the whole field. After the tree is
    updated, `wake_near_edit` turns the edited cells and heights (+0.1 m) into a world box, asks the tree for the bodies
    whose box overlaps it and wakes the sleeping ones that really do; contacts elsewhere keep their state. Contacts
    (`heightfield_contact`, called by `collide_general` like a mesh): the other shape's bounds, in model space, pick the
    cells (blocks and cells whose height range misses the bounds are skipped); each triangle is tested with GJK and the
    deepest result wins. A face contact is kept; a contact on an edge or
    corner counts only when its normal lies in the cone of the normals of the triangles that share it (an open border or a
    hole beside it always counts), so a shape sliding over a seam of a flat or planar field sees only the face normal and
    cannot bump. A shape that sank below a triangle with its closest point inside it is pushed up (solid ground). A body
    wholly below the lowest sample of the cell under its centre touches none of the cells above (they are skipped as
    out of range), so when nothing else hit, the rule is: the centre is inside the grid's x and z extent, the cell under it
    is not a hole, and the body's lowest bound is at most `kHeightfieldSolidDepth` (8 m, world units) below the surface at
    the centre; then the contact is the triangle over the centre's own (normal = its up, depth = how far the body's deepest
    point is under its plane). A body under a hole cell, outside the extent or deeper keeps falling: that is how a body that
    fell through a hole is told from one the terrain rose over (one that fell and then slid sideways under solid cells within
    8 m of the surface is pushed back up too). Boxes and
    hulls get one point per low corner, probed onto the field with `ray_heightfield` (up to four points, feature ids
    like the mesh manifolds). `ray_heightfield` walks the cells along the ray (Amanatides-Woo, bounded by rows + cols + 8
    steps, testing the triangles of a cell only when the ray's height inside the cell overlaps the cell's samples) so its
    cost follows the ray's length and not the grid; `ray_body`, `shape_cast3d` (which uses `collide`), `overlap_sphere3d` and `move_character` use
    these through the tree, where the field is one leaf. The NavMesh bake treats a field like a ground plate (one ray down per
    column) and its signature includes the field's `revision`. A grid that cannot be used (the messages are in
    `update_heightfield`; rows or columns outside 2..4096; a heightfield on a dynamic or kinematic body; no `Heightfield3D`)
    is a problem like a mesh on a moving body: logged once, listed in `Physics::problems3d()`, no collider. Determinism: the
    block order, the cell order and the triangle order are fixed, and nothing depends on the thread count (the hash with
    0, 1, 2 and 8 job threads is tested). Measured (Release, macOS): `physics.heightfield_step` (200 bodies on 256 x 256
    samples, 20 steps) 19.3 ms, `physics.heightfield_edit` (40 one-sample edits, 100 bodies asleep) 3.8 ms; one edit and
    `sync` in a 1025 x 1025 field: about 0.003 ms.
  - *Navigation*: `nav.find_paths` and `nav.find_tile_paths` (and the script calls) answer many queries at once. With 8 or
    more queries (`kNavBatchMinQueries`) they run as `parallel_for` with 4 queries per chunk; each chunk owns a
    `NavGrid::Scratch` (its open list and visited marks; a search never writes the grid), writes only its own slots of the
    result, so the answer list is in request order. The NavMesh is picked per query on the main thread first, so every
    error (with its query number and JSON pointer) comes before any search starts. At most 10000 queries per call.
    Single `nav.find_path` calls stay on the calling thread.
  - *Audio*: `render_sfx` renders each layer of a patch as a job when the patch has at least 2 layers and at least 24000
    samples (`kSfxJobMinSamples`; about half a second at 48 kHz) and the layer buffers fit in 64 MB; the layers are
    summed in layer order afterwards, so the samples are identical. A noise oscillator draws from a stream keyed by
    `(seed, layer, oscillator)` rather than `Chunk::rng()`, so the sound does not change with how layers are grouped.
    The device callback never waits for a job and starts none; the mixer of live voices and `song_preview` stay on their
    own thread. On that thread nothing allocates and nothing locks: a voice's volume, its occlusion gain and its
    low-pass cutoff move to what the game thread sent over a ramp of a fixed number of frames (about 20 ms, 5 ms), and a
    switch between the pan and the head model (hrtf) is a 4 ms crossfade, all counted in frames of the device, never in
    time read from a clock.
  - What this does not promise: the same results are checked on one machine across thread settings. Floating point can
    still differ in the last digit between CPU architectures, as it did before jobs.

### Systems that run as jobs

The per-frame work of these systems is split over the pool with the helpers of `engine/render/src/render_jobs.h`
(`rjobs::split`, `rjobs::run`, `rjobs::stable_sort`) or `jobs::parallel_for` / `jobs::weighted_ranges` (`fa/core/jobs.h`, shared
with the particle step of `fa_scene`). Each pass
below its threshold, and every pass while the pool has no worker thread (stopped, `"inline"`, 0 workers), is one chunk
on the calling thread: the reference path. The thresholds are counts of items, never times, so where the line falls
does not depend on the machine:

| Job name | What a chunk does | Runs as jobs from | Chunk |
| --- | --- | --- | --- |
| `render.gather_sprites` | the quads of its sprites (matrix, anchor, 9-slice, grid meshes, skinned meshes, flash, parallax repeat) | 512 sprites | 128 sprites |
| `render.gather_tilemap` | the visible cells of a band of rows of one Tilemap | 16384 visible cells | ~4096 cells |
| `scene.particles` | steps its emitters (each `ParticleSim` owns its particles and its Rng) | 2048 particles | emitters of ~1024 particles |
| `render.gather_particles` | the quads of its emitters (particles, trails) | 2048 particles | emitters of ~1024 particles |
| `render.sort_quads`, `render.flatten_quads` | stable sort of the 2D items; copy of their vertices into the stream | 4096 items; 16384 vertices | 1024 items; 8192 vertices |
| `render.mesh_matrices`, `render.mesh_cull` | the render scene, once per frame: a mesh's matrix and flash; its bounds (skinned too), material hashes and blend flag | 256 meshes | 64 meshes |
| `render.mesh_frustum` | a camera's frustum test over the render scene (once per camera job) | 256 meshes | 64 meshes |
| `render.sort_blended`, `render.sort_meshes` | stable sorts of the blended meshes (back to front) and of the batches (by material) | 1024 items | 256 items |
| `render.shadow_bounds`, `render.shadow_cull` | the shadow casters' bounds; the test against the light's volume | 256 casters | 64 casters |
| `scene.animation_poses` | every clip channel sampled, the fade blended, the skinning palettes of its animators | 512 skeleton nodes | 2 animators |

What stays on the main thread: everything that may load or create a GPU resource (`Assets::texture`, `mesh`,
`material`, fonts), the animator sheets, the camera tag mask cache, the warnings that fire once, the statistics, and
every sokol_gfx call (the passes build CPU data; the submission comes after them, on the main thread).

The determinism rule, on top of the one for every job: chunk bounds depend only on item counts (and, for particles, on
particle counts), each chunk writes its own `QuadList` or its own slot of a vector, and the parts are joined in chunk
order (`QuadList::append` renumbers the items so their order is kept; `add_quads_of` joins the bands of one tilemap
item). A stable sort has exactly one result, so the chunked sort (each chunk sorted, then pairwise `std::merge`) gives
the order of `std::stable_sort`, as long as the comparison is a strict weak order: every float a render sort compares
goes through `rjobs::order_float` (NaN, from a NaN transform or colour, sorts as +infinity). The 3D batches are
ordered by asset names and entities, never by addresses, which differ from one process to the next. The frame is
therefore byte-identical with any thread count. engine/render/tests/render_jobs_tests.cpp draws scenes far above every
threshold (3000 sprites, a 400x200 tilemap, more than 2048 live particles, 820 meshes with shadows and skinned rigs;
5000 sprites and 2400 meshes with NaN positions and colours) stopped, inline and with 1, 2 and 8 workers, compares
the pictures and the statistics, and checks on the profiler that each pass was cut into the same chunks with every
worker count (which thread ran a chunk depends on timing, so the test only reports it).
engine/scene/tests/test_animation.cpp does the same for 300 animators, and the ctest `example_jobs_same_frames`
compares example scenes drawn by two processes with `FA_JOB_THREADS=inline` and `8`.

## Background loading
`scene.preload`, `assets.preload` and `scene.load {async: true}` (docs/PERFORMANCE.md, "Background loading") read and decode
files while frames run. The pieces and who owns what:

- **`fa::IoQueue`** (`core/background_io.h`): each Engine owns one, made with its `jobs::Owner` and its `LoadTrace` owner. One
  **IO thread for the whole process** serves every queue in turn (round robin, one file at a time), so two engines that load
  at once both move on and never see each other's items. It starts with the first item of a threaded queue (the pool has at
  least one worker) and ends with the last queue; a game that never loads in the background has no IO thread. An item is a
  READ (on the IO thread, through `fa::fs`) then a DECODE (a job of the queue's owner). Its result waits until the main
  thread `take()`s it; `take()` of an item the IO thread has not started does it at once on the calling thread, so it never
  waits behind other files and never deadlocks, also with 0 workers. Without workers there is no IO thread and `take()`
  does the read and the decode itself: the result is the same either way.
- **`fa::BackgroundLoader`** (`runtime/include/fa/runtime/internal/background_loader.h`, main thread only): the jobs of one Engine. A job's first
  item (the SCAN) reads the scene and the text files it names into `fs`'s warm set and lists the binary files; then one item
  per binary file: the renderer decodes a texture, model or font off the main thread (`Renderer::background_*`) and the
  main thread uploads it; audio decodes a sound (`Audio::decode_clip`) and the main thread adopts it. `tick()` runs once per
  frame, before the scripts' platform callbacks, and takes items in a fixed order (round after round, one item of each job
  in start order) within the frame's budget: exactly N items (tests, headless runs, the editor, replays: the same frames on
  any machine and any pool), or the items that are ready within `loadBudgetMs`/`uploadBudgetMB` (a game with a window: a
  prefix of the same order, whose length a recording keeps as `"loadUnits"`). An async scene load whose files are ready
  becomes the frame's pending scene change (`apply_scene_change` at the end of the frame); a scene change asked meanwhile
  cancels it.
- **Lifetime**: a cancelled job's queued items become orphans the loader frees once the IO thread let go of them; a decode
  still running finishes on its worker and is dropped. `Engine::shutdown` stops the loader (`cancel_all`: the IO thread lets
  go of this engine's files), then waits for its jobs owner (the decodes still running), then destroys the loader; nothing
  of a load outlives its engine.
- **The warm set is the process's** (`fs::warm`, keyed by path), and the loaders of every engine count their references
  to each file in one registry (`background_loader.cpp`): a reference per item that read the file (taken before it is
  warmed), then one per job or finished load that holds it. `fs::unwarm` runs when the last reference goes, so two engines
  that load the same file share one copy and one engine's cancel, finish or `background_loads_reset` (a script test file
  starting afresh) never drops a file the other read ahead.
- **Script loads die with their context**: `ScriptHost::drop_script_background_loads` (called with `drop_script_jobs` when
  the JavaScript context is created or closed) cancels the loads a script started, an async scene load's pending switch
  included, and drops their updates, so none reaches a handle that is gone. A cancel in the frame a load's files became
  ready still stops its switch: the pending scene change keeps the load's id.
- **Load trace**: reads run in `LoadTrace::ReadingFor(owner, tag)`, which counts them in the totals and the async load's
  entry but enters a file into the first-use order only at `LoadTrace::file_used` (a warm file read through `fs`, or the
  renderer and audio adopting a prepared asset on first use), so an async load records what a sync load records.

