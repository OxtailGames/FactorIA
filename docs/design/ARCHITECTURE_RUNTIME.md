# FactorIA architecture: animation, UI, platform services, localization and docs

Part of [FactorIA architecture](ARCHITECTURE.md) (the entry page lists every page).

## Animation
Skeletal animation is GPU-free and lives in `fa_scene`, so simulation and tests never need a renderer:
- `skeleton.h` (`load_skeleton`, cached per path + modification time) reads a glTF with cgltf through `fa::fs`: the node
  hierarchy with rest poses, skins (joints, inverse bind matrices), animation clips (translation / rotation / scale channels;
  LINEAR, STEP, CUBICSPLINE) and the `JOINTS_0` / `WEIGHTS_0` of skinned primitives (`SkinVertices`, matched to the renderer's
  loader by node and primitive index). The renderer loader ignores the transform of a skinned node (glTF spec) and keeps
  each skinned part's joints/weights in vertex buffer 2 (`SubMesh::skinVb`, `SkinVertex`, at most `kMaxSkinJoints` = 64).
- `animation.h` samples clips into a `Pose`, blends poses and builds the skinning palette. `update_animators(world, dt)` runs
  every `Animator`: state machine, clip time, cross-fade, clip events (pushed to `world.events().game`), then the palette.
- **When it runs:** the runtime calls it once per FIXED step, after `physics.step` and before `scripts.dispatch_events`, with
  `fixedDt * time.scale` (not at all while the scale is 0). Events therefore reach `world.on` in the step that produced them and
  headless runs are deterministic. The variable-rate render step never advances animation.
- **What the renderer reads:** `Animator::skinPalettes` (components.h), a runtime-only vector with one palette per skin (`palette` is skin 0; the importer adds "rigid" skins for meshes that follow animated nodes), one matrix per joint,
  `jointGlobal * inverseBind` in the glTF's model space (vertices of a skinned mesh are not transformed by their node). The renderer
  (`renderer_draw.cpp`) packs it into the `fa_skin` uniform (64 joints x 3 rows of a 3x4 matrix) and draws with the
  skinned programs of the mesh template (`mesh_skin`, `shadow_skin`: only the vertex stage differs, the lighting code is
  shared). Skinned items carry the Animator pointer in their material key so they never join an instanced batch, and their
  culling box is `skinned_bounds` (the bind box carried by every joint, joined).
- The tween module (`tween`, `ease`) is JavaScript (`factoria.js`), advanced by the script system's update with the scaled `dt`,
  so it shares the game clock with timers.
- **Sprite animators and particles are simulation too.** `update_sprite_animators(world, dt)` (`fa/scene/sprite_animator.h`) advances
  every `SpriteAnimator` (frame, `clipEnded`, frame events, `Sprite.region`) and `World::particles().update(world, dt)`
  (`fa/scene/particle_store.h`) steps every `ParticleEmitter`, runs its `autoDestroy` and spawns the bursts queued by
  `emitBurst`. Both run in the fixed step right after `update_vfx`, with `fixedDt * time.scale`, and again with `dt` 0 before a
  picture is drawn (`Engine::Impl::settle_visuals`: a clip a script changed this frame, or a burst, shows in this frame's
  picture and never advances time). A `SpriteAnimator` reads the size of its sheet from the image file or the packed atlas
  (`texture_size`, cached by file name and looked at again once per frame: the end of the `dt` 0 pass starts the next epoch, so the
  steps of a frame and its settle pass look at a file once. On a platform whose files have no modification time,
  like an Android APK asset, each picture is read once), never from a GPU texture, so a run with `graphics=false` and one that draws
  give the same `Sprite.region`; the renderer only repeats the region for a texture that exists on the GPU alone
  (`runtime:`, `target:`). The particle state is a `ParticleStore` owned by the `World` and keyed by entity: two worlds (the
  editor's scene and its Play session) never share it, and `World::clear()` and every scene load empty it. The renderer
  (`renderer.h`) keeps only camera and parallax in `Renderer::update`; `render_world` draws what the world holds.
- **Text and cameras without a renderer (M91.1b).** Nothing the simulation reads depends on a GPU. Text is shaped and measured by
  `FontSet` (render/src/font_set.h: fonts, the fallback chain, HarfBuzz shaping, wrapping, rich text, `textScale`/`uiScale`,
  `maxTextScale`/`autoShrink`), which has no GPU in it: the renderer's `Fonts::layout` places glyphs on the atlas with what it
  returns, `Renderer::measure_text` and `fa::TextMeasurer` (`fa/render/text_measure.h`, what the engine owns when there is no
  renderer, handed to scripts, the UI and `bounds()` as `VisualMeasure.textSize`) only take the size. One implementation, so the
  sizes are the same numbers with and without a window; `approx_text_size` is left for a built-in font that cannot be loaded, with
  one warning. The cameras are `fa/scene/camera_geometry.h`: `camera_geometry` builds the view, projection and viewport of a
  `Camera` for a render target size, `CameraSet` keeps the cameras of the last frame (`refresh`, the renderer's snapshot: queries
  before the first `render()` see the default camera) and answers `world_to_screen`, `screen_to_world`, `screen_ray` and
  `camera_at`; `update_parallax` writes `Parallax.offset` from it. The offset the world keeps is always the one for the FIRST
  camera (with a renderer too: while it draws, each camera, render target or `CameraView` shifts the layers for itself, and the
  first camera's offset is put back when the gathers are done). A scene load refreshes the `CameraSet`, and the script natives
  fall back to the live orthographic maths while it has no camera. The renderer builds its `CameraInfo` from the same function and
  `Engine::render()` without a renderer refreshes the `CameraSet` from the design size, so `input.mouse.world`,
  `camera.worldToScreen` and Parallax give the same floats either way (the queries always use the OpenGL depth range, whatever the
  backend). `world_state_hash` includes the live particles (`ParticleStore`: positions, ages, the emitter clocks, random sequences and
  emission accumulators).
  The ctests `example_<name>_graphics_same_hash` (one per example) compare `game.state_hash` of the WHOLE world of every scene
  after 40 frames with a renderer that draws and with `--no-graphics` (first the Sprite, SpriteAnimator and ParticleEmitter
  components alone, so a failure says whether the animators differ), and
  engine/runtime/tests/sim_without_renderer_tests.cpp does it frame by frame for a small project with a moving camera, a Parallax
  layer, a fitted panel and wrapped Japanese text. engine/render/tests/text_measure_tests.cpp compares `TextMeasurer` with the
  renderer (Latin, CJK, Arabic, the missing-glyph fallback, wrapping, rich text, the text and interface scales) with `==`, and
  one test with no renderer at all checks fixed sizes of the bundled font (4% tolerance) so it also runs where there is no GPU. The
  `TextMeasurer` is kept in step with the project settings only while there is no renderer.
Game-maker docs: [ANIMATION.md](../ANIMATION.md).

## UI
Menus and settings screens are components (`Panel`, `Button`, `Toggle`, `Slider`, `TextField`, `ScrollList` in
`scene/components.h`, category "UI"), screen space only; `Interactable` is the exception (below). The work is split three ways so nobody depends on a sibling:
- **Where a widget is** has ONE definition, `fa/scene/ui_rect.h` (`ui_rect`, `ui_clip_rect`, `ui_slider_track`); layout, hit-testing, drawing and
  the editor's picking (`bounds.h`) all call it.
- **How it behaves** is `fa_ui` (`UiSystem`, `fa/ui/ui.h`): layout of Panel and ScrollList children, focus rules
  (nothing takes focus except `autoFocus`), navigation and auto-repeat over the `ui_*` actions, pointer hover / press /
  drag / wheel, widget values, and the `ui.*` game events (`world.events().game`, which scripts receive through
  `world.on` and `ui.on`). It reads `Input`, writes components and events, never draws. The runtime calls `update`
  every frame before `scripts.update` and `layout` before drawing; `ui.state` is its read-only command.
- **Any entity as a widget.** The `Interactable` component (`scene/components.h`) makes a composition of sprites, shapes, text and
  children a widget of the same focus, navigation and event system, with no second system next to it: `fa_ui` keeps one list of
  items in which a Button and an Interactable differ only in where the rectangle comes from (`ui/src/interactable.cpp`: the bounds of the
  entity and its children, projected through a camera for a world-space one, or screen-space rectangles). `UiSystem` gets the camera as
  an injected `UiProjectFn` (`set_world_projection`; the runtime installs the renderer's `world_to_screen`/`camera_at`, because `fa_ui` is below
  `fa_render`; without it `scene/camera_query.h` does the orthographic maths, which headless runs use). `InteractableVisual` children
  show, hide or tint by state; hover, blur, press and release events come from Interactables only.
- **How it looks** is `fa_render` (`render/src/ui2d.cpp`): 9-slice backgrounds, labels, focus ring, drawn into the screen quad
  list. A ScrollList's descendants (widgets and every other screen-space item) carry a clip rectangle that `draw_group` applies as a scissor;
  batches only merge with an equal clip.

## Platform services
Achievements, stats, leaderboards, cloud saves, purchases, the store overlay, rich presence, integrity tokens and ads are
ONE request interface, `fa_services` (`fa/services/platform.h`), so a game is written once and a backend decides what answers. A
request is `(method, args)` and gets one answer, a result or `{code, message, hint}`:
- **The catalog** is the `"platform"` section of factoria.json. `PlatformServices::start` checks every id against it
  and adds the store's own id (`storeId`) before the backend sees the request; a mistake is a teaching error there,
  never inside an SDK.
- **A backend** is a `PlatformBackend`: the fake (`fake_platform.h`, in memory, deterministic, the reference of every
  method), "none" (exported games without a store), or the adapter in `fa_runtime` (`platform_backend.h`) that turns a
  native plugin's `FaBackendDesc` (plugin ABI v2, `fa_plugin.h`) into one. `choose_platform_backend` picks which runs.
- **Answers** may come later and from any thread (`PlatformSink`, a weak handle: an answer after the engine is gone is
  ignored). The game thread takes them once per frame (`Engine` calls `PlatformServices::frame()` and
  `ScriptSystem::dispatch_platform()` first thing), which settles the scripts' Promises and calls `platform.on` listeners.
- **Commands** `platform.state`, `platform.reset`, `platform.respond`, `platform.emit`, `platform.revoke`, `platform.set_fake`
  (`platform_commands.h`, registered by the runtime): `game.platform` of `factoria:test` is a view of them.
- **`http.fetch`** is a method of the same pipeline with a backend slot of its own (`set_http_backend`, next to the store and
  ads backends). `PlatformServices::prepare` checks the URL against the `"network"` hosts of factoria.json
  (`fa/services/network.h`) and shapes the arguments; the runtime's `HttpBackend` (`http_backend.cpp`) hands them to
  an `HttpClient` of `fa_platform` (`fa/platform/http.h`: WinHTTP, `NSURLSession`, libcurl loaded with dlopen, Android's
  `HttpURLConnection` through JNI, the browser's `fetch`; one `http_<platform>` file each). Headless runs and tests ask for
  the fake backend, which never touches the network. A plugin cannot offer the "http" service.
- **`analytics` and `remoteConfig`** are script services in `factoria.js`, not platform services: they call `http.fetch`
  (so the same host check and fake apply) and keep their state in `storage` under the engine's own `factoria.*` keys.
  `fa/services/network.h` parses their `factoria.json` sections (`parse_analytics`, `parse_remote_config`) and `factoria
  validate` checks them. The script system ticks them with the unscaled frame time, and runs `app.suspend` and the quit
  flush (`request_quit` and `close_requested` wait up to 3 seconds for a pending request) through hooks of the prelude.
- **`websocket.connect`** is not a `PlatformServices` request: a connection is a stream of events, so `ScriptHost::websocket_client()`
  hands the script system a `WebSocketClient` of `fa_platform` (`fa/platform/websocket.h`: WinHTTP, Network.framework with the engine's codec,
  libcurl, a socket stream through JNI on Android, the browser's WebSocket; `websocket_<platform>` files, plus the memory client of
  headless runs and tests). The script layer checks the address against the same `network.hosts` list before `connect()`.
  Thread rule: whatever the network does is pushed to the connection's `WebSocketEventQueue` by any thread (an OS callback, a
  reader thread) and drained by the game thread once a frame (`dispatch_platform`), so no OS thread ever touches a script or the
  World. The queue lives in a `std::shared_ptr` that every callback captures; the connection's destructor calls `abandon()` and
  returns without waiting (it runs on the game thread), so a callback that comes late finds the queue ended. A scene change closes
  every connection without events; reconnects with backoff run in `factoria.js` on the engine clock.
Docs: [PLATFORM.md](../PLATFORM.md), [NETWORKING.md](../NETWORKING.md), [ANALYTICS.md](../ANALYTICS.md).

## Localization
Text lives in string tables, `locales/<language>.json`, and the engine shows the player's language (docs:
[LOCALIZATION.md](../LOCALIZATION.md)).
- **Pure logic** is `fa_core` (`fa/core/i18n.h`): BCP 47 tags and best match, CLDR plural rules, `{placeholder}`
  formatting, table parsing with JSON-pointer errors, and `I18n` (current language, fallback chain current -> base ->
  default, warn once per missing key). It reads files through `fa::fs`.
- **The system language** is `fa_platform` (`system_languages()`, one `system_language_<platform>` file each).
- **The pass** is `fa_scene` (`localize_world`, `localize_entity`): it writes `t(key)` into `Text.text`, `Button.text`,
  `Toggle.label`, `Slider.label` and `TextField.placeholder` for components with a `key`, only when the string differs.
  The runtime runs it after every scene load, each frame and on a language change; scripts run it for what they spawn.
- **The engine** (`fa_runtime`, `localization.cpp`) owns the `I18n`: it reads `project.localization`, chooses the start
  language (`choose_start_language`: `EngineConfig::language`, `FA_LANGUAGE`, the system language of a windowed game,
  else the default language), switches language (`ScriptHost::set_language`, the `i18n.change` game event) and registers
  `i18n.state` / `i18n.set_language`. It also hands `project.localization.fallback_fonts_for(language)` to
  `Renderer::set_fallback_fonts` when the renderer starts and at every switch (`apply_fallback_fonts`). Scripts see it as
  the `i18n` object (`ScriptHost::i18n()`).
- **The tools** (`fa_tooling`) check the tables and fonts in `factoria validate` (`validate_localization.cpp`, with
  `FontCoverage` from `fa_render`) and register `i18n.export` / `i18n.import` (`translations.cpp`: CSV and XLIFF 1.2 in
  `translations_formats.cpp`). Both read the tables through the same `read_table` (`localization_tables.cpp`).

## Headless
`HeadlessGpu` creates a window-less device: EGL (Linux; Mesa llvmpipe works
without a GPU), Metal (macOS), D3D11 with WARP fallback (Windows). Used by
`factoria run --headless`, tests, the MCP server and CI.

## Docs: names, sizes and pages
`docs/*.md` is embedded in the binary (not `docs/design/`, `docs/i18n/`, `docs/reference/`, `COMPONENTS.md`) and served by
`docs.list`, `docs.read` and `docs.search` (`tools/common/src/docs.cpp`). A doc's name is its file name without the
folder, lower case, `_` as `-` (`doc_name_from_path`), so two embedded docs must never share a file name, whatever
their folder. Every doc has an entry in the manifest of that file (summary, audience).

A doc over about 60 KB is split into an **entry page** and **pages**:

- The entry page stays `docs/<NAME>.md`, so every link to it and `docs.read <name>` keep working. It says what the doc
  covers, gives the essentials a reader needs first, and has an index of its pages, one line each, linking each by relative
  path: `- [Input](scripting/SCRIPTING_INPUT.md): keys, actions, gamepads.`
- Each page is `docs/<name>/<NAME>_<PART>.md` (folder = the doc's lower-case name; `docs/scripting/SCRIPTING_INPUT.md`
  is the doc `scripting-input`). The file name starts with the doc's name so that the embedded name is unique and flat.
  A design doc does the same under `docs/design/<name>/`.
- The doc's **family** is its entry page plus every embedded doc in that folder. `docs.list` gives a page
  `family` (the entry page's name). `docs.read {name:"scripting", heading:"Input"}` serves a heading that is not in the entry
  page from the page of the family that has it (the result has `page`, `requestedName` and a `note`; two pages with it are an
  error that lists both), so an old reference such as `docs/SCRIPTING.md, "Input"` keeps working. A read of the entry page
  without `heading` has `pages` ([{name,title,bytes,path}]), and a cut read lists them in `contents` too.
- `docs.read` looks for a heading in the entry page and in its pages: an exact title on the entry page wins (the result
  lists `alsoOnPages` when a page has the same title, a longer version); otherwise an exact title on exactly one page wins;
  a partial match in several places, or an exact title on several pages, is an error that lists them all.
- A test (`doc_layout_problems()`, `fs_docs_test.cpp`) fails when two embedded docs share a name, when a page sits in a
  folder without its entry page, when a page's file name does not start with its entry page's (`BIG_`), or when the entry
  page has no Markdown link `[Title](<folder>/<FILE>.md)` to a page. The rules are the same whether the docs come from the
  binary or from the repository; `docs/design/` is not embedded, so its names are not checked for uniqueness, but its
  families are checked for links. A page needs a manifest entry like any doc.

