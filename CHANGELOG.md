# What's new in FactorIA

The editor shows these notes when it offers an update, and each release on GitHub uses its section. Newest first.

Older versions, one file per minor version with its patch releases: [0.28](changelog/0.28.md), [0.27](changelog/0.27.md), [0.26](changelog/0.26.md), [0.25](changelog/0.25.md), [0.24](changelog/0.24.md), [0.23](changelog/0.23.md), [0.22](changelog/0.22.md), [0.21](changelog/0.21.md), [0.20](changelog/0.20.md), [0.19](changelog/0.19.md), [0.18](changelog/0.18.md), [0.17](changelog/0.17.md), [0.16](changelog/0.16.md), [0.15](changelog/0.15.md), [0.14](changelog/0.14.md), [0.13](changelog/0.13.md), [0.12](changelog/0.12.md), [0.11](changelog/0.11.md), [0.10](changelog/0.10.md), [0.9](changelog/0.9.md), [0.8](changelog/0.8.md), [0.7](changelog/0.7.md), [0.6](changelog/0.6.md), [0.5](changelog/0.5.md), [0.4](changelog/0.4.md), [0.3](changelog/0.3.md), [0.2](changelog/0.2.md), [0.1](changelog/0.1.md).

## Unreleased

### Added

- `websocket.connect(url, options)` for game scripts: WebSocket connections to the hosts `factoria.json` `network.hosts` declares (the
  same list, errors and `did you mean` as `http.fetch`), with `on`/`off`/`send`/`close`, text and binary messages, subprotocols,
  headers, and reconnects with exponential backoff and a jitter that is the same on every run. A scene change closes the
  connections without events. This is the shared part: the interface (`fa/platform/websocket.h`), an RFC 6455 codec
  (`fa/platform/websocket_codec.h`), a loopback test server, a scripted in-memory server for tests and headless runs
  (`game.websocket`), and the script API. The clients of the platforms (WinHTTP, `NSURLSessionWebSocketTask`, libcurl, Android,
  the browser) come in the same milestone; until then `websocket.supported` is false outside tests and a connection fails with an
  `"error"` and a `"close"` event (docs/NETWORKING.md, "WebSocket").
- `factoria validate` warns about a script that calls `websocket.connect` in a game with no `network` hosts, as it does for
  `http.fetch`.

## 0.29.1

FactorIA 0.29.1 fixes the two crashes the weekly fuzz run found in 0.29.0: a damaged PostScript (`CFF `)
font made stb_truetype read outside the file, and a small `.gltf` could ask for 2^63 bytes of memory. Fonts and glTF
models are now checked before the third-party readers see them, and a damaged one is an error that names the part
and how to fix it.

### Fixes

- glTF: a small `.gltf` whose base64 buffer declared a huge `byteLength` made the engine ask for that much memory (the
  weekly fuzz run found 2^63-1 bytes). Every glTF reader now refuses it, before cgltf allocates, with an error that names
  the file, `/buffers/N`, the declared size and the most the data can hold. The input is in the fuzz corpus and in
  `fa_test_scene`.
- glTF: an accessor whose start in its buffer, or whose stride, is not a multiple of its component size (a float read
  from an odd address) is refused with an error that names `/accessors/N`, instead of being read through a misaligned
  pointer. This changes behaviour: a model with a misaligned accessor (the glTF specification forbids it, but some old
  exporters wrote it) that loaded before is now refused; the error names
  `/accessors/N` and the fix is to export the model again. A GLB whose JSON chunk is not a multiple of 4 bytes long is
  refused the same way.
- Fonts: an `.otf` with PostScript outlines (a `CFF ` table) whose INDEXes, Top DICT or Private DICT point outside the
  table made stb_truetype read outside the file while loading (found by the weekly fuzz run). The `CFF ` table is now
  walked before stb_truetype sees it: a damaged one is an error that names the part (Name INDEX, Top DICT, FDArray...),
  its offset in the table and what is wrong. A glyph the CharStrings INDEX or the FDSelect has no entry for is drawn as
  the `.notdef` box, and a CFF font whose `hmtx` table is shorter than its glyph count is refused like a TrueType one.
- Fonts: a font whose `head` table says 0 units per em (stb_truetype's scale would be infinite) is an error that says so,
  for TrueType and CFF fonts. An FDSelect (format 3) range that ends before it starts no longer condemns a CFF font: the
  glyphs no range holds are drawn as `.notdef`.

## 0.29.0

FactorIA 0.29.0 (M96) makes the exported player smaller and its scripts safer to ship. The commands only developer tools
need (clip, bone and skin editing, the effect and mesh tools, the ASCII level import and edit, prefab saving and scene
formatting) live in a new library, `fa_authoring`, that the CLI, the editor and MCP link and the player does not, and
the export refuses a game whose scripts call one of them. CI measures the player on every platform against a size
budget, and two project settings give scripts a heap cap and a per-frame time budget that the profile and the log
report.

- **A new library, `fa_authoring`, for the commands only developer tools need.** The first step of splitting
  `fa_runtime` so that an exported game's player carries no authoring code: `tools/authoring` links on top of the
  runtime, and the `factoria` CLI, the editor, the MCP/DAP/AI servers and their tests get its commands, the player does
  not (the CMake configure fails when `factoria_player` reaches it). `prefab.save` and `scene.format` are the first to
  move; their names, arguments and results do not change. For engine developers: `fa/runtime/command_extension.h` is a
  process-wide list of command extensions that `Engine::init` runs after the built-in and plugin commands,
  `fa::authoring::install()` registers the authoring one (call it once before the first Engine), and
  `Engine::runtime_command_names()` lists what the player has. `Engine::Impl` is now declared in
  `fa/runtime/internal/engine_impl.h`, for engine tools only. The clip, bones and skin commands (`anim.*`,
  `bones.create`, `skin.*`) moved there too, with their tests; same names, arguments and results. The effect and mesh
  tools move too: `vfx.check`, `vfx.budget`, `vfx.filmstrip` and `mesh.create`, `mesh.update`, `mesh.destroy`,
  `mesh.save`, `mesh.list`, `mesh.info` are no longer in the player (the `vfx` and `mesh` APIs of scripts are unchanged,
  and so are `vfx.play`, `vfx.stop` and `vfx.list`). `scene.import_ascii` (the ASCII level import that can also write a
  scene file) and `scene.ascii_edit` move too, so an exported game no longer has them; `scene.place_ascii` (the
  running-world import that `tilemap.generate` with `place` uses), `tilemap.set_tile`, `tilemap.cell_at` and
  `tilemap.cell_to_world` stay in the player. Their arguments and results do not change.
- Player size budgets: CI measures `factoria_player` on every platform (Linux, macOS, Windows, Android, web in `ci.yml`;
  also iOS and the macOS universal binary in `release.yml`), fails above the `maxBytes` of
  `tools/size/player_size_budget.json`, and writes a report with what each library adds (artifact
  `player-size-<platform>`, job summary). The new CMake option `FA_PLAYER_LINK_MAP` makes the player's link write its
  map. `scripts/player-size.sh update` takes a measurement as the new baseline. The size step is the last of its job (a
  player over its budget does not skip the tests), and a link map the script cannot read only adds a `note` to the
  report. The Android job of `ci.yml` now builds Release with `ANDROID_SUPPORT_FLEXIBLE_PAGE_SIZES=ON` (the flag
  release.yml uses), so no PR job builds an Android Debug anymore. Every platform's budget is its size in the M96 CI run
  plus 10 %. See docs/BUILDING.md, "Player size budgets".
- Script budgets. `runtime.scriptMemoryMB` (the JavaScript heap cap, default 768 MB as before) is a project setting, a
  number or `{"default": n, "android": n, "web": n, ...}` per platform, range 16 to 2048 with a teaching error; an
  out-of-memory error names the setting and its value. `runtime.scriptFrameBudgetMs` (default 8 ms, 0 turns it off, also
  per platform) adds up the script time of each frame: a frame over it is marked in the profile (`profile.overBudget`)
  and logs a `script.budget` warning naming the three slowest callbacks, once and then at most every 5 seconds of game
  time. Neither changes what the game does. docs/PERFORMANCE.md, "Script budgets".
- **The export checks that a game's scripts call only commands its player has.** A shipped script with a literal
  `fa.call("scene.format")` (a command of the editor, the CLI and MCP that the exported player lacks) now stops
  `factoria export` before it writes anything, with `file:line:column`, the command, why, and the JS way where there is
  one (`mesh.*` is the `mesh` API, `anim.*` clips are played by the Animator, `scene.import_ascii` is
  `scene.place_ascii` at play time). A misspelled name gets "did you mean" against the player's commands; the commands
  of the game's native plugins count as the player's. `factoria validate` reports the same calls as warnings. `factoria
  serve`'s web export and `project.export` with `dryRun` refuse such a script too (they plan the export first). Scripts
  under `tools/` and `tests/`, files `export.exclude` leaves out and names built at run time (`fa.call(name)`) are not
  checked. The editor's Export window keeps the check's result for ten seconds (dropped at once by a save, a project
  reload, an export or a changed `factoria.json`), so its two-second refresh neither walks the project nor reads the
  scripts. `tools/`, `tests/` and `scripts/autoplay.js` are now left out of an export in any capitalization.

### Fixes

- Audio: two memory leaks the weekly fuzz run found. A SoundFont whose `pdta` list repeats a table is refused with an
  error that names the table and its offset (TinySoundFont leaked the first copy). A damaged Ogg Vorbis setup header no
  longer leaks the scratch blocks stb_vorbis holds when it gives up: the engine's Vorbis wrapper frees them. Both inputs
  are in the fuzz corpus and in `fa_test_audio`.
