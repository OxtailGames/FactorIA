# API reference

Every component and every command of FactorIA, one page per category. The pages are generated from the engine itself (`factoria call docs.write_reference '{"out":"docs"}'`), so they are exact for this version; a test fails when they fall behind. The same data is available offline with `factoria api --md`, `factoria commands` and, over MCP, `docs_components` and `docs_commands`. Use your browser's find (Ctrl+F) on this page to locate anything.

Version marks: an entry added after 0.1.0 ends with "(Since 0.1.x)", and "(Not released yet ...)" means it is only on the main branch, in no download. Nothing is shown for what existed in 0.1.0. If your factoria is older than a mark, that item is missing there (`factoria --version`).

## Components

### [2D](components/2d.md)

- [Light2D](components/2d.md#light2d): A light for lit 2D visuals: sprites and tilemaps with `lit` true. _Since 0.2.0._
- [Parallax](components/2d.md#parallax): Shifts the drawing of this entity's world-space visuals (Sprite, Shape2D, Text, Tilemap) with the camera so far layers slide slower than near ones. _Since 0.2.0._
- [ParticleEmitter](components/2d.md#particleemitter): Emits short-lived particles (smoke, sparks, explosions).
- [Shape2D](components/2d.md#shape2d): Untextured 2D primitive for prototypes, UI panels and debug visuals.
- [Sprite](components/2d.md#sprite): Draws a textured (or solid color) quad.
- [SpriteAnimator](components/2d.md#spriteanimator): Flipbook animation over a grid sprite sheet.
- [Text](components/2d.md#text): Draws a string with a TrueType font (or the built-in font).
- [Tilemap](components/2d.md#tilemap): A grid of tiles drawn from a tileset texture; tile index -1 is empty.

### [3D](components/3d.md)

- [Animator](components/3d.md#animator): Plays the skeletal animation clips of a skinned glTF model (the model of the MeshRenderer on the same entity, or `model`): one clip at a time with cross-fades, clip events, and an optional small state machine (`params`, `states`, `transitions`). _Since 0.2.0._
- [Light](components/3d.md#light): A light source for 3D meshes.
- [MeshRenderer](components/3d.md#meshrenderer): Draws a 3D mesh with a PBR material (GGX highlights, sky reflections, normal maps; glTF materials are read).

### [Audio](components/audio.md)

- [AudioListener](components/audio.md#audiolistener): The 'ears' for spatial audio, usually on the camera or player.
- [AudioSource](components/audio.md#audiosource): Plays a sound clip from the entity.

### [Camera](components/camera.md)

- [Camera](components/camera.md#camera): Renders the scene to the screen.

### [Core](components/core.md)

- [EntityInfo](components/core.md#entityinfo): Identity of an entity; present on every entity.
- [Transform](components/core.md#transform): Position, rotation and scale of an entity relative to its parent.

### [Physics](components/physics.md)

- [CharacterController3D](components/physics.md#charactercontroller3d): A walking character: a kinematic capsule that moves and slides. _Since 0.2.0._
- [Collider2D](components/physics.md#collider2d): Collision shape for 2D physics.
- [Collider3D](components/physics.md#collider3d): Collision shape for 3D physics: box, sphere, capsule, convex hull or triangle mesh.
- [Joint2D](components/physics.md#joint2d): A Box2D joint on this entity's body: revolute (a hinge / pendulum / wheel axle), distance (a rope or spring of fixed length), prismatic (a slider along an axis) or weld (glue two bodies together). _Since 0.2.0._
- [Joint3D](components/physics.md#joint3d): Joins this entity's RigidBody3D to another body or to the world: a hinge (door, pendulum, wheel), a ball joint (rope link, ragdoll shoulder) or a fixed joint (welds the two bodies). _Since 0.2.0._
- [NavLink3D](components/physics.md#navlink3d): An off-mesh link of the NavMesh3D: a jump across a gap, a climb up a ladder, a drop off a ledge. _Not released yet._
- [NavMesh3D](components/physics.md#navmesh3d): A navigation mesh for path finding on 3D ground. _Not released yet._
- [RigidBody2D](components/physics.md#rigidbody2d): Puts the entity under 2D physics (Box2D).
- [RigidBody3D](components/physics.md#rigidbody3d): Simple 3D physics body for arcade games (spheres, oriented boxes, capsules and convex hulls; a triangle-mesh collider is for static level geometry only).

### [Scene](components/scene.md)

- [SceneSettings](components/scene.md#scenesettings): Scene-wide settings stored under "settings" in the scene file: lighting, fog, gravity and background music.

### [Scripting](components/scripting.md)

- [Script](components/scripting.md#script): Attaches JavaScript behaviour to the entity.

### [UI](components/ui.md)

- [Button](components/ui.md#button): Clickable button with a text label. _Since 0.1.6._
- [Captions](components/ui.md#captions): The subtitles of the game (docs/TEXT.md, "Captions"): draws the lines that `audio.play(path, { caption })` and `ui.caption(text, seconds)` put on the caption list, the newest `maxLines` of them, at the bottom of this entity's rectangle on a background that hugs the text. _Since 0.2.0._
- [Panel](components/ui.md#panel): Container widget: a background rectangle (solid or 9-slice) whose children are laid out in a row, a column or a grid. _Since 0.1.6._
- [ScrollList](components/ui.md#scrolllist): Scrolling container: its children are stacked in a column (aligned left, packed at the top) at -scroll, and everything drawn by them and their descendants (widgets, Text, Sprite, Shape2D) is CLIPPED to the list's rectangle. _Since 0.1.6._
- [Slider](components/ui.md#slider): Horizontal value slider: label in the left 35% (when not empty), the track in the next 50% (85% without a label) with a fill and a knob in accentColor, the value in the last 15% (with labelAbove the label is above the track and the track gets the 85%). _Since 0.1.6._
- [TextField](components/ui.md#textfield): Single-line text input. _Since 0.1.6._
- [Toggle](components/ui.md#toggle): Check box with a label: a square box at the left (a filled inner square in accentColor when on) and the label to its right. _Since 0.1.6._
- [TouchButton](components/ui.md#touchbutton): On-screen button for phones and tablets (docs/MOBILE.md): a disc in `color` (darker while held) with an optional label. _Since 0.2.0._
- [TouchStick](components/ui.md#touchstick): On-screen analog stick for phones and tablets (docs/MOBILE.md): a disc in `color` with a knob that follows the finger. _Since 0.2.0._
- [Video](components/ui.md#video): A video on the screen (docs/MENUS.md, "Studio intro"): plays an .mpg file (MPEG-1 video with MP2 sound, the same decoder on every platform) in this entity's rectangle, the way an image fills a widget. _Not released yet._

## Commands

Every command is a CLI call (`factoria call <name> '<json>'`), an MCP tool (dots become underscores) and a script function (`fa.call(name, args)`). Commands of plugins (for example `steam.*`) and the project's own `tools/*.js` are not listed: they depend on the project.

### [ai](commands/ai.md)

- [`ai.models`](commands/ai.md#aimodels): List the models each AI provider offers (the values for roles.<role>.model).
- [`ai.providers`](commands/ai.md#aiproviders): List configured AI providers and roles, or diagnose which ones are usable (doctor).
- [`ai.run`](commands/ai.md#airun-modifies-state): Run an AI agent on a task in the current project (blocks until it finishes).

### [api](commands/api.md)

- [`api.commands`](commands/api.md#apicommands): Describe every registered command (name, summary, schema).
- [`api.components`](commands/api.md#apicomponents): Describe every component type: fields, kinds, defaults, docs.
- [`api.scripting`](commands/api.md#apiscripting): Machine-readable JavaScript API (modules, classes, functions) for gameplay scripts.

### [assets](commands/assets.md)

- [`assets.analyze_audio`](commands/assets.md#assetsanalyze_audio-modifies-state): Measure the loudness of a sound (or of every sound) and keep the result in assets.json. _Since 0.1.6._
- [`assets.disclosure`](commands/assets.md#assetsdisclosure): Write the AI-generated content disclosure for store forms (Steam) from the provenance records. _Since 0.1.6._
- [`assets.draw_capsules`](commands/assets.md#assetsdraw_capsules-modifies-state): Make the store page images (capsules, heroes, covers, screenshots) at each store's sizes from one piece of key art and a logo. _Since 0.2.0._
- [`assets.draw_icon`](commands/assets.md#assetsdraw_icon-modifies-state): Draw the game's icon (1024x1024 PNG) and the Android adaptive-icon foreground from shapes and text, no image provider needed. _Since 0.2.0._
- [`assets.generate_image`](commands/assets.md#assetsgenerate_image-modifies-state): Generate a PNG image with the image asset provider and record where it came from. _Since 0.1.6._
- [`assets.generate_model`](commands/assets.md#assetsgenerate_model-modifies-state): Generate a 3D model with the model3d asset provider and record where it came from. _Since 0.1.6._
- [`assets.generate_music`](commands/assets.md#assetsgenerate_music-modifies-state): Generate a music track with the music asset provider and record where it came from. _Since 0.1.6._
- [`assets.generate_sound`](commands/assets.md#assetsgenerate_sound-modifies-state): Generate a sound effect with the sound asset provider and record where it came from. _Since 0.1.6._
- [`assets.generate_sprite_sheet`](commands/assets.md#assetsgenerate_sprite_sheet-modifies-state): Generate a sprite sheet (a grid of animation frames) and record its layout for SpriteAnimator. _Since 0.1.6._
- [`assets.generate_voice`](commands/assets.md#assetsgenerate_voice-modifies-state): Generate spoken audio from text with the voice asset provider and record where it came from. _Since 0.1.6._
- [`assets.import`](commands/assets.md#assetsimport-modifies-state): Bring a file made elsewhere (Aseprite, PSD, OBJ, FBX, PNG, WAV, glTF, MP4...) into the project's assets/ folder and record where it came from. _Since 0.1.6._
- [`assets.list`](commands/assets.md#assetslist): List project asset files with type and size. Types: texture, audio, font, mesh, script, scene, prefab, material, other (by file name).
- [`assets.provenance`](commands/assets.md#assetsprovenance): Show where assets came from: the provenance record of one file, or all of them. _Since 0.1.6._
- [`assets.set_provenance`](commands/assets.md#assetsset_provenance-modifies-state): Record where an asset came from (hand-made, imported, or made with AI elsewhere). _Since 0.1.6._
- [`assets.slice_sheet`](commands/assets.md#assetsslice_sheet-modifies-state): Make an image playable by SpriteAnimator: check its frame grid, or find the frames of an uneven sheet and repack them. _Since 0.1.6._
- [`assets.synth_sound`](commands/assets.md#assetssynth_sound-modifies-state): Make a game sound (bark, growl, coin, jump, explosion...) offline from a preset: a deterministic WAV, no provider and no key. _Not released yet._

### [audio](commands/audio.md)

- [`audio.bus`](commands/audio.md#audiobus-modifies-state): Set a bus's volume and effects (low-pass, reverb, ducking), or read its state. _Not released yet._
- [`audio.log`](commands/audio.md#audiolog): List the sounds played so far (clip path, frame, volume, bus, source entity), oldest first.
- [`audio.snapshot`](commands/audio.md#audiosnapshot-modifies-state): Apply a named mixer snapshot from factoria.json, or list the snapshots. _Not released yet._

### [docs](commands/docs.md)

- [`docs.commands`](commands/docs.md#docscommands): Reference of every available command (tool) with arguments.
- [`docs.components`](commands/docs.md#docscomponents): Reference of every component and field (types, defaults, docs).
- [`docs.list`](commands/docs.md#docslist): List the engine documentation available offline.
- [`docs.read`](commands/docs.md#docsread): Read a documentation page (Markdown).
- [`docs.search`](commands/docs.md#docssearch): Search the documentation by keywords.
- [`docs.write_reference`](commands/docs.md#docswrite_reference-modifies-state): Write the browsable API reference pages (docs/reference/) and docs/COMPONENTS.md. _Since 0.2.0._

### [engine](commands/engine.md)

- [`engine.info`](commands/engine.md#engineinfo): Show engine version, platform, graphics backend and loop state.

### [feedback](commands/feedback.md)

- [`feedback.list`](commands/feedback.md#feedbacklist): List the engine-feedback entries recorded for this project.
- [`feedback.report`](commands/feedback.md#feedbackreport-modifies-state): Record an engine gap (missing feature, bug, confusing doc) and the workaround you used.
- [`feedback.update`](commands/feedback.md#feedbackupdate-modifies-state): Change the status of a feedback entry or link it to an engine issue.

### [fs](commands/fs.md)

- [`fs.delete`](commands/fs.md#fsdelete-modifies-state): Delete a file or folder from the project.
- [`fs.edit`](commands/fs.md#fsedit-modifies-state): Replace exact text in a file (must match exactly once unless replaceAll).
- [`fs.list`](commands/fs.md#fslist): List files and folders in the project.
- [`fs.read`](commands/fs.md#fsread): Read a text file (optionally a line range).
- [`fs.search`](commands/fs.md#fssearch): Search text in project files (substring or regex).
- [`fs.write`](commands/fs.md#fswrite-modifies-state): Create or overwrite a file (text, or binary via base64; parent folders are created).

### [game](commands/game.md)

- [`game.input`](commands/game.md#gameinput-modifies-state): Inject input: press/release actions or keys, or set an action state, mouse position/buttons, gamepad buttons/sticks, touches.
- [`game.logs`](commands/game.md#gamelogs): Read recent log lines (engine, scripts, assets...).
- [`game.pause`](commands/game.md#gamepause-modifies-state): Pause the simulation (frame() stops simulating; game.step still works).
- [`game.render_stats`](commands/game.md#gamerender_stats): What the renderer drew in the picture now: draw calls, triangles, lights, shadow casters, texture memory. _Not released yet._
- [`game.resume`](commands/game.md#gameresume-modifies-state): Resume the simulation after game.pause.
- [`game.screenshot`](commands/game.md#gamescreenshot): Capture the game view as a PNG and show it.
- [`game.state`](commands/game.md#gamestate): Dump the game state as JSON: entities, physics, script errors, recent warnings, render stats.
- [`game.step`](commands/game.md#gamestep-modifies-state): Advance the simulation by N fixed frames (deterministic) and return a state summary.

### [i18n](commands/i18n.md)

- [`i18n.export`](commands/i18n.md#i18nexport-modifies-state): Write the game's string tables as a spreadsheet (CSV) or XLIFF files for translators. _Since 0.2.0._
- [`i18n.import`](commands/i18n.md#i18nimport-modifies-state): Read a translator's CSV or XLIFF file back into locales/<language>.json. _Since 0.2.0._
- [`i18n.set_language`](commands/i18n.md#i18nset_language-modifies-state): Switch the game to another language now: every Text and widget with a key is rewritten at once. _Since 0.2.0._
- [`i18n.state`](commands/i18n.md#i18nstate): Show the languages of the game: which is current, which strings each lacks compared with the default language. _Since 0.2.0._

### [material](commands/material.md)

- [`material.info`](commands/material.md#materialinfo): Describe a custom material: lighting, alpha mode, params with types, defaults, ranges and docs, textures, programs and compile state. _Since 0.2.0._

### [physics](commands/physics.md)

- [`nav.bake`](commands/physics.md#navbake): Bake the NavMesh3D walkable grid from the static 3D colliders and return its stats. _Not released yet._
- [`nav.find_path`](commands/physics.md#navfind_path): Find a walkable path between two 3D points on the baked NavMesh3D. _Not released yet._
- [`nav.info`](commands/physics.md#navinfo): List the NavMesh3D components with their bounds, agent size, bake state and stats. _Not released yet._
- [`physics.raycast`](commands/physics.md#physicsraycast): Cast a ray against colliders (2D segment or 3D ray) and return the first hit.
- [`physics.shape_cast`](commands/physics.md#physicsshape_cast): Sweep a circle, sphere or box from one point to another and return the first collider it touches.

### [platform](commands/platform.md)

- [`platform.add_backend`](commands/platform.md#platformadd_backend-modifies-state): Set up a store backend for this game: its plugin, its build and what the store needs. _Since 0.2.0._
- [`platform.emit`](commands/platform.md#platformemit-modifies-state): Send an event to the game as the store would: a purchase, the overlay opening or closing, a sign-in change. _Since 0.2.0._
- [`platform.reset`](commands/platform.md#platformreset-modifies-state): Reset the fake platform backend: nothing unlocked, bought or saved, no scripted answers, signed in, an empty request log. _Since 0.2.0._
- [`platform.respond`](commands/platform.md#platformrespond-modifies-state): Script the next answer(s) the fake platform backend gives to a method: an error, an exact result, or a change to the default. _Since 0.2.0._
- [`platform.revoke`](commands/platform.md#platformrevoke-modifies-state): Take a purchase back in the fake platform backend, as a refund does, and send the game the event a real store would. _Not released yet._
- [`platform.set_ad`](commands/platform.md#platformset_ad-modifies-state): Script what the fake platform backend's test ad does: watched to the end, closed early, no ad to show, or consent refused. _Not released yet._
- [`platform.set_fake`](commands/platform.md#platformset_fake-modifies-state): Change how the fake platform backend behaves: signed in or out, and how many frames it holds its answers. _Since 0.2.0._
- [`platform.state`](commands/platform.md#platformstate): Show which platform backend runs, its services, the player, the declared ids and, for the fake backend, everything it holds. _Since 0.2.0._

### [play](commands/play.md)

- [`play.report`](commands/play.md#playreport): What happened while the user played: perf, spikes, warnings/errors, their problem marks and screenshots.
- [`play.sessions`](commands/play.md#playsessions): List the recent play sessions recorded by the editor (Play .. Stop), newest first.

### [project](commands/project.md)

- [`checkpoint.create`](commands/project.md#checkpointcreate-modifies-state): Save a checkpoint: a snapshot of every file of the project that checkpoint.restore can put back. _Since 0.2.0._
- [`checkpoint.diff`](commands/project.md#checkpointdiff): Show which files changed since a checkpoint (modified, added, deleted). _Since 0.2.0._
- [`checkpoint.list`](commands/project.md#checkpointlist): List the project's checkpoints, newest first. _Since 0.2.0._
- [`checkpoint.restore`](commands/project.md#checkpointrestore-modifies-state): Put the project's files back as they were at a checkpoint (the user's Revert); ask the user before calling it. _Since 0.2.0._
- [`perf.baseline`](commands/project.md#perfbaseline-modifies-state): Measure the game and write or refresh THIS runner's entry in its performance budget file (perf.json). _Since 0.2.0._
- [`perf.check`](commands/project.md#perfcheck): Measure the game and fail when it costs more than its performance budget (perf.json) allows on this runner. _Since 0.2.0._
- [`perf.measure`](commands/project.md#perfmeasure): Run the game headless for N frames and report its cost: CPU time per frame, peak memory, draw calls, entities, triangles, lights, texture memory. _Since 0.2.0._
- [`perf.profile`](commands/project.md#perfprofile): Run the game headless with the profiler on and report where the time goes: per engine system, per script behaviour class, GPU time, memory. _Since 0.2.0._
- [`project.add_menu_kit`](commands/project.md#projectadd_menu_kit-modifies-state): Copy the menu kit (main menu, options, pause, loading screen, ...) into the game and merge its strings into the locales. _Not released yet._
- [`project.create`](commands/project.md#projectcreate-modifies-state): Create a new game project from a template.
- [`project.export`](commands/project.md#projectexport-modifies-state): Package the game for a platform: a desktop bundle, an Android APK/AAB, an iOS project, or a web page (HTML5). _Since 0.1.2._
- [`project.info`](commands/project.md#projectinfo): Show the project settings, input actions, current scene, scenes and scripts.
- [`project.new_ci_workflow`](commands/project.md#projectnew_ci_workflow-modifies-state): Write a GitHub Actions workflow that validates, tests and exports the game on every push. _Since 0.2.0._
- [`project.new_plugin`](commands/project.md#projectnew_plugin-modifies-state): Create a native plugin (C/C++) for this game and declare it in factoria.json. _Since 0.1.6._
- [`project.templates`](commands/project.md#projecttemplates): List the project templates `project.create` can start from.
- [`project.test`](commands/project.md#projecttest-modifies-state): Run the project's JavaScript tests (tests/*.test.js) headless and return the report.
- [`project.validate`](commands/project.md#projectvalidate): Check the whole project for errors: project file, scenes, assets, input bindings, scripts, feedback file.

### [publish](commands/publish.md)

- [`publish.appstore`](commands/publish.md#publishappstore-modifies-state): Upload the iOS build (.ipa) or the Mac App Store package (.pkg) to App Store Connect (xcrun altool, macOS only). _Since 0.2.0._
- [`publish.epic`](commands/publish.md#publishepic-modifies-state): Upload the desktop exports to the Epic Games Store (BuildPatchTool UploadBinary, one artifact per platform). _Since 0.2.0._
- [`publish.gog`](commands/publish.md#publishgog-modifies-state): Upload the desktop exports to GOG (Galaxy Pipeline Builder build-game, one project file per platform). _Since 0.2.0._
- [`publish.googleplay`](commands/publish.md#publishgoogleplay-modifies-state): Upload the release Android App Bundle (.aab) to Google Play (fastlane supply). _Since 0.2.0._
- [`publish.itch`](commands/publish.md#publishitch-modifies-state): Upload the desktop exports to itch.io (butler push, one channel per platform). _Since 0.2.0._
- [`publish.microsoft`](commands/publish.md#publishmicrosoft-modifies-state): Upload the Windows MSIX package to the Microsoft Store (msstore publish). _Not released yet._
- [`publish.steam`](commands/publish.md#publishsteam-modifies-state): Upload the desktop exports to Steam (steamcmd, one depot per platform). _Since 0.2.0._

### [scene](commands/scene.md)

- [`prefab.save`](commands/scene.md#prefabsave-modifies-state): Save an entity of the running world, with its children, as a prefab file.
- [`scene.ascii_edit`](commands/scene.md#sceneascii_edit-modifies-state): Edit the ASCII map of a level file (a scene.import_ascii args file) with operations instead of rewriting rows, then rebuild the level. _Since 0.2.0._
- [`scene.destroy`](commands/scene.md#scenedestroy-modifies-state): Destroy an entity and its children.
- [`scene.format`](commands/scene.md#sceneformat-modifies-state): Rewrite scene and prefab files in the canonical compact layout, without loading them.
- [`scene.get_entity`](commands/scene.md#sceneget_entity): Get one entity with every component field (including defaults and runtime values).
- [`scene.import_ascii`](commands/scene.md#sceneimport_ascii-modifies-state): Build a Tilemap level and the objects standing on it (coins, enemies, spawn points) from ASCII rows and a legend.
- [`scene.list_entities`](commands/scene.md#scenelist_entities): List entities (id, name, tags, components) with optional filters.
- [`scene.load`](commands/scene.md#sceneload-modifies-state): Replace the running scene with a scene file.
- [`scene.reload`](commands/scene.md#scenereload-modifies-state): Reload the current scene from disk (discards runtime changes).
- [`scene.remove_component`](commands/scene.md#sceneremove_component-modifies-state): Remove a component from an entity.
- [`scene.save`](commands/scene.md#scenesave-modifies-state): Save the running world to a scene file (current scene path by default).
- [`scene.set_component`](commands/scene.md#sceneset_component-modifies-state): Add a component to an entity (if missing) and set the given fields.
- [`scene.set_parent`](commands/scene.md#sceneset_parent-modifies-state): Move an entity under another entity, or to the top level of the scene. _Since 0.2.0._
- [`scene.spawn`](commands/scene.md#scenespawn-modifies-state): Create an entity from entity JSON, or instantiate a prefab at a position.

### [screen](commands/screen.md)

- [`screen.set_safe_area`](commands/screen.md#screenset_safe_area-modifies-state): Pretend the device has a notch, rounded corners or system bars (a notched phone, headless). _Since 0.2.0._

### [script](commands/script.md)

- [`script.errors`](commands/script.md#scripterrors): List script errors (load/runtime) and scene load problems.
- [`script.eval`](commands/script.md#scripteval-modifies-state): Evaluate JavaScript in the running game context (REPL) and return the value.
- [`script.reload`](commands/script.md#scriptreload-modifies-state): Re-import script modules edited on disk and restart the behaviours (the world is kept).
- [`script.trace`](commands/script.md#scripttrace): Debug scripts: run the game headless and record the stack, locals and watch expressions each time chosen lines run. _Since 0.2.0._

### [setup](commands/setup.md)

- [`setup.install`](commands/setup.md#setupinstall-modifies-state): Install what an export needs: the Android JDK + SDK, the players of other platforms, CMake, the AppImage tools, sokol-shdc, the VS Code debugger extension, ffmpeg (or open Xcode's App Store page). _Since 0.1.4._
- [`setup.status`](commands/setup.md#setupstatus): Check what this computer has for exporting: the Android JDK and SDK, the players of other platforms, CMake, Xcode, the AppImage tools, sokol-shdc, the VS Code debugger extension, ffmpeg. _Since 0.1.4._

### [shader](commands/shader.md)

- [`shader.compile`](commands/shader.md#shadercompile): Compile a custom material's GLSL snippet for the dialects of some platforms and report errors with file, line and fixes. _Since 0.2.0._

### [sign](commands/sign.md)

- [`sign.macos`](commands/sign.md#signmacos-modifies-state): Sign, notarize and staple the exported macOS app (Developer ID), or sandbox and sign it as a .pkg for the Mac App Store. _Since 0.2.0._
- [`sign.windows`](commands/sign.md#signwindows-modifies-state): Sign the Windows MSIX package (and the exe) with a code-signing certificate, to install it outside the Microsoft Store. _Not released yet._

### [ui](commands/ui.md)

- [`ui.caption`](commands/ui.md#uicaption-modifies-state): Show a subtitle line on the Captions component for a few seconds. _Since 0.2.0._
- [`ui.check_layout`](commands/ui.md#uicheck_layout-modifies-state): Load each screen in each language and text size and list every text that overflows its box, overlaps another text or leaves the screen. _Since 0.2.0._
- [`ui.clear_captions`](commands/ui.md#uiclear_captions-modifies-state): Remove every subtitle from the screen now. _Since 0.2.0._
- [`ui.set_slider`](commands/ui.md#uiset_slider-modifies-state): Set a Slider the way a drag does: clamped, snapped to step, and ui.change is sent. _Not released yet._
- [`ui.set_text_scale`](commands/ui.md#uiset_text_scale-modifies-state): Set the text size option: screen-space Text and the labels of UI widgets get bigger or smaller. _Since 0.2.0._
- [`ui.speak`](commands/ui.md#uispeak-modifies-state): Say a line aloud with the system's text to speech (or record it, headless). _Since 0.2.0._
- [`ui.state`](commands/ui.md#uistate): List the UI widgets on screen (Panel, Button, Toggle, Slider, TextField, ScrollList, TouchStick, TouchButton, and screen-space Text) and which has focus. _Since 0.1.6._
- [`ui.stop_speaking`](commands/ui.md#uistop_speaking-modifies-state): Stop what is being said by ui.speak and drop the queued lines. _Since 0.2.0._

