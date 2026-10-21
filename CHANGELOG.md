# What's new in FactorIA

The editor shows these notes when it offers an update, and each release on GitHub uses its section. Newest first.

## Unreleased

Edit by hand in the editor

- The editor has a Hierarchy and an Inspector now. The Hierarchy lists every entity as a tree: click one to select it (a
  click in the game view selects it there too), drag it onto another to make it a child, drop it on the empty space to
  make it a top-level entity, and right-click for create child, duplicate, rename, active and delete. There is a search box.
- The Inspector shows the selected entity's components with a field for every value: tick boxes, number drags that
  respect each field's range, vectors, colour pickers, drop-downs for choices and for other entities, file pickers for
  pictures, sounds and materials, and a text box for free-form JSON. Hover a name to read what it does. Add Component and
  the x on a component's header add and remove components.
- Everything you change by hand goes through the same commands the AI uses, so Undo works (one drag is one step) and a
  value a field does not accept is refused with the reason. While the game plays you can edit the running game; Stop
  takes those edits back.
- A `MeshRenderer` shows its material's settings with the right widgets (sliders, vectors, colour pickers) and a Reset
  button for each, and a material that does not compile shows its error right under the material field.
- New command `scene.set_parent` moves an entity under another one (or to the top level), for the AI too.
- Move, rotate and scale in the game view: select something and drag the arrows (W), the rings (E) or the handles (R) that
  appear on it; Q goes back to just selecting. The four buttons next to Undo do the same. Hold Ctrl to snap, press Esc in
  the middle of a drag to cancel it. A whole drag is one Undo step, it works for 2D and 3D, for things on the screen (like
  a score) and for things inside another, and while the game is paused it edits the running game.
- Still to come: a browser for the project's files.

Find out what makes your game slow

- A profiler: it tells you where the time of a frame goes, per part of the engine (physics, scripts, sound, drawing...) and
  per script class, with the milliseconds each class takes per frame and how often it runs, plus the GPU time (on
  Windows and Linux; other systems say why not) and memory use. It only measures: your game plays exactly the same.
- In the editor, View > Profiler shows it live while you play. Every play session you record now also keeps this
  summary in `play.report`, so the AI can see which script is the slow one.
- `perf.profile` does the same on a headless run, with an optional input replay to reach the heavy part of the game. See
  `factoria docs read performance`.

Better looking 3D, and much bigger 3D scenes

- Materials look like real materials: `metallic` and `roughness` now use physically based shading, and shiny surfaces
  reflect the sky of your scene (`skyColor` and `horizonColor`), so a metal sphere looks like metal without any extra
  file. Scenes you already have look close to before, with a faint sheen on plastic and stone.
- Normal maps: give a `MeshRenderer` a `normalMap` picture to add bumps, scratches or bricks without extra triangles, and
  `normalScale` to make them stronger or softer.
- glTF models keep their materials: metallic and roughness (with their textures), normal maps, ambient occlusion and
  glowing parts are read from the file. Models without tangents get them generated.
- Big scenes are cheaper: anything outside the camera's view is skipped, and many copies of the same mesh with the same
  material are drawn together. Ten thousand identical cubes now cost one draw.
- Up to 32 lights at once instead of 8. With more, the engine keeps the sun and the brightest, nearest lights.
- The render statistics (`play.report`) now also count `meshesCulled`, `meshBatches` and `lightsDropped`.
- Your own shaders: a `MeshRenderer` can use a material file (`material`) with a few lines of GLSL that change how the
  surface looks (a pulsing glow, cut-out leaves, moving water) or move its vertices. Shadows follow the moved or cut-out
  shape, each entity can change the material's values (`materialParams`), and a change to the file shows up at once
  while the game runs. A material that does not compile draws magenta and says which line is wrong.
- A new guide for your own shaders (`factoria docs read shaders`): how to write a material, the rules for its few lines
  of GLSL, and five ready examples: a pulsing glow, dissolving, water, wind on grass and a rim light. The shader
  compiler comes with FactorIA, next to `factoria` in every download, so there is nothing to install. If Windows
  Defender removes `sokol-shdc.exe` by mistake, restore it from Windows Security > Protection history, or run
  `factoria setup shaders` to get it again.
- In the editor, saving a material, a shader or a texture updates the game view right away, while editing and while
  playing. A mistake in a shader keeps the last picture that worked and shows one error in the Console with the file
  and the line.
- The Gem Roller example has glowing, pulsing gems made with a custom material.
- Not yet: an environment picture for reflections.

Animation

- 3D models with skeletons: a glTF/GLB with named animation clips plays through the new `Animator` component, which goes on
  the entity with the model's `MeshRenderer`. Switch clips with a smooth cross-fade (`entity.animator.play("Run", 0.2)`),
  change the speed, and get an event when a clip reaches a moment you chose (a footstep at 0.3 s) with `world.on`.
- A small state machine is built in: list the parameters, the states (a clip each) and the transitions in the scene file
  (`"when": "speed > 0.1"`), then your script only sets values: `entity.animator.set("speed", 3)`. Animation runs in the
  fixed step, so tests and replays give the same result every time.
- New `tween` and `ease` in the scripting API: slide a menu in, fade a sprite, grow a pickup. Works on numbers, vectors
  and colors of anything, in 2D and 3D, with 30 easings (`"backOut"`, `"bounceOut"`...), delay, repeat, yoyo, chaining and
  `await tween(...).finished`.
- Animated models are drawn deformed by the animation, shadows included (up to 64 joints per model; a model with more
  is drawn in its bind pose and a warning says so). The new guide is `factoria docs read animation`.

3D physics: new shapes, joints and a character controller

- 3D colliders can now be capsules (`shape: "capsule"` with `radius` and `height`), convex shapes (`"convex"`, the
  smallest solid that wraps a model) and triangle meshes (`"mesh"`, the exact surface of a model, for terrain, ramps and
  level geometry). For the last two, set `Collider3D.mesh` to a primitive name or to your `.glb`/`.gltf` file, usually
  the same as the entity's `MeshRenderer.mesh`. All shapes collide with each other, and raycasts, shape casts, triggers,
  sleeping and the physics debug view work with all of them.
- A mesh collider is for things that never move. Put it on a body that moves and the engine tells you once, in plain
  words, to use a convex collider or several boxes and capsules instead.
- Joints: add a `Joint3D` to an entity that has a body to make a hinge (doors, pendulums, wheels, with optional angle
  limits and a motor), a ball joint (chains, shoulders) or a fixed joint, hanging from the world or from another body.
  A swinging pendulum keeps its real period.
- Character controller: add `CharacterController3D` to an entity and call `physics.moveCharacter(entity, delta)` each
  frame. It slides along walls, steps up stairs and kerbs (`stepOffset`), refuses slopes steeper than `slopeLimit`, stays
  on the ground going down a ramp, pushes crates, and tells you if it is on the ground (`isGrounded`, `groundNormal`).
  You add your own gravity and jump.
- Limits for now: a model with more than 256 vertices used as a convex collider is simplified to 256 points, jointed
  bodies never fall asleep, and the character is not carried by moving platforms.

More for 2D games

- Flipped and rotated tiles: a tile number can carry a flip or turn, so one picture serves four directions. In
  `scene.import_ascii` a legend entry accepts `flipX`, `flipY` and `rotate` (0, 90, 180, 270). Collision follows the
  plain tile number.
- 9-slice sprites: give a `Sprite` a `slice` (left, top, right, bottom in pixels of the picture) and it stretches like a
  button background, corners intact. It works with flips and with pictures packed in an atlas.
- 2D lights: a `Light2D` entity (point or directional) lights the sprites and tilemaps that set `lit`. Add a
  `normalMap` and the sprite shows bumps that react to the light. `SceneSettings.ambientLight` is the unlit brightness.
  Up to 16 lights at once; the nearest to the camera win.
- Parallax: a `Parallax` component makes a far background move slower than the camera (or faster, for foreground), and
  a sprite can repeat endlessly with `repeatX` / `repeatY`.
- Joints: a `Joint2D` on a body ties it to the world or another body as a hinge (revolute), rope (distance), slider
  (prismatic) or glue (weld), with limits, motors and springs. Scripts can read the reaction force and switch a motor.

Games in the browser

- Export your game for the web: `factoria export --platform web` (or Web in the editor's Export window) makes a folder
  with an `index.html` that plays the game in any modern browser, and a `.zip` of it ready to upload to itch.io as an
  HTML5 game. The page shows a loading bar and explains in plain words when something is wrong (an old browser, a
  download that failed).
- In the browser, saves made with `storage` are kept between visits, sound starts with the player's first click or key,
  and gamepads work. Native plugins and store services (achievements, purchases) are not available on the web.
- The web player comes with every FactorIA download; `factoria setup players --platforms web` installs it if you need it.

Phones and tablets

- Change to know about: `factoria export --platform android --release` now stops when your game has no signing key,
  because Google Play rejects an app signed with the debug key. The message tells you how to make a key. To try a release
  build on your own phone anyway, add `--allow-debug-key` (the export command's `allowDebugKey` option).
- Menus and heads-up displays can keep clear of the notch, rounded corners and system bars: switch on `safeArea` next to
  `anchor` on a sprite, text, shape, particle emitter or interface widget, and it is placed against the free part of the
  screen. Scripts can read it as `screen.safeArea`. You can try a notched phone without one with
  `screen.set_safe_area {"profile":"phone-portrait"}`.
- The Android Back button and gesture now reach your game as `input.onBack`: close a menu or go up one screen and the game
  stays open. If nothing handles it the game closes, as before.
- `input.vibrate()` makes a phone vibrate (a light tap on iPhones). Exported Android games include the permission for it.
- Android games can raise the on-screen keyboard for text fields and receive what is typed. Keyboards that compose words
  (predictive text, swipe typing, emoji, Asian languages) still cannot type into an Android game; physical keyboards work.
- An on-screen gamepad for games made for a controller: add a `TouchStick` and a few `TouchButton`s to a scene and players
  move with the thumb and press A, B... on the screen. They press the same gamepad buttons and stick a real controller
  does, so your game needs no other change. Several fingers work at once, the controls stay clear of the notch, and they
  only show while the player is using touch (they hide when a real controller or keyboard is used).
- Tests can press Back, fake a notch, check vibrations and touch the on-screen gamepad without a device.
- iPhone and iPad exports include the privacy file the App Store asks for (`PrivacyInfo.xcprivacy`), listing the few
  system features FactorIA uses and saying that nothing is collected or tracked. If your game or a plugin collects data,
  tracks players or uses more system features, add them under `export.ios.privacy` in `factoria.json`; mistakes in it are
  reported with the fix. The app also says it uses no special encryption, so App Store Connect stops asking at every
  upload (`export.ios.usesNonExemptEncryption` changes it).
- `factoria setup players --platforms mobile` now also downloads the iPhone and iPad libraries on Windows and Linux, so
  you can prepare an iOS project there without pointing at a macOS download. Building it still needs a Mac.
- The mobile guide lists what to answer in Google Play's Data safety form and in App Store Connect's App Privacy section.

Upload your phone builds

- Upload your iOS build to TestFlight and App Store Connect from your AI or the command line (`publish.appstore`,
  on a Mac): you archive the game in Xcode as before, FactorIA sends the `.ipa` with an App Store Connect API key. Run it
  with `dryRun` first to see the exact command.
- Upload your Android release bundle to Google Play (`publish.googleplay`, needs fastlane): pick the track (internal
  testing by default), leave the release as a draft or roll it out, and send the "What's new" text per language from
  files of your project. A bundle signed with the debug key is refused before anything is sent. Google Play still wants the
  first bundle of a new app uploaded by hand.
- Your keys stay in files outside the project and are never shown or logged.

A complete example game

- Lantern Keep (`examples/lantern-keep`) is a small but complete 2D platformer, made the way your AI makes a game: six
  levels, menus, three save slots with a level select and cloud saves, achievements, leaderboards and a shop of cosmetics
  on the test store, accessibility options (text size, a slower game, invincibility, no screen shake), four languages
  including Arabic, an on-screen gamepad for phones and export settings ready for the stores. Read it, copy from it, or
  point your AI at it. Its `SHIPPING.md` lists what each store needs and what is still done by hand.

Guides for finishing and publishing

- `factoria docs read finishing` takes a game that plays to a game a store accepts, step by step with Lantern Keep's
  code: menus, options that stay set, saves that survive updates, languages, accessibility, credits and tests.
- `factoria docs read publishing` has one checklist per store (Steam, Epic, GOG, Microsoft Store, Google Play, App
  Store, itch.io, your own site): what FactorIA does for you and what you still do by hand, with fees and review times.
- Store images and trailers: `assets.draw_capsules` makes every picture a store page asks for (Steam capsules, Epic,
  GOG, Microsoft Store, Google Play, App Store screenshots, the itch.io cover) from one picture of your game and your
  logo or title. `factoria run --headless --input replay.json --record-video trailer.avi` records a trailer from an
  input replay, with sound; ask for `trailer.mp4` when ffmpeg is installed.

Learn FactorIA

- Two tutorials for people. `factoria docs read first-game-with-ai` makes your first game with the editor and an AI in
  six rounds, starting from the 2D platformer template: what to type, what to look for and how to undo.
  `factoria docs read make-by-hand` builds a small game by hand from the empty template (collect four gems, then a "You
  win!" screen), one whole file at a time, with a check after each step.
- What a game costs to make with AI: `factoria docs read ai-costs` shows what a complete game cost in a real run, what
  makes a run cheap or expensive, how to set a spending limit and where to see what you spent.
- A browsable API reference in the FactorIA repository: `docs/reference/` has an index of every component and command,
  one page per category, and the version that added each one.
- Searching the docs (`factoria docs search`, and your AI over MCP) shows the best section of each guide first, so a
  name like `onTriggerEnter` finds the scripting reference instead of many sections of one tutorial.

Accessibility, speed checks and legal texts

- Colour filters for players: `colorFilter` on the `Camera` turns the whole picture greyscale, raises the contrast, or
  corrects the colours for players who cannot tell red from green (`protanopia`, `deuteranopia`) or blue from yellow
  (`tritanopia`). Your options screen sets it from the player's choice.
- See your game as a colour-blind player does: `factoria run --headless --screenshot-at 60 --screenshot-simulate
  deuteranopia` (or `simulate` in `game.screenshot`) saves the screenshot that way without changing the game, so you or
  your AI can check that hazards still stand out.
- Read menus aloud: `ui.speak(text)` says a line with the computer's or phone's own voice, in the game's language, and
  `ui.speechAvailable` tells whether the system can speak. Speak the button that has the focus and players who cannot
  read the screen can use your menus. Tests check what would be said with `game.spoken()`, without sound.
- Start from the player's own settings: `game.accessibility` tells you the text size the player set on their system,
  and whether they asked for less motion, high contrast or use a screen reader. Use it to set your options on the first
  run; what the player then chooses in your game wins.
- Subtitles: add a `Captions` entity to your scene, then `audio.play("voice.wav", { caption: "Watch out!" })` shows the
  line while the sound plays, and `ui.caption(text)` shows one with no sound. They follow the text size and the player's
  language, and an option can turn them off. Tests list them with `game.captions()`.
- `factoria docs read menus` shows each of these as an option of the ready-made menus, and the accessibility part of
  `factoria docs read finishing` lists them all.
- Speed and memory checks: `factoria call perf.baseline` measures how much CPU time and memory your game uses and how
  many things it draws, and saves it in `perf.json`. `factoria call perf.check` then fails when the game got much
  heavier, so you notice before your players do. `factoria docs read performance` explains how to use it in your own
  checks.
- Privacy policy and license: `factoria docs read legal` says what FactorIA sends from your game (nothing by itself),
  gives a privacy policy you can copy for a game that collects nothing, the paragraphs to add when you use analytics,
  ads, accounts or cloud saves, and when you need a license agreement of your own. It is not legal advice.

Fixed while making Lantern Keep

Lantern Keep showed what a complete game still had to work around. These are now in the engine, so your AI writes less
code of its own:

- Menus fit their texts: `autoSize` on `Button`, `Toggle` and `Slider` grows the widget to its label at a big text
  size or in a longer language. A button label with several lines is centred line by line, `maxWidth` wraps it, and a
  label that still does not fit is cut at the button's edge. `ScrollList.fill` lets a list take the height the rest of a
  column leaves, and a fitted panel bigger than the screen logs a warning naming it.
- Scripts can apply the layout right away: `ui.layout()` sizes and places the widgets at once, so a script that changes
  a text can read the real sizes (`Button.size`, `Panel.size`, `ui.rectOf`) straight after, without waiting for the next
  frame.
- Panels that do not fit: `fallbackLayout` (row, column or grid) is used instead of `layout` when the panel would leave
  the screen, for example a column that becomes a row at a big text size. `uniformSize` makes the `autoSize` buttons,
  toggles and sliders in a panel all as wide as the widest one and as tall as the tallest one.
- Right-to-left languages: a `Text` with `align: "start"` or `"end"` follows the language's direction, and a panel with
  `direction: "auto"` lays out its rows right to left in Arabic or Hebrew. Scripts read `i18n.direction`.
- Panels: a script hook `onEnable()` runs every time an entity is shown and `onDisable()` every time it is hidden, before
  the frame is drawn, so a panel never shows its placeholder texts for a frame. A hidden panel already has its
  `.behaviour`.
- Focus with a gamepad or the keyboard goes to the widget you expect in the direction you press, and a greyed-out
  `autoFocus` button no longer keeps the focus.
- 2D: a moving platform carries the bodies standing on it, also when the player's script sets its speed every frame
  (that speed is now relative to the platform; drop any carry code of your own). `Shape2D.lit` lets the placeholder
  shapes be lit by `Light2D`.
- ASCII levels: `scene.import_ascii` keeps prefabs as references, so editing a prefab changes every level without
  importing the maps again, and level files stay small. Several maps can share one legend file (`legendFrom`).
- Scripts: vectors and colours work like small arrays (`const [x, y] = position`, `position[0]`, `...color`), reading
  `game.screenSize` is about 60 times faster, and a promise rejection you handle a moment later is no longer reported.
  Unpausing the game keeps the speed you set in `time.scale`.
- Saves: a save file is written in one go, so a crash cannot leave half a file. A save file that does not load is kept
  as `storage.corrupt.json` instead of being overwritten, and `storage.corrupt` tells your game.
- Store texts can be translated: achievements and products in `factoria.json` can name a key of your `locales` files
  (`nameKey`, `descriptionKey`, `titleKey`), and the game lists them in the player's language.
- Tests: `factoria test tests/saves.test.js` runs one test file (or several, or a pattern). `game.click("playButton")`
  presses a widget by its id, `ui.rectOf` gives where a widget is on screen, `expect(x).toMatchObject({...})` checks
  some fields of an object, `game.platform.set({ backend: "none" })` tests the game as on a store-less build, and a
  "not a function" error shows the line with a mark under the call.
- Exports: `export.exclude` in `factoria.json` leaves folders out of every export (`"store/**"`). A publish dry run
  works before the store's upload tool is installed and lists what is missing. The exported game takes `--frames 120` to
  run a few frames and exit, as a quick check in CI. `factoria validate` warns about pictures phones cannot compress, and
  new projects keep `build/` out of git.
- The export guide (`factoria docs read exporting`) has one table of what each export needs (downloads, Android tools,
  Xcode) and whether your computer can make it at all, offline or after a download. A new Microsoft Store section says
  what FactorIA covers and what you still do by hand.
- A game icon without an image service: `assets.draw_icon` draws your icon and the Android icon from shapes, colours and
  text, so you need no paid picture provider and no Python.
- Store screenshots at full size: `game.screenshot` takes a `scale` (so does `factoria run --render-scale`), so a
  1280x720 game makes sharp 1920x1080 pictures instead of enlarged ones. The HUD and the visible area stay the same.
- `i18n.import` for a new language keeps the shape of your main language file, and `factoria docs read` prints clean
  text on Windows.
- The reference (`factoria api`, `docs/COMPONENTS.md`, the MCP tool list) now says which version added each component,
  field and command, and marks with "Not released yet" what is only on the main branch, so you can tell what your
  installed FactorIA has.
- Editing an ASCII level no longer means counting characters: `scene.ascii_edit` changes the map file of a level with
  operations (fill a rectangle, replace a glyph, insert or delete columns, put a coin "2 tiles above the ground" of
  column 40), rewrites only the rows and rebuilds the level, and tells you where every object ended up.
- On Windows, deleting a folder that holds files with very long paths (a macOS export nests four folders) now deletes
  all of it: exporting again into the same folder, `fs.delete` and deleting a project from the editor no longer leave
  old files behind.

## 0.1.6

Menus and on-screen interface

- New interface pieces for your game: buttons, toggles, sliders, text fields, scrolling lists and panels with
  stretchable backgrounds, laid out in rows, columns or grids. Players use them with the mouse, the keyboard or a
  gamepad.
- Scripts can switch to full screen, change the window size, vsync and frame-rate cap, let players remap the controls,
  show the right button names for their gamepad, take typed text, and show or hide the cursor.
- A menus guide your AI follows to build a main menu, options, a pause menu, credits and a loading screen when your game
  needs them. New projects still start empty.
- Pausing really pauses now: physics, particles and animations stop too, while a pause menu keeps working.

Art, sound and music made by AI

- Your AI can generate images, sprite sheets, sound effects, music, voices and 3D models with the providers you set up
  (OpenAI, ElevenLabs, Meshy), keeping one style and colour palette across a game.
- Every generated or imported file remembers where it came from, and exports include `AI_CONTENT_DISCLOSURE.md` with
  the answers Steam asks about AI-generated content.
- Import Aseprite, Photoshop (PSD), OBJ and FBX files (FBX needs Blender or FBX2glTF installed), and cut sprite sheets
  into frames automatically.
- Lighter games: textures are compressed for each platform and packed into atlases, long music streams instead of
  loading whole into memory, and sounds can be evened out to the same loudness.
- `factoria validate` warns about images that are too big, sounds that clip or are too quiet, and games over a store's
  size limit.

Native plugins

- A game can bring its own native code as a plugin (C or C++ on desktop, Java or Kotlin on Android, libraries on iOS)
  without changing the engine. Plugins can live outside the game's folder, for SDKs you are not allowed to share.

## 0.1.5

- Exported Windows games open without a black console window, and the `.exe` carries your game's name and version
  (Properties in File Explorer shows them).
- Every run of a game writes a `log.txt` in the game's save folder, so a player can send it to you when something goes
  wrong.
- Exporting no longer fails on Windows when the output folder is deep enough to make paths longer than 260 characters.
- When a text uses characters its font does not have (Chinese, Japanese or Korean with the default font, for example),
  the log says which characters are missing and which font has them, instead of leaving the text blank without a word.
- When a command fails, your AI assistant always gets an error it can read and act on.

## 0.1.4

- Android: export your game as an APK to test or an AAB for Google Play, signed with your own key, with its icon.
- New Export window in the editor, with a button per platform and the settings each one needs (name, version, icons).
  What an export still lacks (Android SDK, players for another system) is installed in one click, or with
  `factoria setup` from a terminal.
- macOS: FactorIA is signed and notarized by Apple, so it opens without a security warning.
- iPhone, iPad and Apple Silicon Macs: touches and clicks land where they should, and games run on real devices.
- Android: a game you leave and open again starts correctly.
- The editor's title shows the FactorIA version and the open project.
- Exporting again only replaces a folder an earlier export made, never a folder of yours.
- Scripts: a warning when a method looks like a misspelled event name (for example `onUpdat`), which would otherwise
  never be called.
- License: FactorIA is MIT and the templates are MIT-0, so your game's code is yours to license as you like. Exported
  games include the license notices they need (`FACTORIA_NOTICES.txt`).

## 0.1.3

- Windows installer: installs for your user without an administrator prompt, adds FactorIA to the Start menu and
  makes `factoria` work in any terminal.
- Linux: a single-file AppImage, besides the `.tar.gz`. macOS: one download for Apple Silicon and Intel.
- Android and iOS export work straight from the download: you no longer need the engine's source code.
- Gamepads: hundreds more models are recognised on Linux, and on Android an unplugged pad frees its slot.
- 3D physics: balls roll and spin naturally when hit off-centre, resting bodies sleep and wake like in 2D, and fast
  objects no longer pass through walls.

## 0.1.2

- Editor: fixes in the AI chat, and projects can be deleted from the project list.
- Destroying an object also removes its physics body.
- Your AI assistant can export the game by itself.
- Screenshots taken by tests always show a complete, up-to-date frame.

## 0.1.1

- Editor: Ctrl+C and Ctrl+V work.

## 0.1.0

The first release of FactorIA, a 2D and 3D game engine made for an AI to build your game.

- Games are plain text (scenes in JSON, logic in JavaScript), so an AI can read and change every part of them, check
  its work and run tests.
- The editor is built around an AI chat: send pictures as references, keep several chats with their history, see how
  much of your plan you have used, and choose the model for each AI role.
- Templates to start from: a 2D platformer, an empty 2D game and an empty 3D game.
- 2D and 3D physics, gamepads, and play sessions that can be replayed exactly, with a report your AI can read.
- Downloads for Windows, macOS and Linux. The editor offers each new version and updates itself when you say so.
