# Creating tools and extending the engine

This guide has two readers. Game-making AIs read section A to add a repeatable tool to a game project, and section G to add native code (C/C++) to a game without changing the engine. Engine developers read sections B to F, which are in [docs/design/EXTENDING_*.md](design/EXTENDING_COMMANDS.md) (repository only, not in the binary) to add commands, components, systems and feedback processing to FactorIA itself.

The examples use the APIs of this build and were checked against it. The reference for the JavaScript side is `docs/SCRIPTING.md`. The reference for the frame and the built-in commands is `engine/runtime/include/fa/runtime/engine.h`.

## Where things go

| You want to add | Put it in | It becomes |
|---|---|---|
| A tool for one game | `tools/<name>.js` in the game project | command `project.<name>`, MCP tool `project_<name>` |
| Native code for one game (an SDK, a platform service) | a native plugin: `factoria call project.new_plugin` (section G) | `plugins.<name>.<function>()` in scripts, commands `<name>.<verb>` |
| A command for the running game | C++ `CommandRegistry::add`, in `engine/runtime/src/` | MCP tool, `factoria call`, editor command, `fa.call` |
| A command for project tooling | C++ `CommandRegistry::add`, in `tools/common/src/` | the same surfaces |
| A new component | a struct in `engine/scene/include/fa/scene/components.h`, registered in `components.cpp` | scene JSON, script views, typings, docs, MCP |
| A per-frame behaviour of the engine | a system called from the frame loop in `engine/runtime/src/` | runs in every game |
| Documentation for AIs | `docs/*.md` | embedded in the binary; MCP resources `factoria://docs/...` |

Every capability is registered once as a command. The same registry feeds MCP, the built-in agent, the CLI, the editor console and scripts. Do not add a one-off CLI flag for a capability that tools or AIs should use.

## A. Project tools (`tools/*.js`)

A project tool is a JavaScript module in the game's `tools/` folder. The file name is the tool name, so `tools/spawn_wave.js` becomes `project.spawn_wave` (CLI and `fa.call`) and MCP tool `project_spawn_wave`. This is the contract in `docs/SCRIPTING.md`.

```js
// tools/<name>.js
import { world, fa } from "factoria";

export default {
  name: "<name>",                 // keep it equal to the file name
  summary: "One line, imperative.",
  description: "What it does, its caveats, and one example call as JSON.",
  input: {                        // JSON Schema for the arguments
    type: "object",
    required: [],
    properties: {},
  },
  readOnly: false,                // true when the tool only reads
  capabilities: ["read", "state"], // optional: what the tool can do, see "Capabilities" below
  run(args) {                     // args are validated; defaults from `input` are filled in
    return { /* any JSON-serializable value */ };
  },
};
```

- **Schema keywords** the validator checks: `type`, `properties`, `required`, `additionalProperties`, `default`, `enum`, `const`, `minimum`, `maximum`, `minLength`, `pattern`, `items`, `anyOf`, `oneOf`. Invalid arguments are refused before `run` is called. The error names the field and gives a hint, such as the allowed values.
- **Closed by default.** A key that `input` (or a nested object with `properties`) does not declare is an error, not an ignored extra: `invalid_arguments`, `/crates: unknown property 'crates'`, with a "did you mean" and the accepted keys in the hint. So declare every key `run` reads, with a `description`. A tool without `input`, or with `properties: {}`, takes no arguments. If the keys really are open-ended (a free-form map), say so: `additionalProperties: true` on that object accepts any key, and `additionalProperties: { type: "number" }` accepts any key whose value matches the schema. A project from before 0.13.0 whose tools or scripts pass extra keys now gets this error: add the missing properties to `input` (or drop the key from the call).
- **Capabilities.** `capabilities` is an optional array of names saying what the tool can do outside the engine's memory: `read`, `state` (changes the running game in memory), `writeProject`, `writeAnywhere`, `network`, `process`, `spend`, `publish` (docs/design/ARCHITECTURE_COMMANDS.md, "Commands", "Capabilities"). A caller that was not granted all of them (a game script gets `read` and `state`) is refused with `capability_denied`. Without the key the set follows `readOnly`: `["read"]` when it is true, `["read", "state", "writeProject"]` otherwise, so a tool that only changes the world in memory should declare `["read", "state"]` and one that talks to a server `["read", "network"]`. A tool with `capabilities` also gets `readOnly: true` only when the set is exactly `["read"]`. A name that does not exist (`"writeProjct"`) is a script error with the file, the position in the array and a "did you mean"; the tool is not registered until it is fixed.
- **Hot reload.** Saving the file reloads the tool. MCP clients receive `notifications/tools/list_changed`.
- **Errors.** Two kinds, and the caller sees them differently.
  - An *expected* failure, such as a check that found bad level data, is `throw new ToolError(message, hint, data?)` (import it from `"factoria"`). The caller gets code `tool_error`, the message, and your `hint`, which says how to fix the data or the call. `data` is an optional object with details. It appears in the JSON error of `factoria session` and `factoria call --batch`, and as `e.data` on the Error that `fa.call` throws in a script or test; MCP shows only the code, message and hint, so put what a fixer needs into the hint.
  - Any other exception is a script bug. The caller gets code `failed`, the message with `file:line`, and the error is also recorded as a script error.
  - Arguments that break the `input` schema are refused before `run` is called, with a message that names the field.
- **Calling.** MCP: `project_<name>`. CLI: `factoria call project.<name> '<json>'`. Scripts: `fa.call("project.<name>", {...})`.

### A.1 Level generator: writes a scene file

It builds a scene from parameters and writes it with the `fs.write` command. It is read-write, so the description says that it overwrites the file.

```js
// tools/gen_arena.js
import { fa, rng } from "factoria";

export default {
  name: "gen_arena",
  summary: "Generate a scene with random crates and write it to a .scene.json file.",
  description: 'Example: {"path":"scenes/arena.scene.json","crates":12,"width":800,"height":480,"seed":7}. Overwrites the file; the same seed gives the same arena. Run project_validate afterwards.',
  input: {
    type: "object",
    required: ["path"],
    properties: {
      path: { type: "string", pattern: "\\.scene\\.json$", description: "Project-relative path ending in .scene.json." },
      crates: { type: "integer", minimum: 0, maximum: 200, default: 12, description: "How many crates to place." },
      width: { type: "number", minimum: 100, default: 800, description: "Width of the area, in pixels." },
      height: { type: "number", minimum: 100, default: 480, description: "Height of the area, in pixels." },
      seed: { type: "integer", default: 1, description: "Seed; the same seed gives the same arena." },
    },
  },
  readOnly: false,
  run({ path, crates, width, height, seed }) {
    const r = rng.create(seed); // own generator: rng.seed() would reseed the one RNG the running game draws from
    const entities = [
      { id: "camera", components: { Camera: { projection: "orthographic", clearColor: [0.1, 0.1, 0.15, 1], primary: true } } },
    ];
    for (let i = 0; i < crates; i++) {
      entities.push({
        id: `crate_${i}`,
        tags: ["crate"],
        components: {
          Transform: { position: [r.range(-width / 2, width / 2), r.range(-height / 2, height / 2), 0] },
          Shape2D: { shape: "rectangle", size: [40, 40], color: [0.6, 0.4, 0.2, 1] },
        },
      });
    }
    const scene = { format: "factoria.scene/1", settings: { gravity2D: [0, 0] }, entities };
    const written = fa.call("fs.write", { path, content: JSON.stringify(scene, null, 2) + "\n" });
    return { path: written.path, entities: entities.length };
  },
};
```

`rng.create(seed)` returns an independent generator (`float`, `range`, `int`, `chance`, `pick`, `shuffle`, `seed`) that never touches the world RNG, so the tool does not change the random sequence of the game that is running. Its algorithm (mulberry32) is stable across engine versions, so a seed you store keeps giving the same arena. `rng.seed(n)` would reseed the game's own RNG instead.

To write the state of the live world instead, call `scene.save` with `fa.call` (its arguments are in `docs_commands`).

### A.2 Balancing tool: reads `game.state`

It is read-only. It reads the running game through `game.state` and reports the enemies that are too fast.

```js
// tools/balance_report.js
import { fa } from "factoria";

export default {
  name: "balance_report",
  summary: "Report the speed of every enemy in the running game and flag the fast ones.",
  description: 'Example: {"maxSpeed": 400}. Read-only. Reads game.state, so load the level first (scene_load or game_step).',
  input: {
    type: "object",
    properties: {
      maxSpeed: { type: "number", minimum: 0, default: 400, description: "Enemies faster than this are flagged." },
    },
  },
  readOnly: true,
  run({ maxSpeed }) {
    // Ask only for the Script component, and raise the default cap of 200 entities.
    const state = fa.call("game.state", { components: ["Script"], maxEntities: 1000 });
    // Entities have the scene-file shape (id, name, tags, components).
    const enemies = state.entities.filter((e) => (e.tags ?? []).includes("enemy"));
    if (enemies.length === 0) {
      throw new Error("No entity tagged 'enemy' in the running game. Load the level, or check the tags in its scene file.");
    }
    const flagged = [];
    for (const e of enemies) {
      const speed = e.components?.Script?.props?.speed;
      if (typeof speed === "number" && speed > maxSpeed) flagged.push({ id: e.id, speed });
    }
    // game.state sets "truncated" when some entities were left out.
    return { enemies: enemies.length, truncated: state.truncated === true, flagged };
  },
};
```

### A.3 Asset checker: finds unused and oversized files

It uses `fs.list` and `fs.read`. A file counts as used when its project-relative path appears in a scene, a prefab or a script. This is a heuristic, so check the list before you delete anything.

```js
// tools/check_assets.js
import { fa } from "factoria";

// Files under a project folder. A missing folder is treated as empty.
// fs.list returns at most 500 entries unless a limit is given, so ask for more.
function filesUnder(dir) {
  try {
    return fa.call("fs.list", { path: dir, recursive: true, limit: 10000 }).entries.filter((e) => e.type === "file");
  } catch (_) {
    return [];
  }
}

export default {
  name: "check_assets",
  summary: "List assets that no scene, prefab or script mentions, and assets over a size limit.",
  description: 'Example: {"maxKb": 512}. Read-only. Paths are project-relative, for example "assets/sfx/jump.wav".',
  input: {
    type: "object",
    properties: {
      maxKb: { type: "number", minimum: 1, default: 512, description: "Files larger than this are reported." },
    },
  },
  readOnly: true,
  run({ maxKb }) {
    const assets = filesUnder("assets");
    const sources = [];
    for (const dir of ["scenes", "prefabs", "scripts"]) {
      for (const f of filesUnder(dir)) sources.push(fa.call("fs.read", { path: f.path }).content);
    }
    const text = sources.join("\n");
    return {
      assets: assets.length,
      unused: assets.filter((a) => !text.includes(a.path)).map((a) => a.path),
      tooBig: assets
        .filter((a) => a.size > maxKb * 1024)
        .map((a) => ({ path: a.path, kb: Math.round(a.size / 1024) })),
    };
  },
};
```

### A.4 Rules for good project tools

- Keep one job per tool. Return ids and counts rather than large dumps.
- Set `readOnly: true` for queries. Agents use the flag to decide what is safe to call.
- Say in `description` whether the tool overwrites files or changes the running game.
- A tool does not step the simulation unless its description says so.
- Tools can use everything in `"factoria"` and every command through `fa.call`.
- A check that can find several problems reports all of them in one result (section A.5), not one error per run.

### A.5 A check that reports every problem

A `ToolError` names one failure. When the caller needs the whole list (every coin out of bounds, every broken reference), return the list as a normal result instead. Every surface shows a normal result in full, while MCP shows a thrown error only as its message and hint. Let the caller read `ok`:

```js
// tools/check_coins.js
import { world } from "factoria";

export default {
  name: "check_coins",
  summary: "List every coin below a height, so one run shows all of them.",
  description: 'Example: {"minY": -300}. Read-only. Returns every coin below minY, not just the first one.',
  input: {
    type: "object",
    properties: { minY: { type: "number", default: -300, description: "Coins below this height are reported." } },
  },
  readOnly: true,
  run({ minY }) {
    const coins = world.findByTag("coin");
    const low = coins.filter((c) => c.position.y < minY).map((c) => ({ id: c.id, y: c.position.y }));
    return { ok: low.length === 0, coins: coins.length, low };
  },
};
```

Use `throw new ToolError(...)` when the failure is a single fact and the hint can carry the whole fix, for example a missing scene file.

### A.6 Validating the cross references of your data tables

A game's `data/*.json` tables name each other (a recipe names goods, a ship names a port). A typo there is found at play
time by the game's own code, unless a project tool checks it. `didYouMean(word, choices)` from `"factoria"` returns the
closest choice (or `""`), so the tool can say what was meant. Report every problem in one result (A.5), with the file, the
JSON pointer and a hint; throw a `ToolError` when the tables cannot even be read:

```js
// tools/validate_data.js
import { ToolError, didYouMean } from "factoria";
import goods from "../data/goods.json";
import recipes from "../data/recipes.json";

export default {
  name: "validate_data",
  summary: "Check that every recipe names goods that exist.",
  description: "Read-only. Returns ok and a list of problems, each with file, pointer, message and hint.",
  input: { type: "object", properties: {} },
  readOnly: true,
  run() {
    if (!Array.isArray(recipes)) {
      throw new ToolError("data/recipes.json must be an array of recipes", 'Start the file with [ { "id": "plank", "needs": ["wood"] } ]');
    }
    const ids = Object.keys(goods);
    const problems = [];
    recipes.forEach((recipe, i) => {
      (recipe.needs ?? []).forEach((good, j) => {
        if (ids.includes(good)) return;
        const near = didYouMean(good, ids);
        problems.push({
          file: "data/recipes.json",
          pointer: `/${i}/needs/${j}`,
          message: `recipe '${recipe.id}' needs '${good}', which is not in data/goods.json`,
          hint: near ? `Did you mean '${near}'?` : `Goods: ${ids.join(", ")}.`,
        });
      });
    });
    return { ok: problems.length === 0, problems };
  },
};
```

Call it with `factoria call project.validate_data`, or from a test with `fa.call("project.validate_data")`.

## B to F. Engine development (commands, components, systems, checklists, feedback)

These sections are for engine developers and live in the engine's source docs (`docs/design/`), which are not embedded in
the binary: `docs.read` does not serve them, read them in a checkout of the repository.

- **B. C++ commands in the engine** (where to register one, the full example `scene.count_by_tag`, its test): [EXTENDING_COMMANDS.md](design/EXTENDING_COMMANDS.md) (repository only, not in the binary).
- **C. Adding a component** (reflection cheat-sheet, the full example `Wobble`, what you get without extra code) and **D. Adding a system to the frame loop** (the phase, the full example `update_wobble`, the rules for systems): [EXTENDING_COMPONENTS.md](design/EXTENDING_COMPONENTS.md) (repository only, not in the binary).
- **E. Checklists** (naming, doc strings, errors that teach, tests, documentation, the rules of `CLAUDE.md`): [EXTENDING_CHECKLISTS.md](design/EXTENDING_CHECKLISTS.md) (repository only, not in the binary).
- **F. Processing `ENGINE_FEEDBACK.json`** (clusters, feedback from every installation, `feedback fixed`): [EXTENDING_FEEDBACK.md](design/EXTENDING_FEEDBACK.md) (repository only, not in the binary).

## G. Native plugins (C/C++ for one game)

A native plugin is C code (or C++, Rust, anything that exports a C function) that one game ships with: a store or
platform SDK, a library with no JavaScript version, code that must be native. It adds script functions
(`plugins.<name>.<function>(...args)`) and commands (`<name>.<verb>`: MCP tools, `factoria call`, `fa.call`) to that
game only, without changing or rebuilding the engine. Its whole interface is one C header,
`engine/runtime/include/fa/runtime/fa_plugin.h`, which every new plugin gets a copy of.

### G.1 Create, build, run

```bash
factoria call project.new_plugin '{"name": "example"}'
cmake -S plugins/example -B plugins/example/build -DCMAKE_BUILD_TYPE=Release
cmake --build plugins/example/build --config Release
factoria run
```

`project.new_plugin` writes `plugins/example/` (`src/plugin.c`, `include/fa_plugin.h`, `CMakeLists.txt`, `README.md`,
and `android/`, the Gradle module of the Android build) and a `.gitignore` for its build output, and declares the plugin in `factoria.json` (only `plugins.<name>` is added: the file is patched, not rewritten; `"dryRun": true` lists the `files` and `keys` it would write and writes nothing). Its `CMakeLists.txt`
copies the library into the plugin's folder for this computer: `windows/example.dll`, `macos/libexample.dylib` or
`linux/libexample.so` (for Android, [MOBILE.md](mobile/MOBILE_ANDROID.md#native-plugins-on-android) builds it once per ABI). The plugin it writes
is complete (`"template"` picks another starting point: the folders of `platforms/plugins/` in the engine, ready-made
store backends: `"steam"` is the Steamworks plugin ([PLATFORM.md](platform/PLATFORM_BACKENDS.md#steam-steamworks)), `"googleplay"` the
Google Play one, a C bridge plus a Java module with Billing, Play Games and Play Integrity: the example to copy for an
Android SDK ([PLATFORM.md](platform/PLATFORM_APPLE_GOOGLE.md#7-google-play-billing-play-games-services-and-play-integrity)), and `"admob"` the ads backend for
Android and iOS (Google's consent form and rewarded ads, Apple's tracking sheet on iOS; it offers only the `ads` service, so it works next to a store backend,
[PLATFORM.md](platform/PLATFORM_ADS.md#8-ads-google-admob-and-consent-on-android-and-ios)); `factoria call
platform.add_backend` sets one up in a single step; an unknown name lists the ones there are):

```js
plugins.example.add(1, 2)       // 3, computed in C (in its Java class on Android)
fa.call("example.info", {})     // {plugin: "example", platform: "windows", apiVersion: 4}
```

### G.2 The declaration

```json
"plugins": {
  "example": { "path": "plugins/example", "platforms": ["windows", "macos", "linux"] },
  "steam":   { "path": "${STEAMWORKS_PLUGIN}", "platforms": ["windows"] }
}
```

- **Name.** Lower-case letters, digits and underscores, starting with a letter. Not an engine area (`scene`, `game`,
  `project`, ...): the plugin's commands are `<name>.<verb>`.
- **`path`.** The plugin's folder: relative to the project, absolute, or with `${VARIABLE}` parts read from the
  environment. A variable keeps a private SDK outside the repository: each developer sets it to their own copy.
- **`platforms`.** The platforms it is built for. Without it, the game's `platforms`, or all five. On a platform it is
  not built for, `plugins.<name>` is `undefined`, so scripts can test for it.
- **`optional`.** `true` when the game runs without the plugin (default `false`). A missing build for this computer is then
  a warning in `factoria validate`, not an error. Without the build, `plugins.<name>` still exists but throws "the native
  plugin is not loaded" when a function is used, and the runtime logs a warning and goes on, so wrap calls in
  `try`/`catch` or rely on what the plugin provides (a store backend falls back to the development fake store).
  `project.new_plugin` and `platform.add_backend` write `"optional": true` (pass `optional: false` to `project.new_plugin` for a
  plugin the game cannot do without). `factoria export` still fails without the build for the target platform (optional or
  not), so a store build cannot ship without it by accident; `--allow-missing-plugins` (the `project.export` argument
  `allowMissingPlugins`) is the deliberate way around it: the export leaves out every plugin whose build is missing, names
  each in a warning and lists them in `pluginsLeftOut`. It works for a plugin that is not `optional` too, and says in
  the warning that scripts calling it will fail. A plugin is built only for the computer it is built on, so for the other
  platforms take its build from CI or the other computer ([EXPORTING.md](exporting/EXPORTING_DESKTOP.md#desktop-linux-windows-macos)).

The folder holds one build per platform:

| Platform | Build | The export |
|---|---|---|
| Windows | `windows/<name>.dll` | copies `windows/` next to the `.exe` |
| macOS | `macos/lib<name>.dylib` | copies `macos/` into `Contents/Frameworks` (the app is signed with `--deep`) |
| Linux | `linux/lib<name>.so` | copies `linux/` next to the executable |
| iOS | `ios/iphoneos/lib<name>.a` and `ios/iphonesimulator/lib<name>.a` | copies `ios/` to `plugins/<name>/` next to `build_ios.sh`, which links the library of the SDK into the app ([MOBILE.md](mobile/MOBILE_IOS.md#native-plugins-ios)) |
| Android | `android/`: a Gradle library module (`build.gradle`) with `src/main/jniLibs/<abi>/lib<name>.so` and the Java it calls, or `.aar` / `.jar` files | adds the module to the Gradle project (`plugins/<name>`), or the archives to the app; the APK carries `lib<name>.so` for `arm64-v8a` and `x86_64` |

Libraries the plugin needs go next to it, in the same folder: the template's `CMakeLists.txt` sets the run path to
the plugin's folder (`$ORIGIN`, `@loader_path`), and Windows looks in the DLL's folder. The Android build (the module,
the NDK build of the library, Java code) and the iOS build (two static libraries) are described in
[MOBILE.md](mobile/MOBILE_ANDROID.md#native-plugins-on-android).

**The manifest, `ios/plugin.json` and `macos/plugin.json`** (optional). A library cannot tell the export what the app that
ships it must do, so the plugin says so in a small file in its platform folder:

```json
{
  "frameworks": ["StoreKit", "GameKit"],
  "swift": true,
  "entitlements": { "com.apple.developer.game-center": true }
}
```

`frameworks` are system frameworks the iOS app links (a static library cannot), `swift` gives the iOS app the Swift runtime
for a plugin written in Swift, and `entitlements` are capabilities the signed app needs (Game Center, iCloud, ...; values
are booleans, numbers, strings or lists of strings, and may use Xcode's `$(TeamIdentifierPrefix)` and `$(CFBundleIdentifier)`).
`factoria export --platform ios` merges the manifests of all plugins (two plugins that ask for the same entitlement with
different values fail the export, naming both) into the Xcode project's frameworks, Swift runtime and
`factoria_player.entitlements`. `factoria export --platform macos` reads only `entitlements`, from `macos/plugin.json`: it
writes them to `<game>.entitlements` next to the app, because only a signature with the developer's certificate and a
provisioning profile can carry restricted ones. The file never ships inside the app and the plugin never sees it. The
Apple backend (`platforms/plugins/apple`, [PLATFORM.md](platform/PLATFORM_APPLE_GOOGLE.md#6-apple-storekit-2-game-center-and-icloud)) is the
example, and [MOBILE.md](mobile/MOBILE_IOS.md#native-plugins-ios) has the details of the iOS side.

A plugin written in Swift needs a small C file for the entry point: the Swift code exports a function with `@_cdecl` (the
Apple plugin's is `fa_apple_init`) and `FA_PLUGIN_INIT(<name>)` in the C file calls it, so `fa_plugin_init` (a dylib) or
`fa_plugin_init_<name>` (the iOS static library) is a C symbol like any other plugin's. The Apple plugin's `CMakeLists.txt` shows how `xcrun swiftc` builds the macOS dylib and
the two iOS libraries.

### G.3 Checks and failures

- `factoria validate` checks every plugin: a missing build for this computer is an error, one for another platform a
  warning (only that export fails). Errors name the file that is missing and the variable that is not set.
- `factoria export` fails when the build for the platform it exports is missing. A plugin's folder inside the project
  is left out of `game/`: its sources do not ship.
- A plugin that does not load (a missing build, an entry point that fails, a missing dependency) does not stop the
  game: it is a warning in the log, and a script that uses it gets an error with the reason. A collaborator without a
  private SDK can still run the game.
- A library is loaded once per process and never unloaded: after rebuilding a plugin, restart `factoria run` (or the
  editor).

### G.4 The API

```c
#include "fa_plugin.h"

static const FaPluginApi* g_api;

static void add(FaCall* call, const char* args_json, void* user) {   // args_json: "[1,2]"
    double a = 0, b = 0;
    if (sscanf(args_json, " [ %lf , %lf ]", &a, &b) != 2) {
        g_api->fail(call, "add(a, b) takes two numbers", "plugins.example.add(1, 2)");
        return;
    }
    char out[64];
    snprintf(out, sizeof out, "%.17g", a + b);
    g_api->reply(call, out);                                          // the result, as JSON text
}

FA_PLUGIN_INIT(example) {
    g_api = api;
    FaFunctionDesc fn = {"add", "add(a, b): the sum of two numbers.", add, NULL};
    return api->add_function(api, &fn);                               // 0 = loaded
}
```

- **Entry point.** `FA_PLUGIN_INIT(<name>)` defines the exported `fa_plugin_init`. The engine calls it once, before the
  game starts. It registers everything and returns 0; another value is a failure (the plugin is not loaded).
- **`add_function(api, &FaFunctionDesc)`.** `name` is a JavaScript identifier; `doc` is required and goes into
  `types/factoria.d.ts`. The handler gets the arguments as a JSON array.
- **`add_command(api, &FaCommandDesc)`.** `name` is `<plugin>.<verb>` in snake_case; `summary` is required;
  `input_schema` is JSON Schema text (defaults are filled in before the call). The handler gets the arguments as a
  JSON object. The command's category is the plugin's name.
- **Answers.** `reply(call, json)` or `fail(call, message, hint)`, once, before the handler returns; scripts get
  `fail` as an exception (`plugins.example.add failed: message (hint: ...)`), commands as a `failed` error.
- **Also.** `log(api, level, message)` (0 debug, 1 info, 2 warning, 3 error; the category is the plugin's name),
  `api->plugin` and `api->platform`, `native_handle(name)` for platform objects (Android: `"android.activity"`, the
  `ANativeActivity*`). `api->version` is `FA_PLUGIN_API_VERSION`; the struct only grows at its end.
- **Threads and memory.** Handlers run on the game's thread. Strings passed to the engine are copied. Never let a C++
  exception leave a handler.
- **Platform backends (version 2).** A plugin that wraps a store SDK registers a backend with
  `add_backend(api, &FaBackendDesc)` (one per plugin, inside the entry point): `name` (the key of the catalog's `ids`),
  `services` (a JSON array: `"achievements"`, `"stats"`, `"leaderboards"`, `"cloudSave"`, `"purchases"`, `"overlay"`,
  `"presence"`, `"integrity"`, `"ads"`, `"remotePlay"`), `request(req, method, args_json, user)` and an optional `frame(user)` (once per frame on the game
  thread, before scripts: `SteamAPI_RunCallbacks`, or Steam's manual dispatch as the Steam plugin does). The game's `platform.*` calls arrive in `request` with their ids
  already checked; answer each `FaRequest*` exactly once with `resolve(req, result_json)` or `reject(req, code,
  message, hint)`, now or later and from any thread, and push unasked news with `emit(api, "purchase" | "overlay" |
  "player" | "remotePlay", data_json)`. A plugin built for version 2 checks `api->version >= 2`; a version 1 plugin keeps working.
  [PLATFORM.md](PLATFORM.md), section 5, has the method table and a minimal backend.
- **Platform keyboard (version 3).** A plugin that has a keyboard of the platform for gamepad players (the Steam plugin's
  Steam Deck keyboard) registers `add_text_input(api, handler, user)` (one per plugin, inside the entry point). The engine calls
  `int handler(const FaTextInput* in, void* user)` on the game thread, in the frame's UI update, when a `TextField` takes the
  focus while the last input was a gamepad (or the pad's submit button is pressed on the focused field again), with
  `focused` 1, the field's rectangle `x, y, width, height` in window pixels, its `text`, `max_length` (0 = no limit) and
  `multiline`, `password` (both 0: `TextField` has neither yet). Return nonzero when the platform shows its own keyboard:
  `input.platformKeyboard` is then true until the field loses the focus, and the menu kit's on-screen keyboard stays closed.
  When the field loses the focus (or goes away) the handler of the plugin that took it is called with `focused` 0, to take
  its keyboard down; its return value is ignored. Text the keyboard returns goes back with `submit_text(api, utf8)`
  (any thread): at the start of the next frame it replaces the text of the field that took the keyboard, if it still has the
  focus (cut to `maxLength`, control characters dropped, `ui.change` sent); otherwise it is dropped. A keyboard that types key
  presses into the window, like Steam's floating one, needs no `submit_text`. A plugin built for version 3 checks
  `api->version >= 3` before it reads `add_text_input` or `submit_text`; version 1 and 2 plugins are not affected.
- **Device facts (version 4).** `set_device_fact(api, "steamDeck", 0 or 1)` tells the engine something about the machine that
  only the plugin can know. The only name today is `steamDeck`: `game.device.steamDeck` (and `handheld`) follow it, and when
  no plugin says anything the `SteamDeck=1` environment variable is used. The Steam plugin calls it once Steam is running, with
  `IsSteamRunningOnSteamDeck`. Call it from the entry point: the engine reads it when the entry point returns. A plugin
  built for version 4 checks `api->version >= 4` first; older plugins are not affected.
- **Capabilities (version 5).** A command that declares nothing gets `{read}` when `read_only` is 1 and `{read, state,
  writeProject}` otherwise. A command that does more (talks to a server, starts a program, writes outside the project) or
  less (changes only memory: `{read, state}`) says so with `set_command_capabilities(api, "<plugin>.<verb>", "[\"read\",
  \"network\"]")` after its `add_command`, inside the entry point. Names: `read`, `state`, `writeProject`, `writeAnywhere`,
  `network`, `process`, `spend`, `publish` (docs/design/ARCHITECTURE_COMMANDS.md, "Commands", "Capabilities"). A caller that was not granted
  all of them (a game script gets `read` and `state`) gets `capability_denied`; `read_only` follows the declaration (1 only
  for `["read"]`). A plugin built for version 5 checks `api->version >= 5` first.
