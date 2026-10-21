# Performance budgets

A game can get slower or heavier without anyone noticing. FactorIA measures what a run costs and fails a check when it
goes past a budget you committed. The engine does this for its own examples in CI; a game does it with the same three
commands.

## What is measured

`factoria run --headless --json` has a `perf` object in its report:

| Field | Meaning |
| --- | --- |
| `cpuMsAvg`, `cpuMsP95`, `cpuMsMax` | CPU time the engine used per frame, in ms. It is the CPU time of the process (all threads, so GPU driver threads count), not the wall clock: a busy machine moves it less. |
| `cpuClock` | `process`, or `wall` on the web, where the browser gives no CPU time (the web numbers are wall-clock and noisier). |
| `peakMemoryMB` | Peak resident memory of the process. Windows: peak working set. Linux, Android, macOS: `ru_maxrss`. Web: the size of the wasm heap (it never shrinks). |
| `drawCalls`, `entities` | Maximum over the run. |
| `graphics` | The GPU used, `none` when there is no renderer (then `drawCalls` is 0). |

`factoria call perf.measure` runs a project the same way (drawing every frame with the GPU renderer) and returns this as a
`sample` together with the `runner` id.

## Runners and baselines

A baseline is only valid for the kind of machine it was measured on, so budget files key their baselines by a runner id,
`<os>-<compiler>-<renderer>`:

| Runner id | Where |
| --- | --- |
| `linux-gcc-llvmpipe` | Linux, GCC, Mesa llvmpipe (software GL) |
| `windows-msvc-d3d11-warp` | Windows, MSVC, D3D11 WARP (software): a CI runner has no graphics card, so its adapter is the Microsoft Basic Render Driver, which is WARP. On a PC with a card the id is `windows-msvc-d3d11`; `FACTORIA_D3D11_WARP=1` makes it render with WARP and use this id, with numbers close to a runner's but not equal (below) |
| `macos-clang-metal` | macOS, Apple clang, Metal |

Two machines of the same kind still differ: GitHub's Linux runner uses about 25 MB more than WSL on the same code, and
Windows WARP on a PC and on a runner differ by up to 15 MB either way. So a runner's entry is measured on that runner,
and the engine's own entries come from its CI runners' output (a job with no entry prints it, see below).
Set `FACTORIA_PERF_RUNNER=name` to use your own id (a build machine of your own). A runner with no entry in a budget file is
not an error: the check passes with status `no_baseline`, and its result carries `baselineEntry`, the exact JSON to add
under `runners`. `{"requireBaseline":true}` makes it fail instead (error `perf_no_baseline`, with the same entry), so a CI
job cannot pass without checking anything; the engine's own CI does this.

## Budget file

```json
{
  "format": "factoria.perf/1",
  "frames": 300,
  "input": "replays/play.json",
  "tolerance": { "cpuAvg": 1.0, "memory": 0.1 },
  "runners": {
    "linux-gcc-llvmpipe": { "frames": 300, "cpuMsAvg": 4.1, "cpuMsP95": 6.6, "cpuMsMax": 34.3,
                            "peakMemoryMB": 76.8, "drawCalls": 2, "entities": 45, "graphics": "..." }
  }
}
```

`frames` (default 300), `scene` and `input` (a project-relative input replay, see [CLI.md](CLI.md)) say what is run; use
`input` to reach the heavy part of the game, because a game waiting on its title menu costs little.

A limit is `max(baseline * (1 + ratio), baseline + slack)`; the slack keeps a tiny baseline from failing on noise.

| Tolerance key | Default | Applies to | Why |
| --- | --- | --- | --- |
| `cpuAvg`, `cpuP95` (ratio) | 1.0, 1.5 | CPU time per frame, average and 95th percentile | Measured: the same run varies by about 5% on one machine, but CI runners are shared and differ by up to 2x between jobs. The budget catches a game that becomes 2-3x slower, not 20%. |
| `memory` (ratio) | 0.10 | Peak memory | Repeated runs differ by about 1-2%. |
| `drawCalls`, `entities` (ratio) | 0.10 | Max draw calls / entities | Deterministic for a fixed scene and input. |
| `cpuSlackMs`, `memorySlackMB`, `countSlack` | 1, 8, 2 | The slack of each kind of limit | |

`cpuMsMax` is recorded but not checked: one slow frame is mostly the machine.

## The commands

All three work on the project they run in (`--project DIR`) and are also MCP tools.

- `factoria call perf.baseline` measures (3 runs, median time) and writes this runner's entry in `perf.json` (or `{"file":
  "path"}`), keeping the other runners' entries. Run it once per kind of machine, and again when the game got heavier on
  purpose. `{"frames":600,"input":"replays/play.json","tolerance":{"memory":0.2}}` also sets the file's run settings and
  tolerances.
- `factoria call perf.check` measures with the settings of the file and compares. Memory, draw calls and entities past
  their limit always fail. A time past its limit fails when the `CI` environment variable is set (GitHub Actions sets it)
  and only warns (`status: "warn"`) elsewhere, because a developer machine can be busy while the full test suite runs;
  `{"strictTime":true}` makes it fail anywhere. A time over its limit is measured a second time before it counts. A
  failure is the error `perf_budget_exceeded`, with every metric's measured value, limit and baseline.
- `factoria call perf.measure` just measures.

Peak memory is the whole process's, so run the check the same way each time; the engine's own tests use
`factoria call --no-graphics --project <game> perf.check @args.json` (the second engine inside the command has the GPU).

### Setting a budget for your game

1. Make a replay that plays the heaviest part (the editor records one; see CLI.md `--input`).
2. `factoria call perf.baseline '{"input":"replays/play.json"}'` and commit `perf.json`.
3. In your CI, after `factoria test`: `factoria call perf.check`. Add the baseline of the CI runner: the first run prints
   `baselineEntry`; paste it under `runners` (or run `perf.baseline` on that machine).

## The engine's examples

Each example has a ctest, `example_<name>_perf`, comparing a 300-frame run with `tools/cli/tests/perf/<name>.perf.json`.
`perf_regression_detected` proves that the check fails: it uses a baseline lowered far below what the game costs and
expects `perf_budget_exceeded`. After a change that makes an example heavier on purpose, refresh its entry on each runner
with `factoria call perf.baseline` (see the file's `runners`) in the same PR.

Not covered yet: the web and Android players report memory and time with the limits above but have no CI baseline.
