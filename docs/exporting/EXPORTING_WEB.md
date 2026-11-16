# Exporting a game, page 4 of 6

Part of [Exporting a game](../EXPORTING.md) (the entry page lists every page).

## Web

`factoria export --platform web` writes a game that runs in a browser (WebGL2 and WebAssembly). The player is the engine
compiled with Emscripten (`factoria_player.js` + `factoria_player.wasm`); the game travels in ONE `game.pak`, like a
desktop [release build](EXPORTING_DESKTOP.md#release-build-gamepak) (scripts as bytecode unless `export.scriptBytecode` is false), whether or
not you pass `--release`.

```bash
factoria export --platform web                    # build/export/<slug>-web/ and build/export/<slug>-web.zip
factoria export --platform web --player path/to/web-player-folder
```

```
build/export/
  my-game-web/                 the folder: any web host serves it as it is
    index.html                 the loading page (progress for the wasm and the pack), then the game
    favicon.png                64x64 icon of the browser tab, made from the game's `icon`; only when the game has one
    factoria_player.js         the Emscripten glue
    factoria_player.wasm       the engine
    game.pak                   the whole game
    FACTORIA_NOTICES.txt       the licenses of the engine inside the game ([License notices](EXPORTING_CONTENTS.md#license-notices))
    .factoria-export           marker (see Replacing an earlier export); not in the zip
    AI_CONTENT_DISCLOSURE.md   only for a game with AI-made assets; not in the zip
  my-game-web.zip              the same files with index.html at the root of the zip
```

**Trying it.** A browser does not run `index.html` from a file (it fetches the wasm and the pack), so serve the folder
over http, e.g. `python -m http.server 8080 --directory build/export/my-game-web` and open `http://localhost:8080/`. The
export prints this command as its first next step. `project.serve_web` does it for you ([below](#serving-the-web-build-projectserve_web)),
also for a phone on the same Wi-Fi, and `singleFile` ([below](#one-html-file-singlefile)) writes a page that opens from a double click.

**itch.io.** The zip is what itch.io takes as an HTML5 game: create a project of kind *HTML*, upload `my-game-web.zip`,
tick *This file will be played in the browser* and set the viewport size (itch.io's page for HTML5 games lists the
limits the export checks and warns about: at most 1000 files, 500 MB unpacked, 200 MB for one file, paths of at most
240 characters). Any other web host serves the folder: send `.wasm` as `application/wasm` (almost every host does).
`factoria publish` does not push the web export yet; upload the zip by hand or run
`butler push build/export/my-game-web.zip <user>/<game>:html5`.

**Setting up Emscripten.** Only building the player yourself needs it (a download of FactorIA carries `web/`). The SDK is
pinned to **6.0.10**, the version CI and the releases use (newer ones are likely fine, untested):

```bash
git clone https://github.com/emscripten-core/emsdk && cd emsdk
./emsdk install 6.0.10 && ./emsdk activate 6.0.10     # emsdk.bat on Windows; needs Python 3.10+ (EMSDK_PYTHON names one)
source ./emsdk_env.sh                                  # emsdk_env.bat on Windows: sets EMSDK and puts emcc on PATH
cd <the engine checkout>
cmake --preset web-release && cmake --build --preset web-release   # build/web-release/player/factoria_player.{js,wasm}
```

`factoria setup webplayer` does all of it, fetching the SDK into the checkout's `.cache/emsdk` when it finds none
([A development build](EXPORTING_DESKTOP.md#a-development-build-players-from-the-checkout)). It also needs CMake 3.24+ and Ninja. On a Mac the
system Python is too old for `emsdk`: `brew install python@3.13` and `export EMSDK_PYTHON=$(brew --prefix python@3.13)/bin/python3.13`.

**Where the player comes from.** The export looks, in this order, for a folder holding both `factoria_player.js` and
`factoria_player.wasm`:

1. `--player <folder>` (or the path of `factoria_player.js`; the CLI only. The editor and `project.export` use 2 to 4).
2. `web/` next to the `factoria` binary: every FactorIA download has it, like `mobile/`.
3. The one `factoria setup players --platforms web` installed (`<FactorIA home>/players/<version>/web/`, taken from the
   download of this machine's own OS; a factoria that has `web/` next to it never needs it).
4. A web build of the engine source: `build/web-release/player/` (or `build/web/player/`) in the checkout factoria was
   built from ([BUILDING.md](../design/BUILDING.md), repository only, not in the binary). A build directory elsewhere: pass its `player/` folder with `--player`.

Without `--player` the export looks at 2, then the checkout's build (4), then 3, and takes the first whose build
fingerprint is this factoria's: a fresh `build/web-release` wins over an installed player of an older release. When none
matches it takes the first one it found and stops on the mismatch, as for every player (see "The player must come from the
same build as `factoria`" under Desktop; `--player` is checked too). The error names both builds and says to build the web
player in the checkout (`factoria setup webplayer`), to run `factoria setup players --platforms web` (a release), or to pass
`--allow-player-mismatch`. If a player that lacks something still reaches the browser, the script error names the module and
the missing export and says the player may be older than the game's engine.

With none of them the export stops before writing anything and says which folders it looked in and the command that fixes
it. `--json` and the plan (`dryRun`) report where the player came from as `mode` (`explicit`, `package`, `installed` or
`build`), the `factoria_player.js` used as `player`, and the zip as `artifact` (`format` is `zip`).

**The page.** `index.html` is `platforms/web/shell.html`, embedded in the factoria binary, with `{{title}}` (the game's
`name`, HTML-escaped), `{{wasmBytes}}` and `{{pakBytes}}` (the sizes of the two downloads, for the progress bar when the
server sends no `Content-Length`) and `{{favicon}}` (`favicon.png`, or `data:,` when the game has no icon) replaced. A placeholder this factoria does not know stays as it is, with a warning.

**What differs from the other exports.**

- **Textures** stay PNG (the `auto` compression is `none`, as on desktop): WebGL2 guarantees no compressed format (ASTC
  and ETC2 are mostly phones, BC7 mostly desktops, and a browser tells the page only at run time), so a KTX2 file would be
  decoded to RGBA in the browser anyway. A texture can still ask for `"compression": "uastc"` in its import settings.
  Atlas pages are at most 2048 px, like on phones: browsers run there too.
- **Audio** is not changed by the web: WAV, OGG and QOA all decode in the player. Prefer OGG or QOA for long sounds, since
  every byte is downloaded before the game starts.
- **Audio output** goes through an `AudioWorkletNode` (no `ScriptProcessorNode` deprecation warning in the console). The
  player has no threads and no `SharedArrayBuffer` (a page without COOP/COEP headers), so Emscripten's `AUDIO_WORKLET` is not
  used: the worklet only plays queued sample chunks and asks the main thread for more when its queue falls under 2048 frames;
  the main thread mixes 512-frame chunks and posts them back. Where a browser has no AudioWorklet (or the worklet module fails to
  load) a `ScriptProcessorNode` of 2048 frames takes over, with the old warning. The console says which one runs
  (`factoria audio: AudioWorkletNode, ...`); `FactoriaAudio` in the page's console holds `backend`, `baseLatency`,
  `outputLatency` and `underruns` (a warning is logged when the main thread was too busy to feed the worklet in time).
  **Latency**, measured in the built-in browser (Chromium, macOS, 44.1 kHz, Burrow Brigade at 60 fps): `AudioContext.baseLatency`
  5.4 ms, `outputLatency` 24 ms, plus the 2048-frame queue (46 ms full, about 35 ms on average), so a sound starts about 65 to
  75 ms after the game asks for it, against about 90 ms of buffer alone with the `ScriptProcessorNode` of sokol_audio. 0
  underruns in 18 s of music. Output latency varies with the device (Bluetooth adds more); the queue is the part the engine
  chooses, and it is sized to survive one long frame.
- **Typing.** Typed text reaches the game from the browser's `keypress` events, so it needs a real keyboard (or events a
  browser treats as typed; a browser pane's synthetic key events may only send `keydown`, and then letters do not appear).
  On a phone or tablet, a `TextField` with focus makes the browser show its keyboard through a hidden `<input>`; iOS Safari
  may need a second tap on the field. Details: [TEXT.md](../TEXT.md#typing-text). A gamepad alone types with the on-screen
  keyboard of [MENUS.md](../MENUS.md).
- **The icon** is only the tab's: the export scales the game's `icon` (the top-level one; there is no `export.web` section)
  into `favicon.png`, 64x64, and the page links it. A game without an icon gets an empty icon (`data:,`, so a host without a
  favicon logs no 404), and no "No icon" warning; an icon file that cannot be read is a warning. The `platforms` list of
  `factoria.json` is not checked for `web`.
- **Hiding and closing.** A web export raises `suspend` when the tab is hidden and `resume` when it is shown again
  (`visibilitychange`), `blur` and `focus` with the page's focus, and `quit` when the page goes away (`pagehide`: a closed
  tab, a reload, leaving the site). That `quit` cannot be cancelled. Right after the handlers have run, the save folder
  (`storage`: one file per key) is copied to IndexedDB, so a game that saves in its `suspend` and `quit` handlers keeps the
  save after its tab is closed. The browser can still kill a page before the copy ends, so keep a timer autosave too. To
  check it: export, serve and open the game, make progress, close the tab (or navigate away), open the game again and see
  that the save is there. `storage.setAsync` has no worker thread on the web: its write runs between frames, or right after
  the `suspend` and `quit` handlers, before the copy. Which signals each platform raises: [SCRIPTING.md](../SCRIPTING.md) "Window
  close".
- **Size** is the cost of the web: the wasm player plus the whole pack is downloaded before the first frame. `factoria
  validate` already warns about big files; the zip is deflated, so a host that compresses (gzip, brotli) saves little more.
  See "The size report" below.

**The size report.** Every export names the five folders that weigh most in what ships (`largestFolders` in `--json`: the
folder cut to two levels, such as `assets/audio`, its files and bytes, after the asset steps), and warns when a folder
called `store`, `screenshots` or `src`, at any depth, is packed: it names the folder, its size and the `export.exclude`
entry that leaves it out (a game that does load such a folder keeps it). A web export also lists each file of the zip
with its raw size and about its gzip size (the deflate size the zip holds plus the 18 bytes of a gzip frame; brotli is
not measured), the total, and how long that total takes to download at 1, 5, 20 and 100 Mbit/s (`webFiles`, `webBytes`,
`webGzipBytes` and `webDownloadSeconds` in `--json`). The times assume the host serves the files compressed; without that
the raw total is what travels.

### One HTML file: `singleFile`

`factoria export --platform web --single-file` (the `project.export` argument `singleFile: true`, the **One HTML file**
checkbox of the Export window's Web row) writes ONE page instead of the folder and the zip:

```
build/export/
  my-game-web/
    my-game.html               the page: the player's JavaScript, the wasm, the icon and game.pak, all inside (base64)
    FACTORIA_NOTICES.txt       the licenses of the engine; the same text is inside the page too
    .factoria-export           marker (see Replacing an earlier export)
```

Double click `my-game.html` (or drag it onto a browser, or mail it): it runs offline from `file://`, with no server. The
report's `artifact` is that file (`format` is `html`); there is no zip. Base64 makes every byte a third bigger, so the page is
about 1.4 times the size of the folder, and the browser decodes it before the first frame. It is meant for a small game, a
jam entry, a demo to send to someone.

- **Size limit.** The export refuses a page over `singleFileMaxMb` (`--single-file-max-mb`; default 64, from 1 to 256 MB of
  1048576 bytes; a fraction such as 1.5 is rounded to the nearest byte, below 1 is refused; 256 MB is about the biggest text a browser's JavaScript can hold). The size is worked out from the sizes of the player files and the pack before the page is built (64-bit
  math), so a game that is too big fails at once, with the size, the limit and how to fix it: make the game smaller
  ([ASSETS.md](../ASSETS.md), "Import settings"), raise the limit (browsers get slow with pages over about 100 MB) or export the
  normal web folder and host it.
- **Threads.** A player whose wasm has a shared memory (a threaded build) needs a page served with cross-origin isolation
  headers (COOP/COEP), which a file cannot have. The export reads the wasm's memory declaration and refuses it with that
  explanation. The web player FactorIA ships uses no threads, so this only happens with a player you built yourself with
  threads.
- **Arguments that contradict.** `singleFile` with another platform, and `singleFileMaxMb` without `singleFile`, are errors
  that name the argument (`/singleFile`, `/singleFileMaxMb`).
- **What a file page does not do.** A game that downloads other files at run time (`http` requests, a web font from another
  site) is a game for a server. The saves (IndexedDB) of a page opened from `file://` belong to the address the browser gives
  that file, which browsers treat differently (some share it between all `file://` pages): do not rely on a save surviving a
  move or a rename of the file. Opening the file on a phone works only in some browsers; to test on a phone use
  `project.serve_web`.

### Serving the web build: `project.serve_web`

`project.serve_web` exports the web build and serves it from a small HTTP server inside the process that runs the command:
the editor, `factoria mcp` and `factoria session` keep it until they end or until `{"stop":true}`; a one-shot
`factoria call` ends it when the call returns. Arguments: `lan` (default false), `stop`, `player` and
`allowPlayerMismatch` (like `project.export`).

```bash
factoria call project.serve_web '{"lan":true}'     # from an MCP session or the editor: the server stays up
```

It returns `{running, state, url, lanUrl, urls, port, version, warnings}`.

- **Where.** `127.0.0.1` (this computer only) unless `lan` is true, then every network interface; always a random port, and a
  random 128-bit token in the path: `http://<address>:<port>/<token>/`. Any request without the token, and any request for a
  file that is not in the build, gets the same `404`. With `lan`, `urls` has one address per private IPv4 address of this
  computer (the first is `lanUrl`) and the warnings say so when there is none.
- **What it serves.** The export goes to `<project>/build/serve-web/` (two folders that take turns, so the page that is being
  downloaded is never replaced under it); the folder of a normal export is not touched. A needed web player that is not
  installed fails with the command that gets it (`factoria setup players --platforms web`).
- **Live reload.** While it runs, a change to a script, scene, asset or `factoria.json` exports again once the files stopped
  changing, and every open page reloads (it asks `<token>/__fa/version` once a second). If the new export fails, the last good
  build keeps being served and `state` is `failed` with the error and the fix; the page shows a banner with it.
- **Safe by construction.** `.wasm` is sent as `application/wasm`, the other types by extension. The path is cut at the
  token, decoded once, and refused (404) when what is left has a `.` or `..` segment or a file name starting with a dot, a
  backslash, a control character, a drive colon or an empty segment (so `//etc/passwd`, `%2e%2e`, `%5c` and `%2f..` are all
  refused; a name that is not valid UTF-8 is a 400, and a Windows device name such as `CON`, `NUL`, `COM1` or `LPT1`, with or without an
  extension, is refused on every system), and only a regular file inside the build folder is sent. A request head is at most 8 KB (431), a log body 16 KB (413), 8 connections
  are answered at a time and 32 wait (more are closed), and a connection that sends nothing for 5 seconds is closed. Requests
  are answered on the server's own threads: the editor's UI thread never waits for them. A 400, 413 or 431 answer is followed by a
  short lingering close (the server finishes sending, then reads what is left of the request for up to half a second), so the client
  reads the status instead of a reset connection. The token comes from the operating system's random generator and is compared
  in constant time. In the editor `project.serve_web` never waits either: it answers `state: "starting"` while a helper thread
  starts the server and makes the first export, and the caller repeats the call (same arguments) until `state` is `ready`; a
  start that failed is reported as the error of that call. The CLI, `factoria mcp` and `factoria session` wait for the first
  export.
- **The phone's console.** The served page posts what the game logs (`console.log/warn/error`, uncaught errors) to
  `<token>/__fa/log`; the lines are written to the engine log with category `phone`, so they show in the editor's Console and
  in `game.logs`. At most 600 lines per minute, 1000 bytes each, a line break in a message becomes a space; when a minute ends
  with lines dropped, one warning says how many.
- **Plain http.** The page is not served over https, so a phone's browser may call it "not secure", and features that need a
  secure context are not available there (the game falls back where it can: audio uses the `ScriptProcessorNode` when the
  `AudioWorklet` is missing). Whether a feature works on the phone is for the phone's browser to say; the log line in the
  Console tells.

The editor's File > Play on Phone... window is the front for this command ([EDITOR.md](../EDITOR.md#play-on-phone)).
