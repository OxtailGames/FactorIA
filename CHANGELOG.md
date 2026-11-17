# What's new in FactorIA

The editor shows these notes when it offers an update, and each release on GitHub uses its section. Newest first.

Older versions, one file per minor version with its patch releases: [0.29](changelog/0.29.md), [0.28](changelog/0.28.md), [0.27](changelog/0.27.md), [0.26](changelog/0.26.md), [0.25](changelog/0.25.md), [0.24](changelog/0.24.md), [0.23](changelog/0.23.md), [0.22](changelog/0.22.md), [0.21](changelog/0.21.md), [0.20](changelog/0.20.md), [0.19](changelog/0.19.md), [0.18](changelog/0.18.md), [0.17](changelog/0.17.md), [0.16](changelog/0.16.md), [0.15](changelog/0.15.md), [0.14](changelog/0.14.md), [0.13](changelog/0.13.md), [0.12](changelog/0.12.md), [0.11](changelog/0.11.md), [0.10](changelog/0.10.md), [0.9](changelog/0.9.md), [0.8](changelog/0.8.md), [0.7](changelog/0.7.md), [0.6](changelog/0.6.md), [0.5](changelog/0.5.md), [0.4](changelog/0.4.md), [0.3](changelog/0.3.md), [0.2](changelog/0.2.md), [0.1](changelog/0.1.md).

## Unreleased

### M71 (in progress): linear HDR and a post-processing stack

- **Scene settings:** `SceneSettings.colorSpace` (`gamma`, the default, or `linear`), `hdrOutput` (`off` or `auto`) and
  `paperWhiteNits` (200) are stored and saved with the scene. They change nothing yet: the picture stays in gamma until the linear
  pipeline lands, and an old project keeps its exact look.
- **PostProcess component:** one reflected component for a camera's own post-processing stack or for a volume (shape `global`, `box`,
  `circle` or `sphere`, `size`, `blendDistance`, `priority`, `weight`), with 20 effects (`ssao`, `ssr`, `fog`, `sunShafts`,
  `exposure`, `depthOfField`, `motionBlur`, `radialBlur`, `lensDistortion`, `chromaticAberration`, `bloom`, `tonemap`,
  `colorGrading`, `vignette`, `sharpen`, `outline`, `pixelate`, `posterize`, `filmGrain`, `colorFilter`). All are off by default and
  only the four listed below are drawn yet: the other fields are stored and saved. The renderer resolves the volumes at each camera on the CPU
  (docs/design/ARCHITECTURE_RENDERING.md, "PostProcess").
- **Commands:** `render.supports` says what the renderer can do on this graphics backend and GPU (float targets, R11G11B10, sampled
  depth, compute shaders, linear colour, HDR output and each post effect; false for what is not drawn yet); `postprocess.get`,
  `postprocess.set` and `postprocess.presets` read and write the PostProcess component.
- **Exposure, bloom, tonemap and colour filter are drawn.** The stack of the camera that draws first is now a set of frame-graph
  passes: bloom (with a new soft `bloomKnee`, a `bloomLensDirt` texture and a `bloomThreshold` that may exceed 1), exposure (manual
  `exposureEv`, or `exposureMode` auto: a 32x32 brightness reduction and a 1x1 adaptation on the GPU, deterministic from the frame
  time, no read back, between `exposureMinEv` and `exposureMaxEv`), tonemap (`none`, `neutral`, `aces`, `agx`, `reinhard`) and the
  colour filter, with a final pass that fuses exposure, tonemap, filter and the encode for the display and dithers by one 8-bit step.
  The screen-space HUD is drawn over the final picture in display colours (never exposed or tonemapped; the colour filter still
  covers it). A frame without any stack still declares no pass and makes no render target. `render.supports` answers true for these
  four effects. docs/RENDERING.md ("Post-processing") has the order and the cost of each; AI_GUIDE recipe 9.20 is rewritten to
  PostProcess.
- **Deprecated:** `Camera.bloom`, `bloomThreshold`, `bloomIntensity`, `bloomRadius`, `bloomScreenSpace` and `Camera.colorFilter`
  keep drawing exactly the same picture (they stand in for a PostProcess on a camera that has none), but warn once and will be
  removed two minor versions after the release that ships them. Migration: add a `PostProcess` to the camera's entity and set
  `bloomEnabled`, `bloomThreshold`, `bloomIntensity`, `bloomRadius`, `bloomScreenSpace`, and `colorFilterEnabled` with
  `colorFilterMode`. A camera with a `PostProcess` of its own ignores the old fields.

## 0.30.1

FactorIA 0.30.1 polishes WebSocket closing and fixes a once-only editor notice that could repeat. Every WebSocket client
now says when the server never answered a close, the Windows client finishes the closing handshake while the server is
still sending, and the notice that `.mcp.json` changed is given once even when the file's time is read twice.

### Fixes

- **WebSocket, a close the server never answers:** after 5 seconds every client ends with an `"error"` that says the
  server did not answer the close, then `"close"` 1006. Linux (libcurl), the tcp client and Android said "the connection
  was lost" before, like a network failure. docs/NETWORKING.md.
- **WebSocket on Windows:** a game that closes (or is destroyed) while the server keeps sending now reads and discards
  what arrives until the server's close frame or the 5 second wait, so the server reads the close frame instead of a
  reset. Destroying a connection that is already closing never makes the close wait longer.
- **WebSocket on macOS and iOS:** a connection failure reported while the connection was waiting for the network is no
  longer missed when the system moves on before the engine looks; the error kept is the first one. Large sends no
  longer copy the rest of the buffer after every chunk. The docs say that the system proxy settings are
  Network.framework's to apply.
- **MCP:** the notice that `.mcp.json` changed after the AI client started could be given twice: the same file time
  was read as two different milliseconds. `file_mtime_ms` now gives the same value every time, and the MCP update tests
  no longer depend on timing.
- **Docs:** the 0.30.0 notes are wrapped at 120 columns, and two sentences about editor undo that had landed in a
  WebSocket entry are back in the undo entry.

## 0.30.0

FactorIA 0.30.0 (M98) adds what games expect from an engine and FactorIA lacked. Saves can be encrypted, with versioned
slots. `websocket.connect` reaches real servers on every platform. `"render": { "interpolation": true }` draws between
fixed steps. Pads rumble, and Windows reads DualShock 4, DualSense, Switch Pro and generic HID pads. A `TextField`
composes with the system's input method (Japanese, Chinese, Korean) on every platform, and UI layout and hit tests
follow rotation and scale. 3D audio gains a rolloff curve, doppler, occlusion and HRTF for headphones. An Android game
ends before its process. The editor selects several entities, copies, cuts and pastes them, shows and applies prefab
overrides, and its undo runs through commands. Deprecated names warn once and name their replacement. M97.3 to M97.5
split the docs into pages an AI reads cheaply, test the names, code, links and citations in them, and publish the
example games with each release, to get from the start window or `project.create {example}`.

### Added and changed

- **Docs tests (M97.4):** a doctest (`docs_names_test.cpp`) reads every command, component and `Component.field` the
  docs name in backticks and checks it against the engine's registries, and checks the few sizes a doc states (the MCP
  result and description caps, the 60 KB page budget) against the constants that set them; the docs it found wrong now
  say `scene.spawn` (not `scene.add_entity`). `docs.list` gives the menu kit the path `templates/menus/` and the sum of
  its bytes (it was `""` and 0) and the MCP server lists it as the resource `factoria://docs/menu-kit`; `docs.read`
  refuses a menu-kit file that holds NUL bytes (it is binary). The page lists of the split docs share one `## Pages`
  heading, the four sound pages have summaries that say what each answers, and `docs.write_reference` writes the tools
  table of the AI guide to `<out>/ai-guide/AI_GUIDE_TOOLS.md` (before the split: `<out>/AI_GUIDE.md`). Links, citations
  and reachability are tested too. Every relative link and anchor resolves (the anchors now follow GitHub's rules for
  accents and other scripts, and `<a id>` counts); every citation `X.md, "Section"` in the docs, the source comments,
  the error texts and the scripts names a section that exists (60 pointed at renamed or missing ones and were
  corrected); every doc is reachable from README.md; an embedded doc that names a doc outside the binary says so; and no
  heading repeats inside a doc (five did: renamed). A translation records the English text it follows with a hash on its
  first line, and a test flags one whose English original changed (for README.md only, the number of its line that
  starts with "Version x.y" is left out of the hash, so a version bump does not make README.es.md stale;
  docs/design/ARCHITECTURE.md, "Testing"). The js blocks too: every ```` ```js ```` block of `docs/` (the design docs
  too) is parsed with the engine's QuickJS and its `root.member` names (`world.`, `ui.`, `tween.`, `Vec2.`...) are
  checked against the generated script typings (`tools/common/tests/docs_js_test.cpp`); a failure names the file and
  line and suggests the closest name. A block that is only a piece of a script (a class method, a `return` outside a
  function) opens with ```` ```js fragment ```` and is not parsed. The docs the test flagged are corrected. A block that
  shows a wrong name on purpose opens with ```` ```js names-skip ```` (parsed, names not checked). The names test checks
  a dotted name only when the text says it is a command (a tool, `factoria call`, arguments in braces) or when it is one
  edit from a real one, so a settings key or an event name is left alone; a closing code fence may carry trailing
  spaces. A citation `X.md, "Title": text` is checked (the colon no longer hides it), and `[x](y.md "Title")` is a link,
  not a citation.

- **Example games, last polish (M98):** `project.create {example}` into an existing empty folder never replaces a file
  or folder that another process puts there meanwhile (the moves use a no-replace rename on Linux, macOS and Windows;
  before, a plain rename could overwrite it) and stops with "is not empty any more"; when a move fails and something it
  had put in the folder cannot be taken out again (a file open elsewhere), the error names it instead of saying the
  folder was left empty; a copy across file systems checks Windows' "not the same device" error by its raw value too. A
  doctest checks every example of `examples/` (the files the packer lists, their names, that each can be read, and the
  limits of the zip; two small examples are packed whole), so a file the packer refuses shows in the pull request that
  adds it and not in the release run (the release workflow still starts only for a change of itself,
  `examples/examples.json` or the packer). A cancel while a new folder's move waits for a sharing violation says
  "cancelled", not a move error.
- **Last polish (M98):** `Audio::close_device()` now runs the commands still waiting for the device before it returns,
  so a later command cannot overtake an older one (only `shutdown()` is expected after it). Android: the answer of a
  slot whose pad is gone is kept until the stop of a rumble that was playing has reached the vibrator, also when the
  slot is asked again first. Linux: a node that vanished says "plug the pad in again" as a pad with no node does. Web:
  the pad list of the rumble functions is refreshed by one shared helper. Web: the hidden input of a phone keyboard with
  no IME has `autocomplete="off"` (Safari no longer offers "Use strong password" over the game). Android: with a burst
  of input filling the IME queue the Back button is still delivered. A scene or component patch (`scene.set_component`,
  a script's `entity.add` / `entity.set`) that fails on one field still logs the deprecation warning of another field it
  had taken (it was lost); the warning line of a patch shows its location and hint as a script spawn's does. Tests and
  docs only: the long hex vectors of the crypto tests wrapped at 64 digits, the camera-under-a-blended-parent and
  Parallax bounds cases of the interpolation tests, `close_device` without a device, the rewrapped IME paragraphs of
  TEXT.md and the interpolation paragraphs of PERFORMANCE_AREAS.md.
- **Android end and build, polish (M98):** in a `game.on("quit")` handler on Android the code after
  `await storage.setAsync(...)` now runs (the end delivers each finished write, runs what it wakes, up to 16 writes in a
  row); before, only the write itself was waited for. The end closes only the audio device (it no longer waits for the
  music's decodes or releases the clips). The docs say what a handler cannot do there (load a scene or an asset, draw,
  cancel, wait for a timer or a download) and that the `cancel()` and `game.quit()` of the documented example do nothing
  on the web and Android. The Android NDK r27 build with `-Werror` stops no more in `engine/core/src/json.cpp` (a
  deprecated nlohmann comparison). The script watchdog tests no longer fail on a loaded machine: a busy loop that gets
  less than 1/8 of a core was cut by the clock cap (another message, so a second error); the tests turn that cap off
  (`ScriptSystem::set_wall_cap_factor`) and one test still checks the cap.
- **IME and text field polish (M98):** a UI that holds the input method and stops updating (the editor's own panels with
  a focused `TextField` while a game runs) gives it up: after 30 updates of another UI without one of its own, the other
  takes it. macOS: text the system inserts with no key behind it (the emoji picker, dictation) is typed as `input.text`
  also while no field has the focus or the IME is off; before it was dropped (iOS did not drop it: its keyboard's
  characters go through sokol_app's own text field). The editor's `ui.reset_layout_positions {dryRun: true}` is no
  longer an undo step or a scene save. Documented limits: the editor's Play view has no input method (the editor window
  has no `AppDesc::input`), and an input method that commits and inserts a newline on one Enter has that Enter swallowed
  (docs/TEXT.md).
- **Editor polish (M98):** pasting a copied entity whose `$prefab` path has a segment of only dots and spaces (`.. `,
  `...`) is refused, as `..` is (Windows ignores trailing dots and spaces); the Inspector's "Undo put the scene back"
  note no longer appears after a scene load or when the undo list was trimmed; in a number that differs between selected
  entities, leaving the box after typing (Tab, a click outside) writes the typed value to all of them, as Enter does.
- **Pad rumble, last polish:** the same-frame pause cut also runs after `onLateUpdate`, so a pause in `onUpdate` with
  the rumble in `onLateUpdate` (or the other way round) never buzzes for one frame either. Android: the answer of a slot
  whose pad went is dropped (after the stop of a rumble that was playing has reached the vibrator). Linux: a pad with no
  event device in sysfs (or whose node vanished) is looked for ten times, about 30 s, and then keeps its reason until it
  is plugged in again.
- **Audio, last polish:** a sound's low-pass that is asked to open twice before the mixer ran a block is taken away
  (before it stayed in the mixer at no effect until the voice ended). Doppler and occlusion changes no longer restart
  the 20 ms ramp of a voice's volume or occlusion gain when their target did not change. The rays of a frame that the
  plan gave to sounds already known are kept for them (sounds that start in that frame take only what is left, and a ray
  whose sound stopped wanting it in that frame goes to another sound that is due). A source or a sound played at a place
  that is not a number (NaN) is silent, not a NaN volume, pan or pitch in the mixer. The warning about the 256-sound
  limit of followed sounds is given again after a world change.
- **Pad rumble, polish:** the seconds of a rumble count the frames' own duration (not scaled by `time.scale`; the docs
  said "game time"); a rumble asked in the same frame that pauses the game (`game.paused = true`, `time.scale` 0) never
  reaches the pad, where before it buzzed for one frame. `input.stopRumble(-1)` now throws like any pad outside 0..3
  (without an argument it still stops every pad). A request with both strengths 0 is a stop (`game.rumbles()` records
  seconds 0), and the command `game.rumble` refuses `seconds` without `low` or `high`. `input.gamepad(i).canRumble` is
  right in the frame a pad connects and in its `gamepadConnected` handler, and a test pad forgets it when it disconnects
  (say `canRumble: true` at each `connect()`). Linux: an `EVIOCSFF` failure other than "unknown effect" no longer leaks
  the old effect, interrupted `ioctl`s are restarted, and a pad whose event node was not writable yet (udev) is asked
  again every few seconds. Android: a slot's answer is dropped when its pad goes (a reused device id is asked again), a
  failed JNI lookup is logged once and its references are released. macOS and iOS: CoreHaptics errors are logged, an
  engine that started when its twin failed is stopped, and engines shut down by themselves when idle. Web:
  `getGamepads()` is asked once per frame, and a pad answers `canRumble: false` with the reason while the page has had
  no user activation, so the rumble still running starts once the player clicked the page or pressed a key (a button of
  the pad may not count), and the pad list is asked again by the rumble hooks when the page has no focus. An infinite
  `seconds` in the platform helpers no longer converts to an integer undefined-ly. The docs now say that the editor's
  Game view reads no physical pad, and what a crash, `abort()` or a Switch Pro do to the motors.
- **UI polish (M98.6 follow-ups):** the input method is one per process: the first UI whose focused `TextField` wants
  it keeps it until that field loses the focus, the UI is reset or destroyed, and a field of a second UI (the editor's
  own panels next to Play, a test) is typed as a plain field meanwhile. On a web page opened on a Mac, Alt (not Ctrl)
  moves and deletes by word, like the native macOS build. A turned or scaled screen-space Text, Sprite or Shape2D
  under a widget now stays rigid with it under `ui.mirrorRtl` too, and is placed from the Transform and the pose, not
  from the inverse of its parent's matrix (a parent that scales to 0 no longer makes it vanish).
  `ui.reset_layout_positions` takes `dryRun` (list what it would reset) and says in its description that it is a guess
  (an intended nudge equal to the slot offset is reset, a ScrollList scrolled since the load can hide a baked
  position); `scene.set_parent` says `positionReset: true` when it sent the child to a layout slot. `TouchStick` and
  `TouchButton` still ignore the rotation of their parents (documented). Two `ui.change` can arrive in one frame (a
  commit and typed text): the last value is the current text.
- **WebSocket on Linux (libcurl), Windows and the tcp client, polish:** when a game does not read its messages and the
  engine ends the connection (`"close"` 1008), `readyState` is `"closed"` as soon as that `"close"` event can be read,
  as it already was for every other end (before, a read right then could still say `"open"` for a moment). On Windows, a
  close frame from the server whose status Windows cannot read is answered with an empty close frame instead of dropping
  the connection.
- **Examples are optional in the docs (M97.5d):** every example's README opens with what the game shows and which docs
  to read first; the docs you get with the download keep each recipe in the doc and name an example only as something
  you may have fetched with `project.create {example}`, and a test fails an embedded doc that cites `examples/<name>`
  without saying so.
- **Examples tab in the start window (M97.5c):** the Open or create a project window has an Examples tab that lists the
  example games of your version (what each shows, its size, whether it is downloaded, the docs to read first) and
  creates a project from one in a folder you choose, with progress and Cancel; the list is read from a saved copy at
  once and refreshed in the background, and a stale list or an offline first run says why and offers Retry. It replaces
  the scan of `~/FactorIA/examples`, a folder the download never had.
- **Example games you can get with a command (M97.5b):** `project.examples` lists the example games of the version you
  have installed (name, title, what each shows, what to read first, download size) and `project.create {example, dir}`
  makes a project from one: it downloads the example's zip from that version's GitHub release, checks its size and
  SHA-256 against the release's list before opening it, refuses any file name that could write outside `dir` (`..`,
  absolute paths, drive letters, `\`, names that differ only in capitals), unpacks it into a hidden folder and renames
  that folder to `dir` at the end, so a failure leaves nothing behind (`dir` must be new or empty). Both keep what they
  download in FactorIA's cache folder (`~/.factoria/cache/examples/<version>`): with no internet the list comes from
  there marked `stale`, and without a copy the error says the base download carries no examples and that you need the
  internet once. A wrong name gets "did you mean". Both need the `network` capability, so an MCP game AI calls them like
  `project.create` today. The release packer also leaves out secrets (`.env`, `ai.local.json`, `*.key`, `*.keystore`,
  `*.jks`, `*.p12`, `*.pem`), `desktop.ini` and `*.fa-tmp`, and a folder it cannot read now fails with its name.
- **3D audio polish (M98.8):** what a game hears changes a little. The volume and the low-pass of a voice (occlusion,
  distance) now ramp in the mixer over about 20 ms and 5 ms instead of stepping at each frame, so a moving or occluded
  sound has no zipper noise. With more sources that ask for occlusion than the 8 rays a frame, the ones never measured
  go first and then the one asked longest ago (none waits for good). Switching an `AudioListener` between `pan` and
  `hrtf` crossfades over 4 ms, and a sound that starts under the head model has its delay line filled. A NaN or infinite
  position, `headRadius` or `speedOfSound` can no longer poison the head model (the warning for a head out of range is
  given once). A 5.1 or 7.1 output keeps the pan, as a mono one does. A listener with many colliders in its hierarchy no
  longer hides a wall from the occlusion ray, and a source that is switched off forgets its doppler and occlusion state.
  A game that logs the 256-sound limit of followed `audio.play` sounds sees one warning.
- **Example games in the release, first part (M97.5a):** every release will publish each example game (`block-push`,
  `lantern-keep`, `kindlewatch`, ...) as its own zip, plus `examples-manifest.json` with each example's title, what it
  shows, the docs to read first, and the size and SHA-256 of its zip. The new command `project.package_examples` makes
  them from the repository's `examples/` (the same files give the same zip), and the engine can now read the manifest,
  build the download address of a release's file from the installed version and check a download against its hash.
  Getting an example from the editor comes in the next parts.
- **Editor undo as commands, second half (M98.7e2):** creating, deleting, duplicating, cutting, pasting and reparenting
  entities (and a bone chain) now store the command and its inverse instead of a copy of the scene, and so do the
  Console and the AI panel when their command has an inverse. Undo of a delete pastes the entity back with its subtree
  under the same ids, parent and sibling index, its outside references and, for a prefab instance, its link and
  overrides; Redo of a create gives the same ids; Undo of a reparent restores the exact old Transform (a widget nudged
  inside a layout Panel returns with its nudge). Each editor action is still one step. Deleting a top-level entity that
  is not the last one still takes a snapshot, so the order of the top-level entities (the file's order, and the
  tie-break of drawing order) is kept exactly; deleting the last one or a child is a command step. `scene.import_ascii`,
  `scene.ascii_edit`, `script.eval`, `prefab.revert`/`apply`, `skin.*` and the AI revert still take a snapshot, and so
  does an edit whose subtree is deeper than 64 levels (a paste would refuse it). A reparent that changes nothing (to the
  place the entity already has) records no step. docs/EDITOR.md, "Undo entries".
- **WebSocket on macOS and iOS, polish:** a redirect answer to the upgrade is not followed (it ends the attempt with an
  `"error"` whose `httpStatus` is the redirect's, as the hint always said), a TLS handshake failure (`wss://` to a port
  that does not speak TLS) says so, a close the system reports as 1006 or 1015 is a failure (`"error"`, then
  `"close"` 1006) and not a clean close, and a game destroyed while its close handshake runs still sends its close
  frame. The docs now say which clients send keep-alive pings (only Windows). On Linux, the memory of a large `send`
  burst is given back after it.
- **Editor undo as commands, first half (M98.7e1):** an edit of a field or a component (Inspector fields, rename, the
  active box, Transform gizmo drags, adding and removing a component) no longer stores a copy of the whole scene on the
  undo stack: it stores the command and its inverse, built from the scene before the edit, so 100 edits cost less than
  one snapshot of a big scene. Undo and Redo run those commands, a drag is still one step, and a step that fails midway
  puts the scene back and says which command failed. The other edits (entities created, deleted, reparented, pasted; the
  Console and the AI; bone tools) still take a snapshot until the second half. docs/EDITOR.md, "Undo entries".
- **Prefab overrides (M98.7d):** three new commands, `prefab.overrides` (what an instance differs in from its prefab
  file, one entry per field, added component and added child, with the prefab's own value, and what cannot be written as
  an override and why), `prefab.revert` (a field, a component or the whole instance back to the prefab; one Undo step in
  the editor) and `prefab.apply` (the instance's value written into the prefab file, which keeps its layout and nested
  prefabs; the other instances of it in the open scene follow, keeping what they override themselves). The Inspector
  marks overridden fields (blue label, tooltip with the prefab's value) and added components, shows the prefab and the
  override count under the name, and offers Revert to prefab / Apply to prefab in the right-click menu of a field and of
  a component header, and Revert all / Apply all (which asks first, and is greyed out while the game plays) for the
  entity (docs/EDITOR.md, "Prefab instances"). A component an instance removed is listed (`removedComponent`), comes
  back with Revert and is deleted from the prefab file by Apply; `name`, `tags` and `active` of EntityInfo can be named
  as fields; Revert is all or nothing; instances are matched by the normalized path of their prefab (case on Windows and
  macOS). A removed prefab child is still not listed.
- **Android: the game ends before its process (M98.4):** when the system destroys the activity (a Back no `input.onBack`
  handler consumed, `game.quit()`, the system closing the app, a relaunch for a theme or wallpaper-colour change), the
  `game.on("quit")` handlers now run (once, not after `game.quit()`, and they cannot cancel), the analytics request for
  the events that wait is started (not waited for), the `storage.setAsync` writes still waiting reach the disk, the pads
  stop and the audio device closes, all on the game's thread while Android's main thread waits at most about 1.5 s; then
  the process ends at once as before. Fixed on the way: on Android `game.quit()` and a Back nobody consumed did nothing
  (sokol_app ignores a quit request there); they now finish the activity, and so does a game that cannot start. A
  force-stop or a kill for memory still delivers no callback. The emulator smoke test checks the end on the relaunch and
  on a second Back (docs/mobile/MOBILE_ANDROID.md, "Lifecycle").

- **Copy, cut and paste of entities (M98.7c):** the new commands `scene.copy_entities` (entities with their subtrees as
  one self-contained JSON text: components, children, links to prefabs) and `scene.paste_entities` (creates them under
  an optional parent or each under the parent it had, with free ids, `nameSuffix`, and the new ids in the answer) make
  the clipboard scriptable, across scenes and projects. An Entity field that names an entity of the copied set names the
  copy; one that names an entity outside it is kept when the target exists in the destination and cleared otherwise
  (listed in `cleared`). A text that is not a copy (not JSON, another format or version) gives an error with the JSON
  pointer and the fix. In the editor, Ctrl/Cmd+C, X and V in the Hierarchy and the Viewport (and Edit > Copy, Cut,
  Paste, Duplicate, and the row menu) use the system clipboard; Paste goes next to the primary and selects the copies
  with the copy of the primary last; Cut and Paste are one Undo step each. Duplicate now goes through the same code, so
  references inside the duplicated set follow the copies (before, they were not remapped), and the copies keep their
  prefab links: an instance is copied inline, with a `$prefab` mark that names its prefab file (a mark that leaves the
  project is refused). A duplicate takes the next free number of its id (`coin_3` becomes `coin_4`; before it got an
  engine id such as `e12`). On macOS the system menu shows no key for Copy, Cut and Paste (it would take Cmd+C from the
  other panels).
- **Windows gamepads beyond XInput (M98.5b1):** DualShock 4, DualSense, Switch Pro and generic USB/Bluetooth pads are
  read on Windows through Raw Input and HID (`hid.dll`, loaded at run time), next to XInput for Xbox pads. Each report
  is parsed through the pad's own descriptor (buttons, axes scaled by their logical range, the hat) in DirectInput's
  numbering, so the Windows lines of SDL GameControllerDB, now embedded in the Windows build only, map them;
  `SDL_GAMECONTROLLERCONFIG` and the project's `gamecontrollerdb.txt` come first, and a pad nothing lists gets a default
  layout read from the pad. XInput and HID pads share the slots 0..3: a pad keeps its slot while connected, and a pad
  that appears takes the slot it had last time when that is free, else the lowest free one, so an Xbox pad no longer
  takes its XInput user index. A remapper that shows a PlayStation or Switch pad as a virtual Xbox pad (DS4Windows,
  Steam Input) makes two pads, the virtual and the physical one: turn it off for the game or have it hide the physical
  pad. Plugging comes from the OS's device notifications, and XInput's empty slots are asked every 2 s, and every 250 ms
  for 1.5 s after a device notification, instead of on a fixed timer only (a time schedule, the same at any frame rate).
  Their rumble came with M98.5b2 (below). Not yet tried with a physical pad.
- **A UI layout that does not write `Transform.position` (M98.6f), a behaviour change:** a Panel or ScrollList used to
  move its children by adding the layout's delta into `Transform.position` every frame (so a saved scene held the
  layout's result). It now keeps the placement apart (`World::ui_layout_offset`, not saved, not in an undo snapshot) and
  the child's `position` is its own offset from the slot, 0 = exactly in it. A game whose script reads `entity.position`
  of a laid-out widget now gets that offset (read `entity.worldPosition`, or `ui.rectOf`, for where it is) and a script
  that sets `position` on one nudges it from the slot instead of being overwritten. Drawing, hit tests, drag, bounds and
  the editor viewport see the placed result; the Inspector shows the offset and a viewport drag edits it. A scene saved
  before has the placement baked into those positions: the engine warns once per widget and the new command
  `ui.reset_layout_positions` sets them to 0 (no example scene needed it). A widget moved into a laid-out Panel or
  ScrollList with `scene.set_parent` (keepWorld) goes to its slot, position 0, as before; reordering under the same
  parent changes only the order. 6e's turned-parent drawing now applies only under a turned or scaled widget, so a plain
  scaled group of HUD visuals keeps its old placement (docs/menus/MENUS_RECIPES.md, "Where a laid-out child is").
- **Windows rumble and full reports for PlayStation and Switch pads (M98.5b2):** the DualShock 4, DualSense (and Edge)
  and Switch Pro, over USB or Bluetooth, now rumble on Windows (`canRumble: true`): the engine's own drivers send each
  pad's output report through its HID device (non-blocking, one write in flight per pad, the latest request wins), with
  the Switch Pro's handshake and HD rumble. The drivers also switch each pad to its full input report, so a Bluetooth
  DualShock 4 or DualSense reports its analog triggers and a Switch Pro its full sticks (its ZL and ZR stay digital). A
  Bluetooth DualShock 4 or DualSense stays on that full report until it is switched off or reconnected; a Switch Pro is
  put back on its simple report at exit (over USB that last step is not verified on a real pad). A Bluetooth PlayStation
  report whose CRC is wrong is dropped. A pad another program holds exclusively, or that stops taking reports (a write
  that fails is tried five times in all, 100 ms apart, unless the device is gone), answers `canRumble: false` with a
  reason saying what to do; so does a generic HID pad ("this pad gives no rumble the engine can drive"). A pad that
  vanishes mid-write leaks nothing. The motors stop when the game quits: at exit the process waits at most about 100 ms
  for every pad's last write, then sends the stop. An unhandled exception (an access violation...) zeroes the XInput
  motors (a filter chained to the crash reporter); the HID pads are not touched then, so a PlayStation pad keeps shaking
  and a Switch Pro stops by itself about 50 ms later. `abort()`, a bad CRT call, a hang and a killed process leave the
  motors on. `hid.dll` and `xinput1_4.dll` load from System32 only, and a pad whose details Windows cannot give yet at
  its arrival is retried (warned once). Not yet tried with a physical pad.
- **Several entities selected (M98.7b):** in the editor, Ctrl/Cmd+click toggles and Shift+click selects a range in the
  Hierarchy, and Ctrl/Cmd+click, Shift+click and a marquee on empty space select in the Viewport. Every selected entity
  is outlined; the gizmo moves, rotates and scales all of them about the primary as one Undo step; Delete, Duplicate and
  drag-to-reparent act on the whole selection; the Inspector shows the components all of them share ("—" where values
  differ) and an edit writes to all of them as one Undo step. The AI context lists the other selected ids.
- **Encrypted saves and slot versions (M98.1):** `storage.set(key, value, {encrypt: true})` (and `setAsync`, with or
  without `compress`) seals the key's file with ChaCha20-Poly1305 under a key derived from a per-project secret
  (`factoria.json` `storage.encryptionSecret`, created once with the new command `project.create_storage_secret`; a
  project without it gets a teaching error, and `project.info` / `game.project` show the secret as `"(hidden)"`).
  `storage.get` opens a sealed value transparently; one that fails authentication is kept aside like a damaged file
  (`storage.corrupt`). It is tamper-evidence, not secrecy: the secret ships with the game
  (docs/scripting/SCRIPTING_UI_SCENES.md, "Encrypted saves"). A plain file is still read by default (a game can turn
  encryption on later), so a player could replace a sealed file with a hand-written one:
  `storage.get(key, fallback, {encrypted: true})` refuses it (kept aside, `storage.corrupt`), and
  `storage.isEncrypted(key)` tells which values are sealed. The secret is shown as `"(hidden)"` by `fs.read` /
  `fs.search` of `factoria.json` (and of a checkpoint's copies), `checkpoint.read` (which refuses `out` for that file),
  the MCP resource and the AI prompt, so those channels do not hand it to a model; it is masking per channel, not a
  guarantee (the secret is in the repository). `storage.list` reports `encrypted` per key. The Slots kit writes a
  `version` in every record (option `version`), calls `upgrade(data, fromVersion)` with it (bare saves and old records
  are version 0), refuses a record from a newer version, and has an `encrypt` option and a `requireEncrypted` one (a
  slot that is not sealed is damaged); its tests and the CLI fixture copies are updated.

- **Pad rumble, the shared part (M98.5a):** `input.rumble(pad, low, high, seconds)`, `input.stopRumble(pad?)` and
  `input.gamepad(i).canRumble` shake the motors of a pad (low and high frequency, 0..1, up to 10 s, on the game's
  clock). The engine stops every pad on pause, focus loss, unplug, scene change and quit. A platform or pad that cannot
  rumble answers `canRumble: false` with the reason (the platforms that can are listed in
  docs/scripting/SCRIPTING_WORLD_INPUT.md, "Pad rumble"). Tests record the requests (`game.rumbles()`,
  `game.rumbleState(pad)`, `connect({ canRumble: true })`) and the command `game.rumble` drives a running game. See
  docs/scripting/SCRIPTING_WORLD_INPUT.md, "Pad rumble".
- **HRTF for headphones (M98.8c):** `AudioListener.spatialization: "hrtf"` places spatial sounds with a parametric head
  model written for the engine (the structure of Brown and Duda, 1998, with Woodworth's time difference; no measured
  data, no library): the interaural time difference follows the angle and `headRadius` (about 0.66 ms at 90 degrees for
  0.0875), the far ear is a little quieter and loses the high frequencies to the head's shadow, and a sound in front and
  its mirror behind have the same time. Everything is interpolated per sample, so a moving source makes no click, and
  the mixer stays lock-free and allocation-free. A stereo clip is mixed to mono first. A 2D camera as the listener and a
  mono output keep `"pan"`, which is bit-for-bit what it was. A `headRadius` outside 0.03 to 0.12 m (at
  `speedOfSound` 343) is clamped with a warning. See docs/SOUND.md, "Headphones".

- **UI layout and hit tests follow rotation and scale (M98.6):** a widget whose Transform (or a parent's) has
  `rotation.z` or a `scale` other than 1 is hovered, clicked, dragged onto, wheel-scrolled, tooltipped, navigated to and
  (TextField) clicked into the turned rectangle it is drawn as, not an axis-aligned one: the renderer draws widgets
  turned and scaled around their pivot too. A child's scale multiplies the room its slot takes in a Panel row, column or
  grid (a `fit` panel grows with it); its rotation keeps the slot. `ui.rectOf` and `ui_rect` report the bounding box;
  new `ui_quad`, `ui_transform`, `ui_contains`, `ui_local_point`, `ui_footprint_rect` and `ui_own_rect` in `ui_rect.h`.
  A turned ScrollList still clips to the bounding box of its turned rectangle (a scissor cannot turn) and warns once.
  Unturned, unscaled UI is bit for bit the same.
- **Pad rumble on Linux, Android and Apple (M98.5c):** `input.rumble` now drives the motors on Linux (evdev force
  feedback: one `FF_RUMBLE` effect per pad on `/dev/input/eventN`, which must be writable: the reason names the `input`
  group and the udev rule when it is not), on Android (the pad's `InputDevice` vibrators: `getVibratorManager()` on API
  31+, `getVibrator()` before; two vibrators get low and high apart, one the stronger of the two) and on macOS and iOS
  (GameController haptics with CoreHaptics: low on the left handle, high on the right). The numbers each API wants are
  pure, unit-tested helpers (`fa/platform/gamepad_rumble_map.h`); the three backends are untested on hardware. The AI
  guide's feedback example no longer uses "No gamepad rumble".

- **Render interpolation (M98.3):** `"render": { "interpolation": true }` in `factoria.json` (default `false`, so
  nothing changes for a game that does not ask) draws entities at the pose between the last two fixed steps, so a 60 Hz
  simulation looks smooth at 120-144 Hz. Only the drawing is blended (position, scale, rotation by slerp; children,
  cameras and physics bodies included): Transform, physics and scripts see the real pose. The new `Interpolation`
  component sets it per entity (`on` / `off` / `inherit`), a new entity, a Transform written outside the fixed step and
  `entity.teleport()` are drawn without smearing, and `render.interpolationSnapDistance` treats a long step as a jump.
  `game.step`, headless runs, replays and a paused game draw the real pose. Scripts, UI hit tests and picking read the
  real camera pose, so `screenToWorld` does not depend on the frame time; a rotation that turns more than 180 degrees in
  one step is not blended. See docs/RENDERING.md, "Render interpolation". Polish: `Parallax.offset` and
  `entity.bounds()` of a parallax layer follow the camera's real pose (the drawing still follows the blended one), so
  they no longer change with the frame time; with `render.interpolation` off and `Interpolation` components on a few
  entities, the passes read only those entities instead of every Transform; the docs now say that lights, particle
  emitters and sounds are placed from the real pose, so a sprite can lag its light or emitter by one fixed step.
- **Encrypted saves, polish (M98.1):** `fs.read`, `fs.search`, `fs.write`, `fs.edit` and `checkpoint.read` now hide
  `storage.encryptionSecret` in any file named `factoria.json` (before, only the one at the project root), and `fs.edit`
  matches its `find` against the text `fs.read` shows, so it cannot be used to guess the secret one prefix at a time. An
  `fs.edit` whose `find` copies the `"(hidden)"` line now matches (it used to say "not found"); an edit that leaves
  `"(hidden)"` as the value still keeps the real secret. `checkpoint.read` of a `factoria.json` over 256 KB no longer
  suggests `out`, which is refused for that file. `seal_blob(key, aad, {})` compiles (it was ambiguous between the byte
  and the text overload), and the Windows error of `random_bytes` prints its status in hex; on Android `random_bytes`
  uses `arc4random_buf`. The docs say that `storage.get(.., {encrypted: true})` keeps a plain file aside in the frame,
  that a write that cannot replace its file (open in another program on Windows) leaves the old file (`storage.set` logs
  a warning and keeps the value in memory, `storage.setAsync` rejects), and that `project.create_storage_secret` writes
  `factoria.json` in the engine's layout.
- `fa/core/crypto.h`: authenticated encryption for save files, written in the engine with no new dependency: SHA-256 as
  raw bytes, HMAC-SHA256, HKDF-SHA256, ChaCha20-Poly1305 (RFC 8439, checked against the RFC vectors), `seal_blob` /
  `open_blob` (a file format with a random salt and nonce per seal; a changed byte, a wrong key or a wrong slot name
  fails with "the data was changed or the key is wrong" and no data), a constant-time compare, `secure_zero`, and
  `random_bytes` from the system's random source on every platform. The save slots (M98.1b) use it; it keeps casual
  edits out, it is not copy protection.
- 3D audio, the shared part (M98.8a): `AudioSource.rolloff` has a fourth value, `"curve"`, with `rolloffCurve` (the gain
  over distance / range, the curve form of particles); a sound cone (`coneInnerAngle`, `coneOuterAngle`,
  `coneOuterGain`, `coneAxis`) makes a source louder in front, in 2D and 3D; `audio.play({ position })` takes the same
  (`rolloffCurve`, `direction` and the cone angles). The fields the next two packages need are in and documented as not
  working yet: `AudioSource.dopplerLevel` and occlusion (`occlusion`, `occlusionMask`, `occlusionGain`,
  `occlusionLowpass`), `AudioListener.speedOfSound`, `spatialization` (`pan` | `hrtf`) and `headRadius`, and `velocity`,
  `dopplerLevel` and the occlusion options of `audio.play` (M98.8b doppler and occlusion by physics rays, M98.8c HRTF,
  now done). With the defaults a sound is bit-for-bit what it was.
- 3D audio, doppler and occlusion (M98.8b): `AudioSource.dopplerLevel` shifts the pitch with the speed a source and the
  listener approach or separate at (`AudioListener.speedOfSound`; velocities from the change of world position between
  frames, a jump of more than 4 speeds of sound per second counts as a teleport and shifts nothing; the factor is
  clamped to 0.25..4 and glides over about 0.05 s), and `AudioSource.occlusion` casts a physics ray (2D and 3D colliders
  of `occlusionMask`, triggers and the source's and listener's own entities ignored) from the listener to the source: a
  blocked path multiplies the volume by `occlusionGain` and low-passes it at `occlusionLowpass`, moving there over 0.1
  s. At most 8 rays per frame in the whole game, a source re-measured every 0.1 s.
  `audio.play({ position, velocity, dopplerLevel, occlusion, ... })` does the same for a one-shot. The mixer has a
  per-voice low-pass (bit-identical when it is off). `occlusionMask` from a script is now clamped before it becomes a
  mask. With the defaults a sound is bit-for-bit what it was. See docs/SOUND.md, "Doppler" and "Occlusion".
- `websocket.connect(url, options)` for game scripts: WebSocket connections to the hosts `factoria.json` `network.hosts`
  declares (the same list, errors and `did you mean` as `http.fetch`), with `on`/`off`/`send`/`close`, text and binary
  messages, subprotocols, headers, and reconnects with exponential backoff and a jitter that is the same on every run. A
  scene change closes the connections without events. This is the shared part: the interface
  (`fa/platform/websocket.h`), an RFC 6455 codec (`fa/platform/websocket_codec.h`), a loopback test server, a scripted
  in-memory server for tests and headless runs (`game.websocket`), and the script API. The clients of the platforms
  (WinHTTP, Network.framework, libcurl, Android, the browser) are the entries below; where a platform has no client (a
  Linux machine without a recent enough libcurl), `websocket.supported` is false and a connection fails with an
  `"error"` and a `"close"` event (docs/NETWORKING.md, "WebSocket").
- `websocket.connect` works on macOS and iOS: a Network.framework connection (TCP, TLS with the system's certificates)
  carries the engine's own protocol code, as on Linux and Android, with subprotocols, headers, text and binary messages,
  close codes and reasons in both directions, and the HTTP status of a refused upgrade, tested against the loopback
  server. `NSURLSessionWebSocketTask` was not used: on macOS 26 it closed the TCP connection without sending the close
  frame. A close waits for the server's answer, or comes after 5 seconds without one as `"error"` and `"close"` 1006
  (docs/NETWORKING.md, "On macOS and iOS").
- The web player opens WebSockets with the browser's own `WebSocket` (`websocket.supported` is true there): messages,
  subprotocols, the engine's connect timeout and close timer, and `error` messages that name what to check, since the
  browser gives no reason; `headers` is an error on the web (the browser cannot send any). `ws.send` and
  `game.websocket.send` also take a `DataView`.
- Linux: `websocket.connect` reaches real servers (`ws://` and `wss://`). libcurl, loaded at run time as for
  `http.fetch`, opens the connection (proxy, TCP, TLS) and the engine's own protocol code does the rest, so any libcurl
  from 7.45 works; without libcurl `websocket.supported` is false and says why (docs/NETWORKING.md, "WebSocket").
- Android: `websocket.connect` works (M98.2c): `wss://` over Java's `SSLSocket` through JNI, with the host name checked
  against the certificate, and `ws://` to localhost over a plain socket, both with the engine's own protocol code; built
  by CI, not yet run on a device (docs/NETWORKING.md, "Which platforms can connect now").
- Windows: `websocket.connect` works, on WinHTTP's WebSocket API with the system's certificates and proxy.
- `factoria validate` warns about a script that calls `websocket.connect` in a game with no `network` hosts, as it does
  for `http.fetch`.
- `TextField` has `caretIndex`, `selectionStart`, `selectionEnd` and a runtime `composition`, and scripts read
  `input.composing` / `input.compositionText`: the shared interface for text editing and IME composition (M98.6).
  Nothing moves the caret yet.
- `TextField` editing: a caret you move with the arrows (by word with Ctrl, Alt on macOS), Home / End, Delete, a
  selection (Shift, drag, double click, Ctrl/Cmd+A), cut / copy / paste of the selection, a scrolling field,
  `password`, and the IME composition drawn at the caret with an exact caret rectangle for the candidate window.
  Ctrl/Cmd+C with nothing selected no longer copies the whole text. New runtime fields `compositionCaret`,
  `compositionSelection`, `scrollX`. A click, or a focus move, commits a composition into the field it began in; a
  password field keeps the input method off, passes `password` to the platform keyboard and is one word for word keys
  and a double click; `maxLength` never cuts inside an emoji sequence; a script's write to `text` moves the caret at
  once; an unfocused long field keeps its last scroll until a script empties it; caret and selection assume
  left-to-right text for now.
- macOS and iOS: a focused `TextField` composes natively. Japanese, Chinese and Korean input methods show their pre-edit
  text as a composition, put the candidate window under the caret and type only the committed text, once; dead keys
  (Option-E) show their pending accent. The keys the input method did not use, and all keys while no field has the
  focus, reach the game as before. The editor's Play mode does not compose yet. See [docs/TEXT.md](docs/TEXT.md),
  "Typing text".
- Windows: a focused `TextField` composes natively too (IMM32 on the game's window). The Microsoft Japanese, Pinyin and
  Korean IMEs show their pre-edit text in the field with the converted clause selected, their candidate list sits under
  the caret, and the commit types once. A key the IME takes (Enter that confirms, Backspace inside a composition) is not
  also a game key. While no field has the focus the window has no input context, so the IME leaves game keys alone.
- Android: a focused `TextField` composes natively. Gboard, Samsung Keyboard and the other keyboards compose into the
  engine's input connection (a new Java class, `factoria.engine.Ime`, in every exported project, whose manifest now
  always has `android:hasCode="true"`): Japanese, Chinese and Korean pre-edit text and predictive words show in the
  field and type once, the converted clause selected, and a tap in the field or a focus move drops what the keyboard
  still sends about the composition. Password fields and unfocused games get keys, as before; a missing class or a
  failed call leaves the keyboard sending keys, with one log line. See [docs/TEXT.md](docs/TEXT.md), "What composes
  where".
- Linux and the web: a focused `TextField` composes natively as well. On Linux the X input method (ibus, fcitx, from
  `XMODIFIERS`; through XWayland on a Wayland desktop) draws its pre-edit text in the field when it can, with the
  converted clause selected and its candidate window under the caret. In a browser a hidden `<input>` sits at the caret
  and its composition events become the field's composition, on desktop and phone keyboards. On both the keys the input
  method takes are not game keys, and the commit types once.
- **IME polish of Android, Linux and the web (M98 follow-ups):** Android: a frame holds either text and composition
  changes or one press of an editing key (Backspace, Enter, Tab, an arrow), never both, so a Tab that follows a commit
  no longer moves the focus before the field takes the text (a commit "a\t" is the text in one frame and Tab in the
  next; a second editing press waits a frame as well); the Back button is delivered at once, not after a long
  `deleteSurroundingText` or a paste of many lines; with the key queue full the key releases are still kept, so no key
  stays held; the keyboard is told the selection after each change of the pre-edit string (`updateSelection`, which
  Gboard and Samsung Keyboard use to keep their suggestions in step); the window keeps the keyboard as it is when it
  gets the focus back (`SOFT_INPUT_STATE_UNCHANGED`), so it is not opened by the text view alone. Linux: an input
  context without pre-edit callbacks is reset on a click only after its input method took a key (it was a server round
  trip on every click), and the game no longer keeps `PropertyChangeMask` on the root window after the input method is
  detached. Web: a blur of the hidden `<input>` to another page element ends the composition, Safari's
  `insertFromComposition` outside a composition types its text once, the keys sokol_app does not know (code 0) share no
  state, and a phone keyboard with the IME off (a password field) gets an `<input type="password">` so it turns its
  predictions off.
- **Docs (M97.3a):** the docs are laid out for reading cheaply. `docs/COMPONENTS.md` (1.8 MB) is no longer inside the
  binary: `docs.read components` answers with a pointer to `docs.components`, which serves one component at a time (the
  file stays in the repository for GitHub readers). `docs/MENUS.md` no longer prints the files of the menu kit (257 KB
  to 85 KB): `docs.read menu-kit` lists them and `docs.read menu-kit/scripts/settings.js` reads one, straight from the
  kit `project.add_menu_kit` copies. `ARCHITECTURE.md` and `BUILDING.md` moved to `docs/design/` and are not in the
  binary (the engine developers read the repository). README.md and README.es.md are organised by audience and link
  every doc; a test keeps it so. A doc over the budget becomes an entry page (`docs/<NAME>.md`, with an index) plus
  pages (`docs/<name>/<NAME>_<PART>.md`): `docs.read` serves a `heading` that moved to a page from it (`page`,
  `requestedName`, `note`), the entry page lists its pages (`pages`, `contents`), `docs.list` and `docs.search` carry
  `family`, and a test checks that names are unique and every page is linked from its entry page
  (docs/design/ARCHITECTURE.md, "Docs").
- **Docs (M97.3d):** `EXPORTING.md` (190 KB), `PLATFORM.md` (121 KB), `MOBILE.md` (78 KB) and `PERFORMANCE.md` (71 KB)
  are split into an entry page and pages (`docs/exporting/`, `docs/platform/`, `docs/mobile/`, `docs/performance/`,
  every one under 45 KB); every heading kept its text, so `docs.read exporting --heading "Android"` still finds it.
- **Docs (M97.3c):** `docs/SCRIPTING.md` (186 KB), `docs/EDITOR.md` (154 KB) and `docs/MENUS.md` (86 KB) are entry pages
  with pages in `docs/scripting/`, `docs/editor/` and `docs/menus/`, each under 55 KB; every heading keeps its text, so
  `docs.read scripting --heading Input` and the old references still find it.
- **Docs (M97.3e):** `AI_PROVIDERS.md`, `ASSETS.md`, `MODELING.md` and `IMAGES.md` are split into an entry page plus
  pages (`docs/ai-providers/`, `docs/assets/`, `docs/modeling/`, `docs/images/`), each under 45 KB; a `heading` that
  moved is still served by `docs.read <name>`.
- A deprecation policy for commands, component fields and the script API: the `deprecated` section of
  `tools/common/api_since.json` (empty for now) says since when and what replaces each one. A deprecated command, a
  scene or prefab with a deprecated component or field, and a call of a deprecated script function log one warning that
  names the replacement and the version that removes it; the typings (`@deprecated`), `docs/COMPONENTS.md`,
  `docs/reference/`, `docs.components`, `docs.commands` and the MCP tools mark it. Something deprecated is removed two
  minor versions later, and a test fails when it is not (docs/ARCHITECTURE.md, "Versions"). `tool_describe` (MCP and the
  built-in agent) and `factoria commands <name>` (text and `--json`, and `--json` of the list) show the `deprecated`
  object too. A warning comes only from the command registry, the scene and prefab loader and the script prelude, once
  per process (once per project in the editor, which forgets what it said when a project opens), and only in a program
  that calls `install_deprecations()` (the docs say so). A non-empty table costs a command call or a loaded component no
  lock and no key (a lock-free filter by name); a deprecated script constant stays non-writable after its first warning.
- **Docs (M97.3b):** `docs/AI_GUIDE.md` (275 KB), `ANIMATION.md` and `MUSIC.md` are split into an entry page plus pages
  under `docs/ai-guide/`, `docs/animation/` and `docs/music/` (every page under 50 KB). Every heading keeps its text, so
  `docs.read ai-guide --heading "Platformer character"` still finds it; the AI guide's generated tools table now lives
  in `docs/ai-guide/AI_GUIDE_TOOLS.md` (`docs.write_reference` fills it there).
- **Editor polish, multi-selection and prefab overrides (M98 pol-ed2):** the selection is pruned of dead entities only
  in Edit (a game that destroys and respawns entities no longer empties it); a typed value in the primary's field writes
  to every selected entity even when it equals the shown one, and the Inspector says "Changed k of N entities"; the move
  and rotate gizmos refuse a selection that mixes HUD and world entities (one toast); the viewport marquee skips meshes
  behind the camera. `prefab.apply` shares one rest pose with the other instances, tells when applying a removed
  component drops an instance's own field overrides, and finds the same prefab file under two spellings on a
  case-sensitive volume. The Inspector warns when Undo steps back an Apply to prefab (the prefab file stays changed).
- **Editor, last polish (M98 pol-last-ed):** the viewport marquee uses the camera under its centre for its projection (a
  split screen with an orthographic and a perspective camera) and looks along that camera's own matrix, so a camera
  whose viewport counts design pixels no longer tilts the test for meshes behind it; the move/rotate gizmo's
  mixed-selection answer is also refreshed when the undo stack hit its cap; the copied-prefab path error is one
  sentence; the Inspector docs say that Esc in a number box restores the text (a value already written while typing
  stays).
