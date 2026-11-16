# What's new in FactorIA

The editor shows these notes when it offers an update, and each release on GitHub uses its section. Newest first.

Older versions, one file per minor version with its patch releases: [0.28](changelog/0.28.md), [0.27](changelog/0.27.md), [0.26](changelog/0.26.md), [0.25](changelog/0.25.md), [0.24](changelog/0.24.md), [0.23](changelog/0.23.md), [0.22](changelog/0.22.md), [0.21](changelog/0.21.md), [0.20](changelog/0.20.md), [0.19](changelog/0.19.md), [0.18](changelog/0.18.md), [0.17](changelog/0.17.md), [0.16](changelog/0.16.md), [0.15](changelog/0.15.md), [0.14](changelog/0.14.md), [0.13](changelog/0.13.md), [0.12](changelog/0.12.md), [0.11](changelog/0.11.md), [0.10](changelog/0.10.md), [0.9](changelog/0.9.md), [0.8](changelog/0.8.md), [0.7](changelog/0.7.md), [0.6](changelog/0.6.md), [0.5](changelog/0.5.md), [0.4](changelog/0.4.md), [0.3](changelog/0.3.md), [0.2](changelog/0.2.md), [0.1](changelog/0.1.md).

## Unreleased

- **Editor undo as commands, first half (M98.7e1):** an edit of a field or a component (Inspector fields, rename, the active box,
  Transform gizmo drags, adding and removing a component) no longer stores a copy of the whole scene on the undo stack: it stores
  the command and its inverse, built from the scene before the edit, so 100 edits cost less than one snapshot of a big scene.
  Undo and Redo run those commands, a drag is still one step, and a step that fails midway puts the scene back and says which
  command failed. The other edits (entities created, deleted, reparented, pasted; the Console and the AI; bone tools) still take
  a snapshot until the second half. docs/EDITOR.md, "Undo entries".
- **Copy, cut and paste of entities (M98.7c):** the new commands `scene.copy_entities` (entities with their subtrees as one
  self-contained JSON text: components, children, links to prefabs) and `scene.paste_entities` (creates them under an optional
  parent or each under the parent it had, with free ids, `nameSuffix`, and the new ids in the answer) make the clipboard
  scriptable, across scenes and projects. An Entity field that names an entity of the copied set names the copy; one that names an
  entity outside it is kept when the target exists in the destination and cleared otherwise (listed in `cleared`). A text that is
  not a copy (not JSON, another format or version) gives an error with the JSON pointer and the fix. In the editor, Ctrl/Cmd+C, X
  and V in the Hierarchy and the Viewport (and Edit > Copy, Cut, Paste, Duplicate, and the row menu) use the system clipboard;
  Paste goes next to the primary and selects the copies with the copy of the primary last; Cut and Paste are one Undo step each.
  Duplicate now goes through the same code, so references inside the duplicated set follow the copies (before, they were not
  remapped), and the copies keep their prefab links. On macOS the system menu shows no key for Copy, Cut and Paste (it would
  take Cmd+C from the other panels).
- **Windows gamepads beyond XInput (M98.5b1):** DualShock 4, DualSense, Switch Pro and generic USB/Bluetooth pads are read on
  Windows through Raw Input and HID (`hid.dll`, loaded at run time), next to XInput for Xbox pads. Each report is parsed
  through the pad's own descriptor (buttons, axes scaled by their logical range, the hat) in DirectInput's numbering, so the
  Windows lines of SDL GameControllerDB, now embedded in the Windows build only, map them; `SDL_GAMECONTROLLERCONFIG` and
  the project's `gamecontrollerdb.txt` come first, and a pad nothing lists gets a default layout read from the pad. XInput
  and HID pads share the slots 0..3 (a pad keeps its slot while connected, a gap is filled first); plugging comes from the
  OS's device notifications, and XInput's empty slots are asked every 2 s and right after a notification instead of on a
  fixed timer only. HID pads answer `canRumble: false` with a reason saying their rumble is coming (M98.5b2). Not yet tried
  with a physical pad.
- **A UI layout that does not write `Transform.position` (M98.6f), a behaviour change:** a Panel or ScrollList used to move
  its children by adding the layout's delta into `Transform.position` every frame (so a saved scene held the layout's
  result). It now keeps the placement apart (`World::ui_layout_offset`, not saved, not in an undo snapshot) and the child's
  `position` is its own offset from the slot, 0 = exactly in it. A game whose script reads `entity.position` of a laid-out
  widget now gets that offset (read `entity.worldPosition`, or `ui.rectOf`, for where it is) and a script that sets `position`
  on one nudges it from the slot instead of being overwritten. Drawing, hit tests, drag, bounds and the editor viewport see
  the placed result; the Inspector shows the offset and a viewport drag edits it. A scene saved before has the placement baked
  into those positions: the engine warns once per widget and the new command `ui.reset_layout_positions` sets them to 0 (no
  example scene needed it). A widget moved into a laid-out Panel or ScrollList with `scene.set_parent` (keepWorld) goes to its
  slot, position 0, as before; reordering under the same parent changes only the order. 6e's turned-parent drawing now applies only under a turned or scaled widget, so a plain scaled
  group of HUD visuals keeps its old placement (docs/menus/MENUS_RECIPES.md, "Where a laid-out child is").
- **Several entities selected (M98.7b):** in the editor, Ctrl/Cmd+click toggles and Shift+click selects a range in the
  Hierarchy, and Ctrl/Cmd+click, Shift+click and a marquee on empty space select in the Viewport. Every selected entity is
  outlined; the gizmo moves, rotates and scales all of them about the primary as one Undo step; Delete, Duplicate and
  drag-to-reparent act on the whole selection; the Inspector shows the components all of them share ("—" where values
  differ) and an edit writes to all of them as one Undo step. The AI context lists the other selected ids.
- **Encrypted saves and slot versions (M98.1):** `storage.set(key, value, {encrypt: true})` (and `setAsync`, with or without
  `compress`) seals the key's file with ChaCha20-Poly1305 under a key derived from a per-project secret
  (`factoria.json` `storage.encryptionSecret`, created once with the new command `project.create_storage_secret`; a project
  without it gets a teaching error, and `project.info` / `game.project` show the secret as `"(hidden)"`). `storage.get` opens
  a sealed value transparently; one that fails authentication is kept aside like a damaged file (`storage.corrupt`). It is
  tamper-evidence, not secrecy: the secret ships with the game (docs/scripting/SCRIPTING_UI_SCENES.md, "Encrypted saves"). A plain
  file is still read by default (a game can turn encryption on later), so a player could replace a sealed file with a hand-written
  one: `storage.get(key, fallback, {encrypted: true})` refuses it (kept aside, `storage.corrupt`), and `storage.isEncrypted(key)`
  tells which values are sealed. The secret is shown as `"(hidden)"` by `fs.read` / `fs.search` of `factoria.json` (and of a
  checkpoint's copies), `checkpoint.read` (which refuses `out` for that file), the MCP resource and the AI prompt, so those
  channels do not hand it to a model; it is masking per channel, not a guarantee (the secret is in the repository).
  `storage.list` reports `encrypted` per key. The Slots kit writes a `version` in every record (option `version`), calls
  `upgrade(data, fromVersion)` with it (bare saves and old records are version 0), refuses a record from a newer version, and has
  an `encrypt` option and a `requireEncrypted` one (a slot that is not sealed is damaged); its tests and the CLI fixture copies are updated.

- **Pad rumble, the shared part (M98.5a):** `input.rumble(pad, low, high, seconds)`, `input.stopRumble(pad?)` and
  `input.gamepad(i).canRumble` shake the motors of a pad (low and high frequency, 0..1, up to 10 s, on the game's clock). The
  engine stops every pad on pause, focus loss, unplug, scene change and quit. It works on Windows (XInput pads) and in
  Chrome-based browsers; the other platforms answer `canRumble: false` with the reason until their backends land (Linux, macOS,
  iOS and Android in M98.5c, Windows pads that are not XInput in M98.5b). Tests record the requests (`game.rumbles()`,
  `game.rumbleState(pad)`, `connect({ canRumble: true })`) and the command `game.rumble` drives a running game. See
  docs/scripting/SCRIPTING_WORLD_INPUT.md, "Pad rumble".
- **HRTF for headphones (M98.8c):** `AudioListener.spatialization: "hrtf"` places spatial sounds with a parametric head model
  written for the engine (the structure of Brown and Duda, 1998, with Woodworth's time difference; no measured data, no library):
  the interaural time difference follows the angle and `headRadius` (about 0.66 ms at 90 degrees for 0.0875), the far ear is a
  little quieter and loses the high frequencies to the head's shadow, and a sound in front and its mirror behind have the same
  time. Everything is interpolated per sample, so a moving source makes no click, and the mixer stays lock-free and allocation-free.
  A stereo clip is mixed to mono first. A 2D camera as the listener and a mono output keep `"pan"`, which is bit-for-bit what it
  was. A `headRadius` outside 0.03 to 0.12 m (at `speedOfSound` 343) is clamped with a warning. See docs/SOUND.md, "Headphones".

- **UI layout and hit tests follow rotation and scale (M98.6):** a widget whose Transform (or a parent's) has `rotation.z` or a
  `scale` other than 1 is hovered, clicked, dragged onto, wheel-scrolled, tooltipped, navigated to and (TextField) clicked into
  the turned rectangle it is drawn as, not an axis-aligned one: the renderer draws widgets turned and scaled around their pivot
  too. A child's scale multiplies the room its slot takes in a Panel row, column or grid (a `fit` panel grows with it); its
  rotation keeps the slot. `ui.rectOf` and `ui_rect` report the bounding box; new `ui_quad`, `ui_transform`, `ui_contains`,
  `ui_local_point`, `ui_footprint_rect` and `ui_own_rect` in `ui_rect.h`. A turned ScrollList still clips to the bounding box
  of its turned rectangle (a scissor cannot turn) and warns once. Unturned, unscaled UI is bit for bit the same.
- **Pad rumble on Linux, Android and Apple (M98.5c):** `input.rumble` now drives the motors on Linux (evdev force feedback:
  one `FF_RUMBLE` effect per pad on `/dev/input/eventN`, which must be writable: the reason names the `input` group and the
  udev rule when it is not), on Android (the pad's `InputDevice` vibrators: `getVibratorManager()` on API 31+, `getVibrator()`
  before; two vibrators get low and high apart, one the stronger of the two) and on macOS and iOS (GameController haptics with
  CoreHaptics: low on the left handle, high on the right). The numbers each API wants are pure, unit-tested helpers
  (`fa/platform/gamepad_rumble_map.h`); the three backends are untested on hardware. The AI guide's feedback example no longer
  uses "No gamepad rumble".
- **Render interpolation (M98.3):** `"render": { "interpolation": true }` in `factoria.json` (default `false`, so nothing
  changes for a game that does not ask) draws entities at the pose between the last two fixed steps, so a 60 Hz simulation
  looks smooth at 120-144 Hz. Only the drawing is blended (position, scale, rotation by slerp; children, cameras and physics
  bodies included): Transform, physics and scripts see the real pose. The new `Interpolation` component sets it per entity
  (`on` / `off` / `inherit`), a new entity, a Transform written outside the fixed step and `entity.teleport()` are drawn
  without smearing, and `render.interpolationSnapDistance` treats a long step as a jump. `game.step`, headless runs, replays
  and a paused game draw the real pose. Scripts, UI hit tests and picking read the real camera pose, so `screenToWorld` does not
  depend on the frame time; a rotation that turns more than 180 degrees in one step is not blended. See docs/RENDERING.md, "Render interpolation".
### Added

- `fa/core/crypto.h`: authenticated encryption for save files, written in the engine with no new dependency: SHA-256 as raw bytes,
  HMAC-SHA256, HKDF-SHA256, ChaCha20-Poly1305 (RFC 8439, checked against the RFC vectors), `seal_blob` / `open_blob` (a file
  format with a random salt and nonce per seal; a changed byte, a wrong key or a wrong slot name fails with "the data was
  changed or the key is wrong" and no data), a constant-time compare, `secure_zero`, and `random_bytes` from the system's random
  source on every platform. The save slots (M98.1b) use it; it keeps casual edits out, it is not copy protection.
- 3D audio, the shared part (M98.8a): `AudioSource.rolloff` has a fourth value, `"curve"`, with `rolloffCurve` (the gain over
  distance / range, the curve form of particles); a sound cone (`coneInnerAngle`, `coneOuterAngle`, `coneOuterGain`, `coneAxis`)
  makes a source louder in front, in 2D and 3D; `audio.play({ position })` takes the same (`rolloffCurve`, `direction` and the
  cone angles). The fields the next two packages need are in and documented as not working yet: `AudioSource.dopplerLevel` and
  occlusion (`occlusion`, `occlusionMask`, `occlusionGain`, `occlusionLowpass`), `AudioListener.speedOfSound`,
  `spatialization` (`pan` | `hrtf`) and `headRadius`, and `velocity`, `dopplerLevel` and the occlusion options of `audio.play`
  (M98.8b doppler and occlusion by physics rays, M98.8c HRTF, now done). With the defaults a sound is bit-for-bit what it was.
- 3D audio, doppler and occlusion (M98.8b): `AudioSource.dopplerLevel` shifts the pitch with the speed a source and the listener
  approach or separate at (`AudioListener.speedOfSound`; velocities from the change of world position between frames, a jump
  of more than 4 speeds of sound per second counts as a teleport and shifts nothing; the factor is clamped to 0.25..4 and glides
  over about 0.05 s), and `AudioSource.occlusion` casts a physics ray (2D and 3D colliders of `occlusionMask`, triggers and the
  source's and listener's own entities ignored) from the listener to the source: a blocked path multiplies the volume by
  `occlusionGain` and low-passes it at `occlusionLowpass`, moving there over 0.1 s. At most 8 rays per frame in the whole
  game, a source re-measured every 0.1 s. `audio.play({ position, velocity, dopplerLevel, occlusion, ... })` does the same for a
  one-shot. The mixer has a per-voice low-pass (bit-identical when it is off). `occlusionMask` from a script is now clamped
  before it becomes a mask. With the defaults a sound is bit-for-bit what it was. See docs/SOUND.md, "Doppler" and "Occlusion".
- `websocket.connect(url, options)` for game scripts: WebSocket connections to the hosts `factoria.json` `network.hosts` declares (the
  same list, errors and `did you mean` as `http.fetch`), with `on`/`off`/`send`/`close`, text and binary messages, subprotocols,
  headers, and reconnects with exponential backoff and a jitter that is the same on every run. A scene change closes the
  connections without events. This is the shared part: the interface (`fa/platform/websocket.h`), an RFC 6455 codec
  (`fa/platform/websocket_codec.h`), a loopback test server, a scripted in-memory server for tests and headless runs
  (`game.websocket`), and the script API. The clients of the platforms (WinHTTP, `NSURLSessionWebSocketTask`, libcurl, Android,
  the browser) come in the same milestone; until then `websocket.supported` is false outside tests and a connection fails with an
  `"error"` and a `"close"` event (docs/NETWORKING.md, "WebSocket").
- `websocket.connect` works on macOS and iOS (`NSURLSessionWebSocketTask`: system certificates and proxy, subprotocols, headers, text
  and binary messages, close codes, the HTTP status of a refused upgrade), tested against the loopback server; a close is
  reported as soon as the system has sent it (docs/NETWORKING.md, "On macOS and iOS").
- The web player opens WebSockets with the browser's own `WebSocket` (`websocket.supported` is true there): messages,
  subprotocols, the engine's connect timeout and close timer, and `error` messages that name what to check, since the
  browser gives no reason; `headers` is an error on the web (the browser cannot send any). `ws.send` and
  `game.websocket.send` also take a `DataView`.
- Linux: `websocket.connect` reaches real servers (`ws://` and `wss://`). libcurl, loaded at run time as for `http.fetch`, opens
  the connection (proxy, TCP, TLS) and the engine's own protocol code does the rest, so any libcurl from 7.45 works; without
  libcurl `websocket.supported` is false and says why (docs/NETWORKING.md, "WebSocket").
- Android: `websocket.connect` works (M98.2c): `wss://` over Java's `SSLSocket` through JNI, with the host name checked
  against the certificate, and `ws://` to localhost over a plain socket, both with the engine's own protocol code; built
  by CI, not yet run on a device (docs/NETWORKING.md, "Which platforms can connect now").
- Windows: `websocket.connect` works, on WinHTTP's WebSocket API with the system's certificates and proxy.
- `factoria validate` warns about a script that calls `websocket.connect` in a game with no `network` hosts, as it does for
  `http.fetch`.
- `TextField` has `caretIndex`, `selectionStart`, `selectionEnd` and a runtime `composition`, and scripts read
  `input.composing` / `input.compositionText`: the shared interface for text editing and IME composition (M98.6). Nothing
  moves the caret yet.
- `TextField` editing: a caret you move with the arrows (by word with Ctrl, Alt on macOS), Home / End, Delete, a selection
  (Shift, drag, double click, Ctrl/Cmd+A), cut / copy / paste of the selection, a scrolling field, `password`, and the IME
  composition drawn at the caret with an exact caret rectangle for the candidate window. Ctrl/Cmd+C with nothing selected
  no longer copies the whole text. New runtime fields `compositionCaret`, `compositionSelection`, `scrollX`. A click, or a focus move, commits a
  composition into the field it began in; a password field keeps the input method off, passes `password` to the platform
  keyboard and is one word for word keys and a double click; `maxLength` never cuts inside an emoji sequence; a script's
  write to `text` moves the caret at once; an unfocused long field keeps its last scroll; caret and selection assume
  left-to-right text for now.
- macOS and iOS: a focused `TextField` composes natively. Japanese, Chinese and Korean input methods show their pre-edit
  text as a composition, put the candidate window under the caret and type only the committed text, once; dead keys
  (Option-E) show their pending accent. The keys the input method did not use, and all keys while no field has the focus,
  reach the game as before. The editor's Play mode does not compose yet. See [docs/TEXT.md](docs/TEXT.md), "Typing text".
- Windows: a focused `TextField` composes natively too (IMM32 on the game's window). The Microsoft Japanese, Pinyin and
  Korean IMEs show their pre-edit text in the field with the converted clause selected, their candidate list sits under the
  caret, and the commit types once. A key the IME takes (Enter that confirms, Backspace inside a composition) is not also a
  game key. While no field has the focus the window has no input context, so the IME leaves game keys alone.
- Android: a focused `TextField` composes natively. Gboard, Samsung Keyboard and the other keyboards compose into the
  engine's input connection (a new Java class, `factoria.engine.Ime`, in every exported project, whose manifest now always
  has `android:hasCode="true"`): Japanese, Chinese and Korean pre-edit text and predictive words show in the field and type
  once, the converted clause selected, and a tap in the field or a focus move drops what the keyboard still sends about
  the composition. Password fields and unfocused games get keys, as before; a missing class or a failed call leaves the
  keyboard sending keys, with one log line. See [docs/TEXT.md](docs/TEXT.md), "What composes where".
- Linux and the web: a focused `TextField` composes natively as well. On Linux the X input method (ibus, fcitx, from
  `XMODIFIERS`; through XWayland on a Wayland desktop) draws its pre-edit text in the field when it can, with the
  converted clause selected and its candidate window under the caret. In a browser a hidden `<input>` sits at the caret
  and its composition events become the field's composition, on desktop and phone keyboards. On both the keys the input
  method takes are not game keys, and the commit types once.
- **Docs (M97.3a):** the docs are laid out for reading cheaply. `docs/COMPONENTS.md` (1.8 MB) is no longer inside the
  binary: `docs.read components` answers with a pointer to `docs.components`, which serves one component at a time (the
  file stays in the repository for GitHub readers). `docs/MENUS.md` no longer prints the files of the menu kit (257 KB
  to 85 KB): `docs.read menu-kit` lists them and `docs.read menu-kit/scripts/settings.js` reads one, straight from the
  kit `project.add_menu_kit` copies. `ARCHITECTURE.md` and `BUILDING.md` moved to `docs/design/` and are not in the
  binary (the engine developers read the repository). README.md and README.es.md are organised by audience and link
  every doc; a test keeps it so. A doc over the budget becomes an entry page (`docs/<NAME>.md`, with an index) plus pages
  (`docs/<name>/<NAME>_<PART>.md`): `docs.read` serves a `heading` that moved to a page from it (`page`, `requestedName`,
  `note`), the entry page lists its pages (`pages`, `contents`), `docs.list` and `docs.search` carry `family`, and a test checks
  that names are unique and every page is linked from its entry page (docs/design/ARCHITECTURE.md, "Docs").
- **Docs (M97.3d):** `EXPORTING.md` (190 KB), `PLATFORM.md` (121 KB), `MOBILE.md` (78 KB) and `PERFORMANCE.md` (71 KB) are
  split into an entry page and pages (`docs/exporting/`, `docs/platform/`, `docs/mobile/`, `docs/performance/`, every one
  under 45 KB); every heading kept its text, so `docs.read exporting --heading "Android"` still finds it.
- **Docs (M97.3c):** `docs/SCRIPTING.md` (186 KB), `docs/EDITOR.md` (154 KB) and `docs/MENUS.md` (86 KB) are entry pages
  with pages in `docs/scripting/`, `docs/editor/` and `docs/menus/`, each under 55 KB; every heading keeps its text, so
  `docs.read scripting --heading Input` and the old references still find it.
- **Docs (M97.3e):** `AI_PROVIDERS.md`, `ASSETS.md`, `MODELING.md` and `IMAGES.md` are split into an entry page plus pages
  (`docs/ai-providers/`, `docs/assets/`, `docs/modeling/`, `docs/images/`), each under 45 KB; a `heading` that moved is
  still served by `docs.read <name>`.
- A deprecation policy for commands, component fields and the script API: the `deprecated` section of
  `tools/common/api_since.json` (empty for now) says since when and what replaces each one. A deprecated command, a scene or
  prefab with a deprecated component or field, and a call of a deprecated script function log one warning that names the
  replacement and the version that removes it; the typings (`@deprecated`), `docs/COMPONENTS.md`, `docs/reference/`,
  `docs.components`, `docs.commands` and the MCP tools mark it. Something deprecated is removed two minor versions later, and
  a test fails when it is not (docs/ARCHITECTURE.md, "Versions").
- **Docs (M97.3b):** `docs/AI_GUIDE.md` (275 KB), `ANIMATION.md` and `MUSIC.md` are split into an entry page plus pages under `docs/ai-guide/`, `docs/animation/` and `docs/music/` (every page under 50 KB). Every heading keeps its text, so `docs.read ai-guide --heading "Platformer character"` still finds it; the AI guide's generated tools table now lives in `docs/ai-guide/AI_GUIDE_TOOLS.md` (`docs.write_reference` fills it there).

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
  plus 10 %. See docs/design/BUILDING.md, "Player size budgets".
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
