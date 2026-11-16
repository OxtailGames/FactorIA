# Building FactorIA: tests, sanitizers, fuzzing, coverage and golden images

Part of [Building FactorIA](BUILDING.md) (the entry page lists every page).

## Running tests

- `ctest --preset <name>` runs every test and prints the output of failing tests.
- One module: `cmake --build --preset linux-debug --target fa_test_core`, then
  `ctest --preset linux-debug -R core`. Test targets are named `fa_test_<module>`.
- GPU tests carry the CTest label `gpu`, and `ctest --preset <name> -LE gpu` skips
  them, for example on machines without a GPU.
- Tests run with the repository root as their working directory, so fixture
  paths are relative to the root.
- **The example games run on an optimized build.** `example_<name>_test` (their JS tests), `example_<name>_validate` and
  the perf budgets (`example_*_perf`) carry the CTest label `example`. The games' tests run the whole engine for minutes
  (the biggest take ten minutes in Debug under load, about a tenth of that in Release), so the cache variable
  `FA_EXAMPLE_TESTS` (`AUTO`, `ON`, `OFF`) decides whether they run: `AUTO`, the default, runs them in Release,
  RelWithDebInfo, MinSizeRel and multi-config builds (Visual Studio, Xcode), and registers `_test` and `_perf` as
  `DISABLED` in a Debug build (`ctest` prints them as "Not Run (Disabled)"; CMake says so while configuring; the
  validations still run). `ctest -L example` selects them, `ctest -LE example` leaves them out.
- **Before a push, one command:** `scripts/test-all.sh` (Windows: `scripts\agent-build.ps1 <dir> -Test -Examples`). It builds
  every target in Debug and runs the whole Debug suite, then builds `factoria` in Release (`build/release`) and runs
  `ctest -L example`. `--debug-only` and `--examples-only` run one half; `FA_TEST_DEBUG_DIR`, `FA_TEST_RELEASE_DIR`,
  `FA_TEST_JOBS` and `FA_TEST_CTEST_JOBS` (default 3) tune it; ccache is used when installed. CI already builds Release,
  so its `ctest` runs the examples with no extra job. An AI agent runs that check as
  `scripts/agent-build.sh <dir> --test --examples`, which prints only what failed, never blocks for more than 100 s and
  builds its Debug tree with `-O1 -g1` (the suite takes less than half the time; see "Linux and macOS, short output" in [BUILDING_SCRIPTS.md](BUILDING_SCRIPTS.md#linux-and-macos-short-output-scriptsagent-buildsh)).
- **A scratch shader cache in tests.** `add_test` also gives every test `FA_CACHE_DIR=<build dir>/test-cache`, so a test run never
  reads or writes your real per-user cache folder (`fs::cache_dir()`, docs/PERFORMANCE.md "Startup"); delete the folder for a cold-cache run.
- **Windows file rules in tests (macOS and Linux).** Two Windows behaviours broke the engine and only the Windows CI job
  found them: a file open for reading cannot be replaced or deleted (every `std::ifstream` opens without
  `FILE_SHARE_DELETE`, so the atomic rename of `fs::write_bytes` fails while another thread reads the file), and a file's
  modification time moves in steps of 15.625 ms, so a write right after a read keeps the time the read saw. On macOS and
  Linux `ctest` runs every test with `fa::fs` emulating both (`FA_FS_WINDOWS_RULES_DEFAULT=1`, set by `add_test` in
  `cmake/FactoriaHelpers.cmake`; `scripts/test-all.sh` too): a replace, rename or delete of a file held open through
  `fs::ReadStream` (or `fs::read_bytes`) fails with a sharing violation after the same retries as on Windows, a folder
  with such a file inside loses everything else and reports the violation, paths compare case-insensitively, and
  `fs::modified_time` / `fs::host_modified_time` round down to 15.625 ms. A test that fails only with the mode on found a
  real Windows bug: read the file with `fs::ReadStream` (not a bare `std::ifstream`, which the registry cannot see), and
  never rely on a time change smaller than 16 ms. Details and limits: `core/fs.h`, "Windows file rules".
  Switch it off for one run with `FA_FS_WINDOWS_RULES=0 ctest ...` (any value other than `0`, `false`, `off`, `no` turns
  it on, also for a program run by hand: `FA_FS_WINDOWS_RULES=1 factoria test ...`), or for a build directory with
  `cmake -DFA_TEST_WINDOWS_FILE_RULES=OFF`. A test that sets its own `ENVIRONMENT` property must `APPEND` to it
  (`set_property(TEST <name> APPEND PROPERTY ENVIRONMENT ...)`); `set_tests_properties(... ENVIRONMENT ...)` replaces the
  mode's variable.
- **Time limits count CPU time.** The 60 s of one test of `factoria test`, the 5 s of `script.eval`, the 2 s of a callback
  and the like measure the CPU time the script thread spent (`CLOCK_THREAD_CPUTIME_ID`, `GetThreadTimes`), not the wall
  clock, so a loaded machine or a build running next to the tests cannot fail them. A script blocked for good (a native that
  never returns) is still stopped by a hard cap of 8 times the limit on the wall clock. The messages say which one ran out:
  `(> 60 s of CPU time)` or `(> 480 s on the clock)`.

## Sanitizers

`FA_SANITIZE` (a CMake cache variable) builds every target with Clang's or GCC's sanitizers: the engine, the tools, the
player, the tests and `external/` (ASan must instrument the third-party code too, or it reports container-overflow false
positives where our code and theirs share a `std::vector`, and TSan cannot see the accesses of uninstrumented code). It is
empty by default. Allowed values (anything else stops the configure with a message saying so): `address;undefined`
(AddressSanitizer + UndefinedBehaviorSanitizer; quote the semicolon in a shell), `address`, `undefined` and `thread`
(ThreadSanitizer, which cannot be combined with `address`). GCC and Clang on Linux and macOS only: MSVC, Emscripten,
Android and iOS stop the configure with a teaching error. UBSan is built with `-fno-sanitize-recover=undefined`, so a
finding fails the test it happens in instead of printing one line; ASan stops at its first report as well, and TSan prints
every race of the run and fails the test with its exit code.

- **Run it locally:** `cmake --preset macos-asan && cmake --build --preset macos-asan && ctest --preset macos-asan`
  (Linux: `linux-asan`, with Clang installed; `linux-tsan` for ThreadSanitizer, `ctest --preset linux-tsan -L tsan`). The
  presets build into `build/<preset>` with `-O1 -g1` (assertions stay on). With `scripts/agent-build.sh`, configure the tree
  by hand first (`cmake -S . -B build/agent-asan -G Ninja -DCMAKE_BUILD_TYPE=Debug -DFA_SANITIZE="address;undefined"
  -DCMAKE_C_FLAGS_DEBUG="-O1 -g1" -DCMAKE_CXX_FLAGS_DEBUG="-O1 -g1" -DCMAKE_OBJC_FLAGS_DEBUG="-O1 -g1"
  -DCMAKE_OBJCXX_FLAGS_DEBUG="-O1 -g1"` on a Mac); the script builds and tests a tree that is already configured.
- **The test environment is set by CMake**, not by the test presets: `add_test()` (cmake/FactoriaHelpers.cmake) gives every
  test of a sanitizer tree `ASAN_OPTIONS`, `UBSAN_OPTIONS`, `LSAN_OPTIONS` (Linux only: LeakSanitizer does not exist on
  macOS, where the runtime refuses `detect_leaks`) or `TSAN_OPTIONS`, with the suppression files of `tools/ci/sanitizers/`.
  So any `ctest` of such a tree has them, with a preset or without. A program you run by hand needs them exported.
- **Timeouts are scaled:** instrumented code is 2-3x slower (ASan + UBSan) or 5-15x slower (TSan), so `add_test()` also
  multiplies the `TIMEOUT` of every test by `FA_SANITIZE_TIMEOUT_FACTOR` (3 for ASan + UBSan, 5 for TSan; a CMake cache
  variable); a test with no `TIMEOUT` gets ctest's 1500 s times the factor. With `FA_COVERAGE` on too the factors are multiplied (one
  helper, `fa_scale_test_timeout`, scales each test once). The limits inside the programs are not scaled:
  the script limits (60 s per `factoria test` test, 5 s of `script.eval`, 2 s of a callback) count CPU time of the script
  thread, which the sanitizers slow down too, and a few tests assert wall-clock bounds (for example the 1.4 s of
  `http_tests.cpp` for a 0.3 s request timeout). If such a test fails only in the sanitizer job, check its time first.
- **CI:** `Linux (Clang, ASan + UBSan, tests 1/2)` and `2/2` (job `linux-asan`: two machines, each runs half of the tests,
  split by `scripts/ctest_shard.py`, below) run the whole Debug suite under Xvfb like the `linux` job does, with
  the example games' tests off as in any Debug build, and the `_perf` budgets (`example_*_perf`, `fixture_skinned_sprites_perf`)
  off too: a sanitizer build has no baseline and its times and memory are not an optimized build's. `Linux (Clang, TSan, threaded tests)` (`linux-tsan`) builds only the
  five test programs with threads and runs the tests of the CTest label `tsan`: the job system and the background reads of
  core, the jobs engine and the background loads of runtime, all of audio and mcp, and the WebSocket cases of platform
  (`tsan_platform_websocket`). Both are part of `CI result` and run
  when the change touches anything but docs. Each runs `sudo sysctl vm.mmap_rnd_bits=28` before the tests: the runner's kernel
  randomizes mappings with more bits than the sanitizers' shadow memory layout supports, and the programs would not start.
- **Suppressions policy:** `tools/ci/sanitizers/` (`asan.supp`, `lsan.supp`, `tsan.supp`, and `ubsan_ignorelist.txt`). A finding
  in our own code (engine, tools, player, tests) is fixed, never listed, with the doctest case that catches it. A finding inside
  `external/`, which is never edited, may be suppressed by file pattern, one entry each with the reason above it
  (`ubsan_ignorelist.txt` is a Clang `-fsanitize-ignorelist` that compiles the listed files without the check, because the UBSan
  runtime ignores its suppression file in a `-fno-sanitize-recover` build: Dear ImGui casts a NaN table width to an integer, and
  tinysoundfont and xatlas call a function through a pointer of another function type, which `-fsanitize=function` aborts).
  `asan.supp` names an Apple system library whose own code ASan flags (CoreGraphics' PDF parser, reached from the editor
  window's controls); LeakSanitizer suppressions name system libraries we cannot free (Mesa, X11, ALSA). A suppression you add
  says why, in the file and in the commit.
- **Reading a report:** `llvm-symbolizer` on the `PATH` (the CI job installs `llvm`; Apple's toolchain has it) gives file
  and line in the stack. `UBSAN_OPTIONS=print_stacktrace=1` is already set.

## Fuzzing

`tools/fuzz/` holds the fuzz targets: each feeds arbitrary bytes to one reader of data other people wrote, and the contract
is that every input is a result or an error, never a crash, a hang, runaway memory or undefined behaviour. The targets are
`json` (`parse_json`), `json_schema` (`validate_json` and the schema helpers), `scene` (`load_scene`), `prefab`
(`entity_from_json`), `pak` (`PackReader::open_memory`, the reader of `game.pak`), `mcp_jsonrpc` (`McpServer::handle_message`
with the read-only capabilities of `factoria mcp --read-only`, over an empty temporary project), `translations`
(`read_csv`, `read_xliff`) and the decoders of the files a project brings: `image` (`decode_image` and `image_size`:
PNG, JPG, TGA, BMP, GIF...), `ktx2` (`ktx2_size` and `decode_ktx2`, the CPU transcode of Basis Universal UASTC and ETC1S),
`gltf` (`parse_skeleton` and `read_gltf_mesh_bytes` on a `.glb` or `.gltf`), `font` (`rasterize_text` with a TrueType font
in memory), `audio` (`decode_audio`; the first input byte picks `.wav`, `.ogg`, `.mp3` or `.qoa`), `midi` (`parse_midi`
and `write_midi`) and `soundfont` (`Soundfont::from_memory` and one rendered note). Each is one `tools/fuzz/targets/<name>.cpp` that defines
`extern "C" int LLVMFuzzerTestOneInput(const std::uint8_t*, std::size_t)`, and a corpus folder of small seed files in
`tools/fuzz/corpus/<name>/`.

**Every desktop build with `FA_BUILD_TESTS` replays the corpus.** Without `FA_FUZZ` (every desktop compiler and platform, MSVC included; not Android, iOS or the web) each target is linked
with a small `main()` (`tools/fuzz/replay_main.cpp`) and registered as a ctest `fuzz_<name>` with the label `fuzz`: it runs
every file of the corpus once, so the seeds and every crash ever found stay regression tests of the normal suite
(`ctest --test-dir build/dev -L fuzz`). The same program also mutates: `build/dev/tools/fuzz/fa_fuzz_pak --mutate 20000 --seed 3
tools/fuzz/corpus/pak` runs 20000 deterministic mutations of the corpus files (set `FA_FUZZ_LAST_INPUT=<file>` to have each
input written there before it runs, so the one that crashed is left behind). That is no coverage-guided fuzzing, but in a
build with `-fsanitize=address,undefined` (AppleClang has no libFuzzer) it is a quick smoke test.

**Real fuzzing needs Clang with libFuzzer** (Linux: `apt install clang libclang-rt-<version>-dev`; Apple's Clang does not
ship libFuzzer, Homebrew's LLVM does):

```bash
cmake -S . -B build/fuzz -G Ninja -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCMAKE_C_COMPILER=clang \
      -DCMAKE_CXX_COMPILER=clang++ -DFA_FUZZ=ON -DFA_BUILD_EDITOR=OFF -DFA_BUILD_TESTS=OFF
cmake --build build/fuzz --target fa_fuzz_all
tools/fuzz/run.sh build/fuzz 60            # every target, 60 s each
tools/fuzz/run.sh build/fuzz 600 pak json  # two targets, ten minutes each
```

`FA_FUZZ` builds the whole tree with AddressSanitizer, UndefinedBehaviorSanitizer (a finding aborts) and coverage
instrumentation, and each target as a libFuzzer program `build/fuzz/tools/fuzz/fa_fuzz_<name>`. `run.sh` runs them over a copy
of the corpus (new inputs land in `build/fuzz/fuzz-work/<name>/`, the repository's corpus is never written) with a 20 s
timeout per input, a 4 GB memory limit and inputs up to 64 KiB; a crash, timeout, out-of-memory or leak leaves its input in
`build/fuzz/fuzz-crashes/` and the script exits 1 after running the other targets. It exits 2 when the run itself is
broken (no program, an unknown target, a program that failed without leaving an input); that wins over 1. CI treats 1 as a
warning with the inputs listed in the job summary and 2 as a failed job. CMake refuses `FA_FUZZ` with any compiler but
Clang.

**The decoders wrap code in `external/`** (stb_image, stb_truetype, cgltf, the Basis Universal transcoder, dr_libs,
stb_vorbis, TinySoundFont): it is not ours to edit, so the engine validates before it calls it. The wrappers cap what a
header can ask for (`kMaxImagePixels` for images, plus a side of at most `kMaxImageSide` for KTX2, 32 audio channels, 8
million reserved frames, `kMaxProceduralVertices` for a glTF once its nodes are placed), `gltf_check_buffer_sizes`
refuses a base64 data URI buffer whose `byteLength` is more than its payload can decode to (cgltf allocates the declared
size before it decodes, so a small file could ask for any amount of memory; every reader of a glTF calls it between
`cgltf_parse` and `cgltf_load_buffers`), `gltf_check` first refuses an accessor, or a sparse indices or values block,
whose real address (the buffer's data plus its offsets) or stride is not a multiple of its component size (cgltf loads
floats and indices through typed pointers, `cgltf_validate` included; the real address also catches a GLB whose JSON chunk
is not a multiple of 4 bytes long, which puts the BIN chunk at an odd address), then runs `cgltf_validate` before any glTF
accessor is read, and `check_font_bytes` walks the tables stb_truetype would follow (stb_truetype has no length parameter). It
refuses the whole font for table offsets, glyph offsets and `cmap` segments outside the file, a `cmap` subtable format
the engine does not read, a font with no glyphs and a glyph 0 that is itself unsafe. A format 4 `cmap` search header is
not required to equal the specification (a few system fonts, such as Shree714.ttc, write other values): the check runs
stb_truetype's binary search on it and refuses it only when the entries it can reach lie outside the subtable, and a
`head` table with 0 units per em (stb_truetype divides by it and gets an infinite scale) is refused. What is wrong with
one glyph does not condemn the font: a glyph that includes itself or nests more than 32 levels, composite glyphs placed
by matching points, contours that do not end at rising points, a last contour of a single point off the curve, or a
composite that draws more than 20000 glyphs is listed as unsafe, `FontFace::stb_glyph` hands stb_truetype glyph 0 (the
`.notdef` box) in its place, and everything else in the font still loads. The `CFF ` table of an `.otf` with PostScript
outlines is walked too (`check_cff_table`, `font_check_cff.cpp`), because stb_truetype gives its CFF reader a 512 MB
window from the start of the table instead of its length: the check repeats what `stbtt_InitFont` reads, in the same
order, with the table's length (header size, the Name, Top DICT, String and Global Subr INDEXes, the Top DICT's
CharStrings, Private, FDArray and FDSelect offsets, the Private DICT and local subroutine INDEX, and the same for every
font dict of a CID font), and refuses a font whose reads leave the table or hit a value stb_truetype asserts on (an
offset size outside 1..4, a reserved DICT operand) with an error that names the part and the offset in the table; its
work is capped at 20 million steps, whatever the CPU. A glyph that the CharStrings INDEX does not hold, or whose
FDSelect entry names no font dict (an FDSelect range that ends before it starts holds no glyph, as in stb_truetype), is
unsafe like the glyphs above, and a CFF font's `hmtx` is checked against `maxp` like a TrueType one's. Smaller checks of
the same kind: a picture with no rows is an error, a KTX2 level whose stored size differs from its unpacked size is
refused before the Basis transcoder asserts on it, the comment header of an Ogg Vorbis file is walked before stb_vorbis
allocates from its lengths (it reads them as signed; a header over 16 MB, such as one with a huge cover picture, is
refused with an error that says it is a size limit, not damage), and `sf2_problem` follows the index chains of a
SoundFont (preset, instrument and sample numbers, zone and generator ranges) before TinySoundFont, which trusts them,
reads it. What stays inside `external/` and is only fuzzed: the charstrings of a CFF font (stb_truetype's interpreter
runs on the INDEX entries the check proved lie inside the table, with an operand stack of 48 and 10 nested subroutines,
so it has no way out of them; a hint mask that runs past its charstring entry makes `stbtt__buf_skip` assert in a build
with assertions and is clamped to the entry without them, so it is memory-safe either way: the fuzz build is
RelWithDebInfo, which defines `NDEBUG`, so the fuzzer does not stop on it, and the Debug `linux-asan` job only replays
the corpus and runs the unit tests, none of which has such a charstring; no charstring walker checks it), the Basis
transcoder's own parsing after the header and level checks, dr_wav, dr_mp3, qoa, stb_vorbis beyond the comment header
(codebooks and setup), TinySoundFont once its tables check out (sample ranges are not checked) and the cgltf parser
itself (`gltf_check` validates accessors, not the JSON parse). The sanitizer build silences UBSan (not ASan) inside
`external/` through `tools/fuzz/ubsan_ignorelist.txt`, which `cmake/FactoriaFuzz.cmake` gives the compiler
(`-fsanitize-ignorelist`; a runtime `UBSAN_OPTIONS=suppressions` does not work with `-fno-sanitize-recover`), so a
benign wrap-around or shift in their code does not stop a run; an out-of-bounds access there still does, and is then
fixed in the wrapper. The `linux-asan` job's own list (`tools/ci/sanitizers/ubsan_ignorelist.txt`) names only the
findings its tests reach, so a UBSan finding in `external/` that only a mutated input reaches (an infinite float scale
from a font with 0 units per em, a misaligned float in a glTF buffer) does not stop the fuzz run, whose list covers all
of `external/`, and would fail that job if one of its tests reached it; `fa_fuzz_font --mutate` and `fa_fuzz_gltf
--mutate` in an `FA_SANITIZE=address;undefined` tree find them, and the engine now refuses both inputs before they get
there.

**Add a target:** write `tools/fuzz/targets/<name>.cpp` (include `fuzz_support.h` for quiet logging, `fa::fuzz::fail()` and
`fa::fuzz::empty_project()`; a target must not write outside a temporary folder, open sockets or start programs), put a few
small seed files (a few KB in all, taken from fixtures, schemas or examples) in `tools/fuzz/corpus/<name>/`, and add
`fa_add_fuzz_target(<name> DEPS <library>)` to `tools/fuzz/CMakeLists.txt`. The ctest, the libFuzzer program and `run.sh`
pick it up.

**Add a crash to the corpus:** reproduce it with `build/fuzz/tools/fuzz/fa_fuzz_<name> build/fuzz/fuzz-crashes/crash-<hash>`,
shrink it with `fa_fuzz_<name> -minimize_crash=1 -runs=100000 crash-<hash>` (it writes `minimized-from-*`), fix the code,
write the doctest for the cause in the module's `tests/` (the fix is not finished without one), and copy the minimized file
to `tools/fuzz/corpus/<name>/` under a name that says what it is. Then `ctest -L fuzz` keeps the bug fixed on every
platform.

**CI:** the job `linux-fuzz` of `.github/workflows/ci.yml` (Clang, `FA_FUZZ=ON`, whenever code changed) builds every target
and runs `tools/fuzz/run.sh build/fuzz 60`. A build error fails the job, which is part of `CI result`. The random minute does
not: a different input is tried on every run, so a crash there is usually not caused by the pull request that happened to
meet it, and it must not block unrelated work. That step is `continue-on-error`; when it fails the job stays green, prints a
warning annotation and a summary, and uploads `build/fuzz/fuzz-crashes` as the artifact `fuzz-crashes`. The corpus replay
(`ctest -L fuzz`, in every normal job) does block: it holds every input that ever crashed.

**Weekly run:** `.github/workflows/fuzz-weekly.yml` (Sundays 03:17 UTC, and by hand from the Actions tab with the minutes per
target) fuzzes each target on its own runner for 25 minutes by default, starting from the corpus of the previous weeks (kept in
the Actions cache). It never commits and never opens an issue. It leaves two artifacts per target: `fuzz-corpus-<name>`, the
corpus after `fa_fuzz_<name> -merge=1` (only inputs that add coverage), and `fuzz-crashes-<name>` with the inputs that
crashed; a target that found one makes the run fail, which is the notification.

**Take a weekly crash into the corpus:** download `fuzz-crashes-<name>` from the run, then follow "Add a crash to the corpus"
above with the file (`fa_fuzz_<name> crash-<hash>` reproduces it in an `FA_FUZZ` build, on Linux or with Homebrew's LLVM on a
Mac). To adopt interesting inputs of `fuzz-corpus-<name>` as seeds, copy a few small ones into `tools/fuzz/corpus/<name>/`
(keep the whole folder to a few tens of KB: it is replayed by every normal build).

## Coverage

`-DFA_COVERAGE=ON` (Clang only, `cmake/FactoriaCoverage.cmake`; Apple clang works, GCC and MSVC stop with an error that says so)
builds every target with `-fprofile-instr-generate -fcoverage-mapping`, and every ctest process writes its raw profile to
`<build>/coverage/raw/` (`LLVM_PROFILE_FILE=.../%4m.profraw` is set on each test by the `add_test` wrapper of
`cmake/FactoriaHelpers.cmake`: `%m` is online merge mode, so the many processes of one binary, cli_integration and the examples
start thousands, update a pool of 4 shared files per binary instead of leaving a full profile each; the `factoria` the editor
autotest starts is covered too). The `TIMEOUT` of every test is multiplied by `FA_COVERAGE_TIMEOUT_SCALE` (default 3; times the sanitizer factor when both
are on), because instrumented Debug runs are slow and a test killed by its timeout writes no profile. `external/` is instrumented too, and left
out of the report.

```bash
cmake -S . -B build/cov -G Ninja -DCMAKE_BUILD_TYPE=Debug -DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++ -DFA_COVERAGE=ON
cmake --build build/cov -j4
xvfb-run -a -s "-screen 0 1280x720x24" ctest --test-dir build/cov --output-on-failure   # Linux; macOS needs no xvfb-run
scripts/coverage-report.sh build/cov            # report in build/cov/coverage/report, or pass an out-dir
```

`scripts/coverage-report.sh` merges the profiles (`llvm-profdata`), reads every `fa_test_*` program, `factoria` and
`fa_editor_autotest` in one merged `llvm-cov export`, and writes `coverage.md` and `coverage.json` (lines, functions and
regions per module: `engine/<m>/` and `tools/<m>/`, with `tools/common` as `tooling`; test code, `external/`, `tools/fuzz` and
`tools/bench` are not counted) and `html/index.html` (every file, line by line). It finds `llvm-cov` with `xcrun` on macOS and
`llvm-cov-<version>` on Linux (`LLVM_COV` / `LLVM_PROFDATA` override). Only the `fa_test_*` programs, `factoria` and
`fa_editor_autotest` are read: `factoria_player` and the plugin `.so` files are not passed as `-object`, so code only they run
is not counted. A report of a subset of the tests is valid: it counts
only what ran. The CI job `coverage` (Ubuntu, Clang, Debug, the whole suite with the editor autotest) does this on every code
change (ctest with `--parallel 2`, without the `perf` label; it can still go red on a timeout of an instrumented test, and the
report is made anyway from the profiles that exist), writes the table to the job summary and uploads the report as the artifact `coverage-report`. It is informative: it is
not part of `CI result`, so a failure of the job (or a number going down) never blocks a merge.

## Golden images

Rendering tests compare a headless picture with a committed PNG: `engine/render/tests/golden/*.png` (`expect_golden`), and
`tools/cli/tests/golden/` for the menus and the mobile-export tests. There is one file per picture for every backend (Metal,
Direct3D 11, GL on Mesa llvmpipe). The render tests (`fa_test_render`) need a GPU and fail without one, so a host with none runs
`ctest -LE gpu`; the CLI golden tests (menus, mobile export) skip with a message when there is no GPU.

- **A missing golden fails the test.** The message names the file and says how to create it. A test never writes its own
  reference: that compared the picture with itself and passed. To make or change a golden, run the test with
  `FA_UPDATE_GOLDENS=1` (the old spelling `FA_UPDATE_GOLDEN=1` still works), look at the PNG it wrote, and commit it with
  the change that explains it. In that mode the test passes after writing, so a run that updates also hides a regression:
  review `git diff --stat` of the golden folders. On a Mac, Linux and Windows the pictures differ a little (below), so
  update a golden only for a change you meant, and run the test on the other hosts' CI afterwards.
- **Three limits, all of which must hold** (`engine/core/tests/golden_check.h`): the mean absolute error over all channels
  (0.004), the share of pixels with a channel more than 4/255 off (8 %) and the largest single-channel error (0.6). The mean
  alone lets one wrong region pass on a big picture: a missing sprite changes under 1 % of the pixels. The share catches a
  wrong region and the largest error catches one wrong pixel, except in goldens with text, thin lines or nearest-sampled edges
  (single pixels flip between ink and background from one GPU to the next): those use `expect_golden_edges`, which allows a
  largest error of 1.0 and keeps the other two, so there only the mean and the share guard against a missing glyph or edge. The header says where each number
  comes from; raise a limit only with a measurement of a backend, written there.
- **Measure on a backend:** `FA_GOLDEN_REPORT=1 fa_test_render` (or `fa_test_cli`) prints `GOLDEN <file> mean=... share=... max=...` for every
  golden compared. The numbers measured on Metal, llvmpipe and Direct3D 11 (WARP and hardware) are in the header of `golden_check.h`; add a new backend's there.
- **A failing comparison** writes the picture it got next to the golden as `<name>.actual.png`, or in the temp folder when
  that folder cannot be written (a read-only checkout); the failure message gives the path. Those files are git-ignored;
  delete them when done.

