# Fuzzing

Programs that feed random and mutated bytes to the parts of the engine that read files and messages other people wrote,
looking for crashes, hangs, runaway memory and undefined behaviour. Full instructions: [docs/BUILDING.md](../../docs/BUILDING.md),
"Fuzzing". This folder:

| Path | What |
|---|---|
| `targets/<name>.cpp` | one target: `extern "C" int LLVMFuzzerTestOneInput(const uint8_t*, size_t)` |
| `corpus/<name>/` | small seed files of the target, and every input that ever crashed it |
| `fuzz_support.h` | what the targets share: quiet logging, an empty project folder, `fail()` |
| `replay_main.cpp` | the `main()` of a target in a normal build: runs each corpus file once (and `--mutate N`) |
| `run.sh` | runs the libFuzzer programs of an `FA_FUZZ` build for N seconds each; CI uses it |
| `CMakeLists.txt` | one `fa_add_fuzz_target(<name> DEPS <library>)` line per target |

Targets: `json` (parse_json), `json_schema` (validate_json and the schema helpers), `scene` (load_scene), `prefab`
(entity_from_json), `pak` (PackReader::open_memory), `mcp_jsonrpc` (McpServer::handle_message, read-only capabilities, an
empty project) and `translations` (read_csv, read_xliff).

Two builds, one source:

- **Normal build** (every compiler and platform): each target is a ctest named `fuzz_<name>` with the label `fuzz`, which
  runs every file of its corpus once. The corpus is a regression suite: `ctest -L fuzz`.
- **`-DFA_FUZZ=ON`** (Clang with libFuzzer, Linux; the CI job `linux-fuzz`): the engine and the targets are built with
  AddressSanitizer, UndefinedBehaviorSanitizer and coverage instrumentation, and each target is a libFuzzer program.
