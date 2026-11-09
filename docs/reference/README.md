# API reference

Every component and every command of FactorIA, one page per category. The pages are generated from the engine itself (`factoria call docs.write_reference '{"out":"docs"}'`), so they are exact for this version; a test fails when they fall behind. The same data is available offline with `factoria api --md`, `factoria commands` and, over MCP, `docs_components` and `docs_commands`. Use your browser's find (Ctrl+F) on this page to locate anything.

Version marks: an entry added after 0.1.0 ends with "(Since 0.1.x)", and "(Not released yet ...)" means it is only on the main branch, in no download. Nothing is shown for what existed in 0.1.0. If your factoria is older than a mark, that item is missing there (`factoria --version`).

## Components

### [2D](components/2d.md)

- [Bone2D](components/2d.md#bone2d): A bone of a 2D skeleton, on a plain entity of the hierarchy (docs/ANIMATION.md, "Bones and IK"). _Since 0.7.0._
- [IK2D](components/2d.md#ik2d): Inverse kinematics for a chain of Bone2D entities: put it on the LAST bone (the hand, the foot) and name a `target`; every fixed step, after the animators have posed the bones and before the frame is drawn, the bones from this one up through its parents are turned so the tip of this bone reaches the target entity's position, within each bone's minAngle / maxAngle. _Since 0.7.0._
- [Light2D](components/2d.md#light2d): A light for lit 2D visuals: sprites, shapes and tilemaps with `lit` true. _Since 0.2.0._
- [Parallax](components/2d.md#parallax): Shifts the drawing of this entity's world-space visuals (Sprite, Shape2D, Text, Tilemap) with the camera so far layers slide slower than near ones. _Since 0.2.0._
- [ParticleEmitter](components/2d.md#particleemitter): Emits short-lived particles (smoke, sparks, explosions, fire, trails).
- [Shape2D](components/2d.md#shape2d): Untextured 2D primitive for prototypes, UI panels and debug visuals.
- [Sprite](components/2d.md#sprite): Draws a textured (or solid color) quad.
- [SpriteAnimator](components/2d.md#spriteanimator): Flipbook animation over a grid sprite sheet.
- [SpriteSkin](components/2d.md#spriteskin): Deforms the Sprite on the same entity with bones (docs/ANIMATION.md, "Bones and IK"): each vertex of the sprite's 2D mesh follows up to 4 bones, so one picture bends at an elbow or a tail without cutting it in pieces. _Since 0.7.0._
- [Text](components/2d.md#text): Draws a string with a TrueType font (or the built-in font).
- [Tilemap](components/2d.md#tilemap): A grid of tiles drawn from a tileset texture; tile index -1 is empty.
- [Tint](components/2d.md#tint): Multiplies a colour (and an opacity) into every 2D visual of this entity and of all its children, grandchildren and so on: Sprite, Shape2D, Text (glyph colours and rich-text colours too), Tilemap, ParticleEmitter, and the screen-space UI widgets (Panel, Button, Toggle, Slider, TextField, ScrollList, the touch controls, Video, CameraView, Chart, Captions) drawn by the renderer. _Since 0.4.0._
- [Vfx](components/2d.md#vfx): A visual effect placed in the scene, like a prefab (docs/PARTICLES.md, "Effect documents"): plays the effect document `effect` (a *.vfx.json that bundles emitters, a light flash, sounds and commands such as a camera shake on one timeline). _Since 0.17.0._

### [3D](components/3d.md)

- [Animator](components/3d.md#animator): Plays animation clips: the skeletal clips of a skinned glTF model (the model of the MeshRenderer on the same entity, or `model`), or, when there is no glTF model, the keyframed 2D clips of `clips` (*.anim.json files that animate fields of this entity and its children: position, rotation.z, color.a, Sprite.region...). _Since 0.2.0._
- [IK3D](components/3d.md#ik3d): 3D inverse kinematics on the skinned model of the Animator on the same entity (docs/ANIMATION.md, "3D IK"). _Since 0.16.0._
- [Light](components/3d.md#light): A light source for 3D meshes.
- [MeshRenderer](components/3d.md#meshrenderer): Draws a 3D mesh with a PBR material (GGX highlights, sky reflections, normal maps; glTF materials are read).

### [Audio](components/audio.md)

- [AudioListener](components/audio.md#audiolistener): The 'ears' for spatial audio, usually on the camera or player.
- [AudioSource](components/audio.md#audiosource): Plays a sound clip from the entity.
- [MusicPlayer](components/audio.md#musicplayer): Plays a song document (*.song.json, docs/MUSIC.md) as adaptive music. _Since 0.16.0._

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
- [NavLink3D](components/physics.md#navlink3d): An off-mesh link of the NavMesh3D: a jump across a gap, a climb up a ladder, a drop off a ledge. _Since 0.3.0._
- [NavMesh3D](components/physics.md#navmesh3d): A navigation mesh for path finding on 3D ground. _Since 0.3.0._
- [RigidBody2D](components/physics.md#rigidbody2d): Puts the entity under 2D physics (Box2D).
- [RigidBody3D](components/physics.md#rigidbody3d): Simple 3D physics body for arcade games (spheres, oriented boxes, capsules and convex hulls; a triangle-mesh collider is for static level geometry only).

### [Scene](components/scene.md)

- [SceneSettings](components/scene.md#scenesettings): Scene-wide settings stored under "settings" in the scene file: lighting, fog, gravity and background music.

### [Scripting](components/scripting.md)

- [Script](components/scripting.md#script): Attaches JavaScript behaviour to the entity.

### [UI](components/ui.md)

- [Button](components/ui.md#button): Clickable button with a text label. _Since 0.1.6._
- [CameraView](components/ui.md#cameraview): A 3D (or 2D) view inside the UI (docs/MENUS.md, "A camera inside the UI"): draws the camera named by `camera` into this entity's rectangle, so an item turning on a stage, a character portrait or a map lives in a menu with the clipping of a ScrollList, the `layer` order, the right-to-left mirroring and the modal Panel of any widget. _Since 0.3.0._
- [Captions](components/ui.md#captions): The subtitles of the game (docs/TEXT.md, "Captions"): draws the lines that `audio.play(path, { caption })` and `ui.caption(text, seconds)` put on the caption list, the newest `maxLines` of them, at the bottom of this entity's rectangle on a background that hugs the text. _Since 0.2.0._
- [Chart](components/ui.md#chart): A bar or line chart (docs/MENUS.md, "Charts"): draws `values` as bars or lines inside this entity's rectangle, scaled to the axis, in one batch by the UI layer, with a baseline rule, the axis maximum and minimum written in the current language's number format, and optional vertical `marks`. _Since 0.3.0._
- [Interactable](components/ui.md#interactable): Makes this entity, whatever it is made of (sprites, shapes, text, children), a widget that joins the same focus, navigation and events as Button, Toggle and Slider: hover, press, click, focus, the arrow keys / d-pad (spatial navigation), ui_next / ui_previous (Tab), ui_submit / ui_cancel, Panel.modal scopes, game.click, ui.widgetAt and the ui.* commands find it by id. _Since 0.4.0._
- [InteractableVisual](components/ui.md#interactablevisual): Makes this entity follow the state of an Interactable with no script. _Since 0.4.0._
- [Panel](components/ui.md#panel): Container widget: a background rectangle (solid or 9-slice) whose children are laid out in a row, a column or a grid. _Since 0.1.6._
- [ScrollList](components/ui.md#scrolllist): Scrolling container: its children are stacked in a column (aligned left, packed at the top) at -scroll, and everything drawn by them and their descendants (widgets, Text, Sprite, Shape2D) is CLIPPED to the list's rectangle. _Since 0.1.6._
- [Slider](components/ui.md#slider): Horizontal value slider: label in the left 35% (when not empty), the track in the next 50% (85% without a label) with a fill and a knob in accentColor, the value in the last 15% (with labelAbove the label is above the track and the track gets the 85%). _Since 0.1.6._
- [TextField](components/ui.md#textfield): Single-line text input. _Since 0.1.6._
- [Toggle](components/ui.md#toggle): Check box with a label: a square box at the left (a filled inner square in accentColor when on) and the label to its right. _Since 0.1.6._
- [TouchButton](components/ui.md#touchbutton): On-screen button for phones and tablets (docs/MOBILE.md): a disc in `color` (darker while held) with an optional label. _Since 0.2.0._
- [TouchStick](components/ui.md#touchstick): On-screen analog stick for phones and tablets (docs/MOBILE.md): a disc in `color` with a knob that follows the finger. _Since 0.2.0._
- [Video](components/ui.md#video): A video on the screen (docs/MENUS.md, "Studio intro"): plays an .mpg file (MPEG-1 video with MP2 sound, the same decoder on every platform) in this entity's rectangle, the way an image fills a widget. _Since 0.3.0._

## Commands

Every command is a CLI call (`factoria call <name> '<json>'`), an MCP tool (dots become underscores) and a script function (`fa.call(name, args)`). Commands of plugins (for example `steam.*`) and the project's own `tools/*.js` are not listed: they depend on the project.

### [ai](commands/ai.md)

- [`ai.extensions`](commands/ai.md#aiextensions): Show the extensions (plugins, skills, hooks) AI runs load, per role, and what stops one from loading. _Since 0.11.0._
- [`ai.hooks`](commands/ai.md#aihooks): List the hooks (programs and JavaScript modules run on events) and the recent runs of every hook. _Since 0.11.0._
- [`ai.hooks_test`](commands/ai.md#aihooks_test): Run the configured hooks of one event with a sample input and show what they decide. _Since 0.11.0._
- [`ai.models`](commands/ai.md#aimodels): List the models each AI provider offers (the values for roles.<role>.model).
- [`ai.plugin_install`](commands/ai.md#aiplugin_install-modifies-state): Install a Claude Code marketplace plugin (the user's action) and add it to ai.json extensions. _Since 0.11.0._
- [`ai.providers`](commands/ai.md#aiproviders): List configured AI providers and roles, or diagnose which ones are usable (doctor).
- [`ai.retrospective`](commands/ai.md#airetrospective-modifies-state): Look back at this project's recorded AI runs, find where they wasted steps, minutes or tokens and file at most three efficiency entries. _Since 0.17.0._
- [`ai.review`](commands/ai.md#aireview-modifies-state): Ask the art critics (kind art) or the game reviewers (kind game) for their opinion and a score (blocks until done). _Since 0.4.0._
- [`ai.review_feedback`](commands/ai.md#aireview_feedback-modifies-state): Check an ENGINE_FEEDBACK.json entry's `share` text before it can be shared: a real gap, about the engine, not possible yet. _Since 0.10.0._
- [`ai.reviews`](commands/ai.md#aireviews): List the saved reviews of the art critics and the game reviewers, newest first, with their scores. _Since 0.4.0._
- [`ai.run`](commands/ai.md#airun-modifies-state): Run an AI agent on a task in the current project (blocks until it finishes).
- [`ai.saver_fact`](commands/ai.md#aisaver_fact-modifies-state): Accept or decline a proposed project fact: one line added to the project's AGENTS.md. _Since 0.11.0._
- [`ai.saver_group`](commands/ai.md#aisaver_group-modifies-state): Accept or decline a proposed tool group for this project (loaded in full up front from the next run). _Since 0.11.0._
- [`ai.savers`](commands/ai.md#aisavers): Show the engine's token savers (loop guard, learned tool groups, project facts), what this project's runs learned and the proposals waiting for an answer. _Since 0.11.0._
- [`ai.session_timeline`](commands/ai.md#aisession_timeline): Show where the time of a recorded AI session went: the long gaps and what was going on in each. _Since 0.9.0._
- [`ai.settings.get`](commands/ai.md#aisettingsget): Show the AI settings (roles, limits, assets, savers, tool servers, extensions) with where each value comes from: this project, your defaults or the engine. _Since 0.17.0._
- [`ai.settings.set`](commands/ai.md#aisettingsset-modifies-state): Change one AI setting of this project; a project change waits for the user to accept it in the editor. Your own defaults (scope user) only the user changes. _Since 0.17.0._
- [`ai.tool_plan`](commands/ai.md#aitool_plan): Show which commands the built-in AI agent of a role gets as tools in full and which only as catalog lines. _Since 0.11.0._
- [`ai.tool_servers`](commands/ai.md#aitool_servers): List the external tool servers (MCP) the user configured in ai.json, and optionally test them. _Since 0.8.0._

### [anim](commands/anim.md)

- [`anim.add_event`](commands/anim.md#animadd_event-modifies-state): Add an event to a clip: a game event and/or game feel actions run when the clip passes its time. _Since 0.7.0._
- [`anim.add_track`](commands/anim.md#animadd_track-modifies-state): Add a track to a clip, with keys or the part's current value as its first key. _Since 0.7.0._
- [`anim.check`](commands/anim.md#animcheck-modifies-state): Find what is wrong with a clip, and with how it fits its character. _Since 0.7.0._
- [`anim.create_clip`](commands/anim.md#animcreate_clip-modifies-state): Write a new keyframed 2D clip file (*.anim.json). _Since 0.7.0._
- [`anim.filmstrip`](commands/anim.md#animfilmstrip): One picture with a grid of a clip's poses, to see the whole motion at once. _Since 0.7.0._
- [`anim.list`](commands/anim.md#animlist): List the 2D clips of an entity's Animator (or of a clip file): tracks, events, layers and the current state. _Since 0.7.0._
- [`anim.move_event`](commands/anim.md#animmove_event-modifies-state): Move an event of a clip to another time. _Since 0.7.0._
- [`anim.move_keys`](commands/anim.md#animmove_keys-modifies-state): Move and scale a selection of keys in time. _Since 0.7.0._
- [`anim.pose`](commands/anim.md#animpose-modifies-state): Pose an entity as one of its clips is at a time, and leave it there. _Since 0.7.0._
- [`anim.remove_event`](commands/anim.md#animremove_event-modifies-state): Remove an event from a clip. _Since 0.7.0._
- [`anim.remove_keys`](commands/anim.md#animremove_keys-modifies-state): Remove keys of one track of a clip, by time or all of them. _Since 0.7.0._
- [`anim.remove_track`](commands/anim.md#animremove_track-modifies-state): Remove a whole track (all its keys) from a clip. _Since 0.7.0._
- [`anim.restore`](commands/anim.md#animrestore-modifies-state): Put a clip file back to a whole document, or delete it: the undo and redo of the anim.* edits. _Since 0.7.0._
- [`anim.set_clip`](commands/anim.md#animset_clip-modifies-state): Set the duration, loop or description of a clip. _Since 0.7.0._
- [`anim.set_event`](commands/anim.md#animset_event-modifies-state): Rename an event of a clip, or replace its data or its game feel actions. _Since 0.7.0._
- [`anim.set_interp`](commands/anim.md#animset_interp-modifies-state): Set how selected keys reach the next key: interp or easing, and bezier tangents. _Since 0.7.0._
- [`anim.set_keys`](commands/anim.md#animset_keys-modifies-state): Add or replace keys of one track of a clip, creating the track if it is missing. _Since 0.7.0._
- [`anim3d.add_event`](commands/anim.md#anim3dadd_event): Add an event to a 3D clip: a game event and/or game feel actions the Animator runs when the clip passes its time. _Since 0.16.0._
- [`anim3d.create`](commands/anim.md#anim3dcreate): Write a new, empty 3D bone clip (*.anim.json, format factoria.anim3d/1) for a skinned rig; add tracks with anim3d.set_keys. _Since 0.16.0._
- [`anim3d.generate`](commands/anim.md#anim3dgenerate): Generate a 3D bone clip for a baked rig from parameters: walk and run (stride, cadence, bounce, arm swing), quadruped trot and gallop, idle breathing, swings of tails and chains, hit reactions. Planted feet do not slide. _Since 0.16.0._
- [`anim3d.generators`](commands/anim.md#anim3dgenerators): List the clip generators of anim3d.generate (walk, run, trot, gallop, idle, swing, hit) with their parameters, ranges and defaults. _Since 0.16.0._
- [`anim3d.info`](commands/anim.md#anim3dinfo): Describe a 3D bone clip (duration, tracks, events, contacts, how it was generated) and, with `rig`, check its bones against a baked rig; with no `path`, list the 3D clips of the project. _Since 0.16.0._
- [`anim3d.mirror_pose`](commands/anim.md#anim3dmirror_pose): Key the left/right mirror of a 3D clip's pose at a time: swap both sides, or copy one side onto the other (bones are paired by canonical name: thigh_l <-> thigh_r). _Since 0.16.0._
- [`anim3d.move_keys`](commands/anim.md#anim3dmove_keys): Move keys of a 3D clip in time by dt seconds (a dopesheet drag); a moved key replaces the key it lands on. _Since 0.16.0._
- [`anim3d.preview`](commands/anim.md#anim3dpreview): Draw a 3D bone clip as a filmstrip: the baked rig posed at evenly spaced times, shaded, on a ground grid, with the feet that are on the ground marked; returns the PNG. _Since 0.16.0._
- [`anim3d.remove_event`](commands/anim.md#anim3dremove_event): Remove an event from a 3D clip. _Since 0.16.0._
- [`anim3d.remove_keys`](commands/anim.md#anim3dremove_keys): Delete keys of a 3D clip by bone, channel and time; a track left with no key goes away. _Since 0.16.0._
- [`anim3d.remove_track`](commands/anim.md#anim3dremove_track): Remove the tracks of one bone from a 3D clip (all its channels, or the one in `channel`). _Since 0.16.0._
- [`anim3d.restore`](commands/anim.md#anim3drestore): Put a 3D clip file back to a whole document, or delete it: the undo and redo of the anim3d.* edits. _Since 0.16.0._
- [`anim3d.retarget`](commands/anim.md#anim3dretarget): Carry a 3D clip from one baked rig to another (other proportions, a different template) by bone role, index and side; root motion and feet are scaled and planted feet stay planted. _Since 0.16.0._
- [`anim3d.set_clip`](commands/anim.md#anim3dset_clip): Set the duration, loop, ground speed or description of a 3D clip. _Since 0.16.0._
- [`anim3d.set_event`](commands/anim.md#anim3dset_event): Move, rename or change the data or the game feel actions of an event of a 3D clip. _Since 0.16.0._
- [`anim3d.set_interp`](commands/anim.md#anim3dset_interp): Set how selected keys of a 3D clip reach the next key: linear, step, bezier or an easing (the M42 curves). _Since 0.16.0._
- [`anim3d.set_keys`](commands/anim.md#anim3dset_keys): Add or replace keys of one bone's track in a 3D clip (rotation as euler degrees or quaternion, translation, scale); a key at the time of an existing one replaces it. _Since 0.16.0._
- [`ik3d.check`](commands/anim.md#ik3dcheck): Check the `solvers` of an IK3D component against a baked rig: types, keys, number ranges, bone names ('did you mean') and chains (root -> mid -> end). _Since 0.16.0._
- [`ik3d.key`](commands/anim.md#ik3dkey): Solve a 3D IK solver (two-bone with pole, or look-at) on a clip's pose at a time and key the bones it moved: the way an IK handle poses a chain. _Since 0.16.0._
- [`ik3d.solve`](commands/anim.md#ik3dsolve): Run one IK3D solver offline on a baked rig (its rest pose, or a clip's pose at a time) and report whether it reached, the error and where the bones ended up. _Since 0.16.0._

### [api](commands/api.md)

- [`api.commands`](commands/api.md#apicommands): Describe every registered command (name, summary, schema).
- [`api.components`](commands/api.md#apicomponents): Describe every component type: fields, kinds, defaults, docs.
- [`api.scripting`](commands/api.md#apiscripting): Machine-readable JavaScript API (modules, classes, functions) for gameplay scripts.

### [assets](commands/assets.md)

- [`assets.analyze_audio`](commands/assets.md#assetsanalyze_audio-modifies-state): Measure the loudness of a sound (or of every sound) and keep the result in assets.json. _Since 0.1.6._
- [`assets.animate_svg`](commands/assets.md#assetsanimate_svg-modifies-state): Draw an animation with code (a JS module that returns the SVG of each frame, or an SVG with SMIL) and bake it into a sprite sheet PNG plus its `sheet` entry, offline: no provider, no key. _Since 0.6.0._
- [`assets.bake_sheet`](commands/assets.md#assetsbake_sheet-modifies-state): Bake an entity the engine draws (a prefab, or an entity of a scene) into a sprite sheet: Shape2D, tweens, particles and scripts play and are captured frame by frame. _Since 0.6.0._
- [`assets.check_art`](commands/assets.md#assetscheck_art): Check pictures against the house style and how they read in the game: palette fit, contrast over the real backgrounds, readability at phone and desktop size, halos on alpha edges, and set consistency; returns an annotated picture. _Since 0.16.0._
- [`assets.check_mix`](commands/assets.md#assetscheck_mix): Measure every sound of the project together: loudness per bus, music masking effects, clicks, loop seams, clipping, true peak; each finding has a fix. _Since 0.16.0._
- [`assets.contact_sheet`](commands/assets.md#assetscontact_sheet): Look at a set of images (or .glb models) side by side at their on-screen size, over light, dark and camera-colour backgrounds and in greyscale, labelled with their file names. _Since 0.16.0._
- [`assets.convert_audio`](commands/assets.md#assetsconvert_audio-modifies-state): Convert a WAV in the project to Ogg Vorbis (smaller, streams well) and record where it came from. _Since 0.3.0._
- [`assets.disclosure`](commands/assets.md#assetsdisclosure): Write the AI-generated content disclosure for store forms (Steam) from the provenance records. _Since 0.1.6._
- [`assets.draw_capsules`](commands/assets.md#assetsdraw_capsules-modifies-state): Make the store page images (capsules, heroes, covers, screenshots) at each store's sizes from one piece of key art and a logo. _Since 0.2.0._
- [`assets.draw_icon`](commands/assets.md#assetsdraw_icon-modifies-state): Draw the game's icon (1024x1024 PNG) and the Android adaptive-icon foreground from shapes and text, no image provider needed. _Since 0.2.0._
- [`assets.generate_image`](commands/assets.md#assetsgenerate_image-modifies-state): Generate a PNG image with the image asset provider and record where it came from. _Since 0.1.6._
- [`assets.generate_loop`](commands/assets.md#assetsgenerate_loop-modifies-state): Make a seamless loop offline (a wind or fire bed, a clock, a drone or chord pad) as a WAV or Ogg: no provider, no key. _Since 0.3.0._
- [`assets.generate_model`](commands/assets.md#assetsgenerate_model-modifies-state): Generate a 3D model with the model3d asset provider and record where it came from. _Since 0.1.6._
- [`assets.generate_music`](commands/assets.md#assetsgenerate_music-modifies-state): Generate a music track with the music asset provider and record where it came from. _Since 0.1.6._
- [`assets.generate_sound`](commands/assets.md#assetsgenerate_sound-modifies-state): Generate a sound effect with the sound asset provider and record where it came from. _Since 0.1.6._
- [`assets.generate_sprite_sheet`](commands/assets.md#assetsgenerate_sprite_sheet-modifies-state): Generate a sprite sheet (a grid of animation frames) and record its layout for SpriteAnimator. _Since 0.1.6._
- [`assets.generate_texture`](commands/assets.md#assetsgenerate_texture-modifies-state): Make a material texture (paper, parchment, wood, planks, leather, fabric, stone, noise, gradient, vignette) offline: a seeded PNG, no provider and no key. _Since 0.4.0._
- [`assets.generate_voice`](commands/assets.md#assetsgenerate_voice-modifies-state): Generate spoken audio from text with the voice asset provider and record where it came from. _Since 0.1.6._
- [`assets.import`](commands/assets.md#assetsimport-modifies-state): Bring a file made elsewhere (Aseprite, PSD, OBJ, FBX, PNG, WAV, glTF, MP4...) into the project's assets/ folder and record where it came from. _Since 0.1.6._
- [`assets.list`](commands/assets.md#assetslist): List project asset files with type and size. Types: texture, audio, font, mesh, script, scene, prefab, material, vfx, other (by file name).
- [`assets.pack_atlas`](commands/assets.md#assetspack_atlas-modifies-state): Pack a folder of images into one atlas PNG and write the frame table (rect and pivot per frame) that a Sprite's `region` reads. _Since 0.3.0._
- [`assets.pick`](commands/assets.md#assetspick-modifies-state): Keep the candidate the person chose: it becomes the slot, the others are dropped. _Since 0.18.0._
- [`assets.preload`](commands/assets.md#assetspreload-modifies-state): Read a list of asset files in the background, ready for their first use. _Since 0.19.0._
- [`assets.preview_in_scene`](commands/assets.md#assetspreview_in_scene): See an asset inside a scene of the game: it is placed (a PNG as a Sprite, a .glb as a MeshRenderer) in a private run of the scene and captured at phone and desktop resolutions. _Since 0.16.0._
- [`assets.preview_sheet`](commands/assets.md#assetspreview_sheet): Look at a sprite sheet the way the game plays it: a labelled grid of its frames (numbers, cell edges, pivot, optional onion skin) plus checks for empty, cut or jumping frames and a loop seam. _Since 0.6.0._
- [`assets.provenance`](commands/assets.md#assetsprovenance): Show where assets came from: the provenance record of one file, or all of them. _Since 0.1.6._
- [`assets.rasterize_svg`](commands/assets.md#assetsrasterize_svg-modifies-state): Turn an SVG (text or a project file) into a PNG at a given size, offline: art you write as vector shapes, no provider and no key. _Since 0.4.0._
- [`assets.regenerate`](commands/assets.md#assetsregenerate-modifies-state): Make a made asset again from the recipe its provenance records, and say what changed. _Since 0.6.0._
- [`assets.review`](commands/assets.md#assetsreview): A cheap one-shot vision review of the pictures you made: a verdict and concrete fixes, grounded on assets.check_art and the style references. _Since 0.16.0._
- [`assets.set_provenance`](commands/assets.md#assetsset_provenance-modifies-state): Record where an asset came from (hand-made, imported, or made with AI elsewhere). _Since 0.1.6._
- [`assets.slice_sheet`](commands/assets.md#assetsslice_sheet-modifies-state): Make an image playable by SpriteAnimator: check its frame grid, or find the frames of an uneven sheet and repack them. _Since 0.1.6._
- [`assets.spectrogram`](commands/assets.md#assetsspectrogram): See a sound: a picture of its waveform, spectrogram (log frequency) and loudness curve, with the clipped samples and the loop seam marked. _Since 0.16.0._
- [`assets.subset_font`](commands/assets.md#assetssubset_font-modifies-state): Cut a font down to the characters of the locale tables plus Latin and punctuation (a CJK font from 17 MB to a few hundred KB), pinning a variable font's axes. _Since 0.3.0._
- [`assets.synth_sound`](commands/assets.md#assetssynth_sound-modifies-state): Make a game sound (bark, growl, coin, jump, explosion...) offline from a preset: a deterministic WAV, no provider and no key. _Since 0.3.0._
- [`audio.bake`](commands/assets.md#audiobake-modifies-state): Render audio documents to WAV/OGG files next to them (only the missing or stale ones unless forced), with their recipe in assets.json. _Since 0.16.0._
- [`audio.create`](commands/assets.md#audiocreate-modifies-state): Write a new audio document (a source and a chain of steps) and bake it. _Since 0.16.0._
- [`audio.edit`](commands/assets.md#audioedit-modifies-state): Add, change, remove or move one step of an audio document (or change its source, seed or output), then bake it. _Since 0.16.0._
- [`audio.info`](commands/assets.md#audioinfo): Check an audio document and say what its chain renders to; with no arguments, list the step types and their fields. _Since 0.16.0._
- [`audio.render`](commands/assets.md#audiorender): Render an audio document in memory: measurements, what each step did, and a waveform/spectrogram picture. Writes nothing. _Since 0.16.0._
- [`image.bake`](commands/assets.md#imagebake-modifies-state): Draw a layered image document (*.image.json) into its PNG and return the picture. _Since 0.16.0._
- [`image.create`](commands/assets.md#imagecreate-modifies-state): Make a new layered image document (*.image.json) with a canvas size, a background and optional first layers, and bake its PNG. _Since 0.16.0._
- [`image.draw`](commands/assets.md#imagedraw-modifies-state): Draw pixel-exact shapes (lines, rectangles, ellipses, polygons, flood fills) onto an indexed pixel-art layer by palette colour. _Since 0.16.0._
- [`image.edit`](commands/assets.md#imageedit-modifies-state): Change the selected pixels of one layer of an image document: fill, recolor, move, transform (scale, rotate, flip), delete, copy or cut to a new layer. _Since 0.16.0._
- [`image.export`](commands/assets.md#imageexport-modifies-state): Write the flattened picture of a document, or one layer or group of it, to a PNG, optionally scaled or trimmed. _Since 0.16.0._
- [`image.frame.add`](commands/assets.md#imageframeadd-modifies-state): Add frames to an image document (making it an animation), copying a frame or blank, and keep the tags in place. _Since 0.16.0._
- [`image.frame.cel`](commands/assets.md#imageframecel-modifies-state): Make a layer show in one frame what it shows in another, or show nothing there. _Since 0.16.0._
- [`image.frame.move`](commands/assets.md#imageframemove-modifies-state): Move a frame to another place in the animation; tags follow their frames. _Since 0.16.0._
- [`image.frame.remove`](commands/assets.md#imageframeremove-modifies-state): Remove one frame of an animated image document; later frames and tags move down. _Since 0.16.0._
- [`image.frame.set`](commands/assets.md#imageframeset-modifies-state): Set how long frames show, in milliseconds. _Since 0.16.0._
- [`image.frame.sheet`](commands/assets.md#imageframesheet-modifies-state): Choose how many frames the baked sprite sheet has per row. _Since 0.16.0._
- [`image.generate_layer`](commands/assets.md#imagegenerate_layer-modifies-state): Generate a picture with the image provider and add it to an image document as a `provider` layer, optionally masked by a selection. _Since 0.16.0._
- [`image.info`](commands/assets.md#imageinfo): Describe a layered image document: its layers as a tree with index paths, sizes, bake status, the files it reads and its stored selections. _Since 0.16.0._
- [`image.inpaint`](commands/assets.md#imageinpaint-modifies-state): Repaint the selected part of an image document with the image provider and add the result as a masked `provider` layer. _Since 0.16.0._
- [`image.layer.add`](commands/assets.md#imagelayeradd-modifies-state): Add a layer to an image document (at the top, or at an index, or inside a group) and bake the picture. _Since 0.16.0._
- [`image.layer.add_provider`](commands/assets.md#imagelayeradd_provider-modifies-state): Add a PNG an image provider made to an image document as a `provider` layer, with its provenance and an optional mask from a stored selection. _Since 0.16.0._
- [`image.layer.convert`](commands/assets.md#imagelayerconvert-modifies-state): Turn a layer into an indexed pixel-art layer (quantized to the palette, optional dither) or an indexed layer back into a pixels layer. _Since 0.16.0._
- [`image.layer.move`](commands/assets.md#imagelayermove-modifies-state): Move a layer to another position in its list, or into another group (or back to the top level), and bake. _Since 0.16.0._
- [`image.layer.remove`](commands/assets.md#imagelayerremove-modifies-state): Remove a layer (and the children of a group) from an image document and bake. _Since 0.16.0._
- [`image.layer.set`](commands/assets.md#imagelayerset-modifies-state): Change fields of one layer (name, visible, opacity, blend, x, y, clip, masks, adjustments, effects, its kind's fields) and bake. _Since 0.16.0._
- [`image.paint`](commands/assets.md#imagepaint-modifies-state): Paint round-brush strokes onto a pixels layer of an image document (deterministic stamping), creating the layer's PNG when asked. _Since 0.16.0._
- [`image.palette`](commands/assets.md#imagepalette-modifies-state): Show or change the palette and the colour ramps that indexed pixel-art layers of an image document are locked to. _Since 0.16.0._
- [`image.palette.move`](commands/assets.md#imagepalettemove-modifies-state): Move one colour of an image document's palette to another position; the pixels follow it, so the picture does not change. _Since 0.16.0._
- [`image.palette.remove`](commands/assets.md#imagepaletteremove-modifies-state): Remove one colour from an image document's palette; its pixels become another colour or transparent. _Since 0.16.0._
- [`image.pixel`](commands/assets.md#imagepixel-modifies-state): Write exact pixels (a list, runs or a text stamp) onto an indexed pixel-art layer by palette colour; no anti-aliasing. _Since 0.16.0._
- [`image.pixel.cleanup`](commands/assets.md#imagepixelcleanup-modifies-state): Clean an indexed layer: orphan pixels, doubles at line bends and uneven steps on nearly straight lines; reports what changed. _Since 0.16.0._
- [`image.pixel.dither`](commands/assets.md#imagepixeldither-modifies-state): Fill a region of an indexed layer with a dithered blend of palette colours (Bayer or checker), constant or as a gradient along a direction. _Since 0.16.0._
- [`image.pixel.outline`](commands/assets.md#imagepixeloutline-modifies-state): Outline an indexed pixel-art layer by palette colour: inside or outside, 4- or 8-connected, flat, darkest of the ramp, or selective (sel-out). _Since 0.16.0._
- [`image.pixel.rotate`](commands/assets.md#imagepixelrotate-modifies-state): Rotate the pixels of an indexed layer (or a selection) by any angle, RotSprite-style: no new colours, no blur. _Since 0.16.0._
- [`image.pixel.scale`](commands/assets.md#imagepixelscale-modifies-state): Scale the pixels of an indexed layer (or a selection) cleanly: whole factors repeat pixels, reductions take the commonest colour, scale2x/scale3x round corners; no blending. _Since 0.16.0._
- [`image.pixel.shade`](commands/assets.md#imagepixelshade-modifies-state): Shade an indexed pixel-art shape from a light direction: shadow and highlight bands stepping along the colour ramps, optional dithered transition. _Since 0.16.0._
- [`image.save`](commands/assets.md#imagesave-modifies-state): Check an image document, write it to a *.image.json file and bake its PNG; nothing is written when the document has a problem. _Since 0.16.0._
- [`image.select`](commands/assets.md#imageselect-modifies-state): Select part of an image document's canvas (by colour, alpha, rectangle, ellipse, polygon or a layer's shape) and store it by name for image.edit and image.paint. _Since 0.16.0._
- [`image.tag.remove`](commands/assets.md#imagetagremove-modifies-state): Remove a tag (and so its clip) from an image document. _Since 0.16.0._
- [`image.tag.set`](commands/assets.md#imagetagset-modifies-state): Name a run of frames (a tag); the bake makes a SpriteAnimator clip of it. _Since 0.16.0._
- [`image.tile.check`](commands/assets.md#imagetilecheck): Check that a picture (or each tile of a sheet) repeats without a visible seam, with a preview of 3 x 3 copies. _Since 0.16.0._
- [`image.tile.set`](commands/assets.md#imagetileset-modifies-state): Turn tile mode (wrap-around editing) on or off for an image document. _Since 0.16.0._
- [`image.tileset.build`](commands/assets.md#imagetilesetbuild-modifies-state): Make an autotile tileset (16 or 47 tiles) from a few parts (inside, edge, corner), bake the sheet and write the Tilemap rules. _Since 0.16.0._
- [`image.tileset.check`](commands/assets.md#imagetilesetcheck): Check an autotile tileset: every part is one tile big, and every pair of tiles that can touch in a map fits. _Since 0.16.0._
- [`image.tileset.info`](commands/assets.md#imagetilesetinfo): Explain the parts of an autotile tileset and list its tiles (slot, neighbours, position in the sheet). _Since 0.16.0._
- [`image.tileset.rules`](commands/assets.md#imagetilesetrules-modifies-state): Write the Tilemap autotile rules file of a tileset layer (the recipe command that keeps it current). _Since 0.16.0._
- [`image.to_pixel_art`](commands/assets.md#imageto_pixel_art-modifies-state): Turn a painted, generated or imported picture (a layer or a PNG) into palette-exact pixel art: area-aware downscale, quantize, clean up, into an indexed layer. _Since 0.16.0._
- [`model.bake`](commands/assets.md#modelbake-modifies-state): Build model documents into .glb files next to them (only the missing or stale ones unless forced), with their recipe in assets.json. _Since 0.16.0._
- [`model.bake_maps`](commands/assets.md#modelbake_maps): Bake a model's ambient occlusion, curvature and thickness maps in its UV atlas and measure them (nothing is written): the masks that texturing wear is built from. Returns the maps as pictures. _Since 0.16.0._
- [`model.check`](commands/assets.md#modelcheck): Measure a model document's mesh for faults an artist finds by eye: scale, origin, flipped or inconsistent triangles, open and non-manifold edges, degenerate triangles, platform budgets. Each finding says where, what and how to fix. _Since 0.16.0._
- [`model.create`](commands/assets.md#modelcreate-modifies-state): Write a new model document (a tree of primitives, modifiers, groups and transforms) and bake it to a .glb. _Since 0.16.0._
- [`model.decal`](commands/assets.md#modeldecal-modifies-state): Add, replace, remove or clear the decals of a model document: pictures (logos, stains, markings) projected on its surface and baked into the texture. _Since 0.16.0._
- [`model.edit`](commands/assets.md#modeledit-modifies-state): Add, change, remove or move one node of a model document by its id (or JSON pointer), or change its materials, output or note; then bake it. _Since 0.16.0._
- [`model.game_ready`](commands/assets.md#modelgame_ready-modifies-state): Make a model document game-ready: origin, merged submeshes, LODs, a collider and a triangle budget report per platform; the settings live in the document. _Since 0.16.0._
- [`model.import_clean`](commands/assets.md#modelimport_clean-modifies-state): Clean a generated or imported mesh (.glb, .gltf, .obj) into a game-ready model document: weld, drop floating bits, recentre, scale to a reference, decimate to a platform budget, optionally remesh, unwrap, and bake. _Since 0.16.0._
- [`model.info`](commands/assets.md#modelinfo): Check a model document and measure what it builds; with no arguments, list the operations (primitives, modifiers, group) and their fields. _Since 0.16.0._
- [`model.palette`](commands/assets.md#modelpalette-modifies-state): Colour a model with a palette without a texture: the `vertexColors` section (style palette or your own colours, one colour or a gradient per part, flat low-poly faces); returns the palette swatches. _Since 0.16.0._
- [`model.preview`](commands/assets.md#modelpreview): Draw a model document from 4 to 8 sides (a turntable sheet, shaded and/or wireframe) beside a 1.8 m reference figure, with its triangle count and size; returns the PNG. _Since 0.16.0._
- [`model.select`](commands/assets.md#modelselect): Try a selection of faces or edges chosen by meaning (normal direction, part, region, top/bottom, border, sharp, seam) on the mesh a node receives, and report what it matched. _Since 0.16.0._
- [`model.texture`](commands/assets.md#modeltexture-modifies-state): Texture a model document: materials with tiling textures projected triplanar into the UV atlas, vertex colours, baked ambient occlusion and wear (worn edges, dirt in cavities) built from baked curvature and thickness, and decals; the result is a layered image document you can paint on. Returns the texture picture. _Since 0.16.0._
- [`model.uv`](commands/assets.md#modeluv-modifies-state): Give a model document UVs (automatic unwrap, or box, cylinder, sphere and planar projections per part, packed into one texture at the style's texel density) and measure them; returns the UV layout picture. _Since 0.16.0._
- [`music.arpeggio`](commands/assets.md#musicarpeggio-modifies-state): Make an arpeggio over a chord progression as note text, and optionally put it in a song. _Since 0.16.0._
- [`music.bassline`](commands/assets.md#musicbassline-modifies-state): Make a bassline over a chord progression as note text, and optionally put it in a song. _Since 0.16.0._
- [`music.check`](commands/assets.md#musiccheck): Find what is wrong in a song before listening: notes outside the key or the instrument's range, clashes, mud, silent tracks, loudness. _Since 0.16.0._
- [`music.chord`](commands/assets.md#musicchord): Spell a chord by name, or a chord progression in a key: notes, MIDI numbers and the note text to paste. _Since 0.16.0._
- [`music.create`](commands/assets.md#musiccreate-modifies-state): Write a new song document: pad, bass, drums and an arpeggio over a chord progression, with intro, loop and outro. _Since 0.16.0._
- [`music.drums`](commands/assets.md#musicdrums-modifies-state): Make a drum pattern in a style (rock, funk, waltz, ...), and optionally put it in a song. _Since 0.16.0._
- [`music.edit`](commands/assets.md#musicedit-modifies-state): Change a song document: tempo, tracks, patterns, sections, the arrangement, mutes and automation, checked before anything is written. _Since 0.16.0._
- [`music.export_midi`](commands/assets.md#musicexport_midi-modifies-state): Write a song as a format-1 Standard MIDI File that a DAW or notation program opens. _Since 0.16.0._
- [`music.import_midi`](commands/assets.md#musicimport_midi-modifies-state): Turn a Standard MIDI File (.mid) into a song document: tracks, patterns, sections from markers, drums as grids. _Since 0.16.0._
- [`music.info`](commands/assets.md#musicinfo): Check a song document and say what it holds: structure, bars, seconds, a summary per section, and a piano-roll picture. _Since 0.16.0._
- [`music.instrument`](commands/assets.md#musicinstrument-modifies-state): List the built-in song instruments (by family), the drum kits and lanes, sfx presets and project SoundFonts, show the patch behind an instrument, or list a SoundFont's presets. _Since 0.16.0._
- [`music.mix`](commands/assets.md#musicmix): Render a song in memory and report the mix: each track's level, the buses and what the master's loudness normalization and limiter did. _Since 0.16.0._
- [`music.notes`](commands/assets.md#musicnotes): List the notes of one pitched pattern of a song (pitch, tick, duration, velocity), or the hits of a drum pattern, as a piano roll sees them. _Since 0.16.0._
- [`music.preview`](commands/assets.md#musicpreview-modifies-state): Render a song to a stereo WAV or OGG next to it (offline, deterministic) and see its spectrogram. _Since 0.16.0._
- [`music.render`](commands/assets.md#musicrender-modifies-state): Render a whole song (intro, loop, outro) to a game-ready WAV or OGG with sample-exact loop points, and optionally one stem per layer. _Since 0.16.0._
- [`music.scale`](commands/assets.md#musicscale): Say which notes a scale or mode has and the chords built on its degrees (with Roman numerals). _Since 0.16.0._
- [`rig.bake`](commands/assets.md#rigbake-modifies-state): Fit rig documents to their models and write the skinned .glb files next to them (only the missing or stale ones unless forced), with their recipe in assets.json. _Since 0.16.0._
- [`rig.create`](commands/assets.md#rigcreate-modifies-state): Write a rig document for a model: a skeleton template (humanoid, quadruped, bird, tail, chain, generic) fitted to the model by its parts and landmarks, and bake it to a skinned .glb. _Since 0.16.0._
- [`rig.fit`](commands/assets.md#rigfit-modifies-state): Change what a rig document tells the fit (parts, landmarks, options, symmetry, strict), fit the template to the model again and show what it matched; then bake. _Since 0.16.0._
- [`rig.info`](commands/assets.md#riginfo): Check a rig document and fit it to its model without writing anything: every issue with its fix, the bones, where each joint came from and what the fit noticed. _Since 0.16.0._
- [`rig.templates`](commands/assets.md#rigtemplates): List the skeleton templates (humanoid, quadruped, bird, tail, chain, generic) with their options and the words in part names they recognise; with `name`, the bones of one. _Since 0.16.0._
- [`sfx.bake`](commands/assets.md#sfxbake-modifies-state): Render every sound patch of the project whose WAV is missing or out of date. _Since 0.16.0._
- [`sfx.edit`](commands/assets.md#sfxedit-modifies-state): Change one field of a sound patch by JSON pointer (set, remove, add to an array, move inside an array); the result must still be a valid patch. _Since 0.16.0._
- [`sfx.family`](commands/assets.md#sfxfamily-modifies-state): Make a consistent set of interface sounds (click, hover, confirm, cancel, error, open, close, notify) from one base patch. _Since 0.16.0._
- [`sfx.info`](commands/assets.md#sfxinfo): Check a sound patch and say what it holds and how loud it renders, without writing anything. _Since 0.16.0._
- [`sfx.preset`](commands/assets.md#sfxpreset-modifies-state): List the sound presets, return one as an editable patch, or write it to a *.sfx.json file. _Since 0.16.0._
- [`sfx.render`](commands/assets.md#sfxrender-modifies-state): Render a sound patch (*.sfx.json) to a WAV or OGG next to it and see its spectrogram: the engine's own synthesizer, offline and deterministic. _Since 0.16.0._
- [`sfx.tweak`](commands/assets.md#sfxtweak-modifies-state): Turn a patch's macros by meaning (brighter, longer tail, heavier) and write the change back to the patch. _Since 0.16.0._
- [`skin3d.add`](commands/assets.md#skin3dadd-modifies-state): Add weight to a bone (or take it away with a negative amount) on the vertices of a part or a selection. _Since 0.16.0._
- [`skin3d.auto`](commands/assets.md#skin3dauto-modifies-state): Choose how the weights are computed (auto, heat, voxel, rigid), for the whole rig or one part, and their settings; recompute and bake. _Since 0.16.0._
- [`skin3d.clear`](commands/assets.md#skin3dclear-modifies-state): Remove one edit (by index) or all the edits from a rig document's skin, recompute and bake. _Since 0.16.0._
- [`skin3d.info`](commands/assets.md#skin3dinfo): Show a rig document's skin: the method, its settings and edits, the bones with the parts they follow, and the quality of the weights it gives. _Since 0.16.0._
- [`skin3d.limit`](commands/assets.md#skin3dlimit-modifies-state): Keep at most N influences per vertex (1 to 4) on a part or a selection, strongest first, and normalise. _Since 0.16.0._
- [`skin3d.mirror`](commands/assets.md#skin3dmirror-modifies-state): Copy the weights of one side of the character to the other (_l to _r or the other way), pairing each vertex with its mirror image. _Since 0.16.0._
- [`skin3d.normalize`](commands/assets.md#skin3dnormalize-modifies-state): Drop negligible influences and make each vertex's weights sum to 1, on a part or a selection. _Since 0.16.0._
- [`skin3d.preview`](commands/assets.md#skin3dpreview): Draw the skin weights of a rig: a heat map of one bone or one colour per bone, and optionally the model bent at a bone to see how the skin deforms; returns the PNG. _Since 0.16.0._
- [`skin3d.set`](commands/assets.md#skin3dset-modifies-state): Give a bone an exact weight on the vertices of a part or a selection; the other bones share the rest. _Since 0.16.0._
- [`skin3d.smooth`](commands/assets.md#skin3dsmooth-modifies-state): Smooth the weights over the surface on the vertices of a part or a selection, to soften a crease at a joint. _Since 0.16.0._
- [`vector.add`](commands/assets.md#vectoradd-modifies-state): Add a path, rectangle, ellipse or line to an SVG. _Since 0.16.0._
- [`vector.align`](commands/assets.md#vectoralign-modifies-state): Align SVG elements to each other, the canvas or a key element. _Since 0.16.0._
- [`vector.assign_ids`](commands/assets.md#vectorassign_ids-modifies-state): Give every drawn element without an id one. _Since 0.16.0._
- [`vector.blob`](commands/assets.md#vectorblob-modifies-state): Add a smooth organic shape or curve through or around a few points. _Since 0.16.0._
- [`vector.boolean`](commands/assets.md#vectorboolean-modifies-state): Union, subtract, intersect or exclude SVG shapes into one path. _Since 0.16.0._
- [`vector.delete`](commands/assets.md#vectordelete-modifies-state): Delete SVG elements. _Since 0.16.0._
- [`vector.distribute`](commands/assets.md#vectordistribute-modifies-state): Space SVG elements evenly along an axis. _Since 0.16.0._
- [`vector.duplicate`](commands/assets.md#vectorduplicate-modifies-state): Copy SVG elements right after the originals. _Since 0.16.0._
- [`vector.group`](commands/assets.md#vectorgroup-modifies-state): Wrap SVG elements in a new group. _Since 0.16.0._
- [`vector.info`](commands/assets.md#vectorinfo): List the shapes and groups of an SVG with ids, bounds and node counts. _Since 0.16.0._
- [`vector.mirror`](commands/assets.md#vectormirror-modifies-state): Mirror shapes across a vertical or horizontal axis and weld the halves, or add the mirrored copy. _Since 0.16.0._
- [`vector.nodes`](commands/assets.md#vectornodes-modifies-state): Edit the nodes of a path: move anchors and handles, insert, delete, convert, break, join, close, append. _Since 0.16.0._
- [`vector.offset`](commands/assets.md#vectoroffset-modifies-state): Grow or shrink SVG shapes by a distance (offset path, inset). _Since 0.16.0._
- [`vector.reorder`](commands/assets.md#vectorreorder-modifies-state): Change the drawing order of SVG elements or move them into another group. _Since 0.16.0._
- [`vector.repeat`](commands/assets.md#vectorrepeat-modifies-state): Repeat an SVG element in a grid or around a circle. _Since 0.16.0._
- [`vector.set`](commands/assets.md#vectorset-modifies-state): Set the style, visibility, lock, id or attributes of SVG elements. _Since 0.16.0._
- [`vector.set_path`](commands/assets.md#vectorset_path-modifies-state): Replace the path data of a shape. _Since 0.16.0._
- [`vector.shade`](commands/assets.md#vectorshade-modifies-state): Add a shadow band and a highlight band to shapes from the light direction. _Since 0.16.0._
- [`vector.shape`](commands/assets.md#vectorshape-modifies-state): Add a star, gear, rounded polygon, arrow, speech bubble or ribbon to an SVG. _Since 0.16.0._
- [`vector.simplify`](commands/assets.md#vectorsimplify-modifies-state): Reduce the nodes of SVG paths within a tolerance. _Since 0.16.0._
- [`vector.smooth`](commands/assets.md#vectorsmooth-modifies-state): Round the corners of SVG paths into smooth Bezier curves. _Since 0.16.0._
- [`vector.stroke_to_path`](commands/assets.md#vectorstroke_to_path-modifies-state): Turn the stroke of SVG shapes into a filled outline path. _Since 0.16.0._
- [`vector.style`](commands/assets.md#vectorstyle-modifies-state): Apply the project's style guide to an SVG: outline and palette. _Since 0.16.0._
- [`vector.text_to_path`](commands/assets.md#vectortext_to_path-modifies-state): Turn text into path outlines with the engine's fonts, so it needs no font. _Since 0.16.0._
- [`vector.to_rig`](commands/assets.md#vectorto_rig-modifies-state): Turn an SVG whose named groups are the parts of a character into part pictures, joints and a Bone2D prefab that animates in parts. _Since 0.16.0._
- [`vector.transform`](commands/assets.md#vectortransform-modifies-state): Move, scale, rotate or flip SVG elements in the drawing space. _Since 0.16.0._
- [`vector.ungroup`](commands/assets.md#vectorungroup-modifies-state): Dissolve SVG groups, keeping what is in them where it was. _Since 0.16.0._
- [`vfx.create`](commands/assets.md#vfxcreate-modifies-state): Write a new effect document (*.vfx.json) with one burst emitter, as a starting point to edit. _Since 0.17.0._
- [`vfx.edit`](commands/assets.md#vfxedit-modifies-state): Change one field of an effect document by JSON pointer (set, remove, add to an array, move inside an array); the result must still be a valid effect. _Since 0.17.0._

### [audio](commands/audio.md)

- [`audio.bus`](commands/audio.md#audiobus-modifies-state): Set a bus's volume and effects (low-pass, reverb, ducking), or read its state. _Since 0.3.0._
- [`audio.log`](commands/audio.md#audiolog): List the sounds played so far (clip path, frame, volume, bus, source entity), oldest first.
- [`audio.music`](commands/audio.md#audiomusic-modifies-state): Drive a MusicPlayer: play, stop, setIntensity, goToSection, playStinger or crossfadeTo. _Since 0.16.0._
- [`audio.music_state`](commands/audio.md#audiomusic_state): What the MusicPlayer components are doing: song, section, bar, beat, layers and pending changes. _Since 0.16.0._
- [`audio.snapshot`](commands/audio.md#audiosnapshot-modifies-state): Apply a named mixer snapshot from factoria.json, or list the snapshots. _Since 0.3.0._

### [docs](commands/docs.md)

- [`docs.commands`](commands/docs.md#docscommands): Reference of the available commands (tools) with arguments: a list of names, or one command in full.
- [`docs.components`](commands/docs.md#docscomponents): Reference of components and fields (types, defaults, docs): a list of names, or one component in full.
- [`docs.list`](commands/docs.md#docslist): List the engine documentation available offline.
- [`docs.read`](commands/docs.md#docsread): Read a documentation page (Markdown), a section or a line range; long pages come in parts.
- [`docs.search`](commands/docs.md#docssearch): Search the documentation by keywords.
- [`docs.write_reference`](commands/docs.md#docswrite_reference-modifies-state): Write the browsable API reference pages (docs/reference/) and docs/COMPONENTS.md. _Since 0.2.0._

### [engine](commands/engine.md)

- [`engine.info`](commands/engine.md#engineinfo): Show engine version, platform, graphics backend and loop state.
- [`engine.update_status`](commands/engine.md#engineupdate_status): Tell whether FactorIA was updated on disk while this process runs, and so whether a restart is due. _Since 0.4.0._

### [feedback](commands/feedback.md)

- [`feedback.archive`](commands/feedback.md#feedbackarchive-modifies-state): Move the closed feedback entries (fixed-in-engine, wont-fix, duplicate, rejected) to the archive file. _Since 0.4.0._
- [`feedback.check`](commands/feedback.md#feedbackcheck): Check, before filing, whether the engine already has what a feedback report says is missing. _Since 0.16.1._
- [`feedback.check_fixed`](commands/feedback.md#feedbackcheck_fixed-modifies-state): Close the open feedback entries whose gap this engine version fixed. _Since 0.10.0._
- [`feedback.delete`](commands/feedback.md#feedbackdelete-modifies-state): Delete a closed feedback entry (rejected, wont-fix, duplicate, fixed) from the file and its archive. _Since 0.16.1._
- [`feedback.list`](commands/feedback.md#feedbacklist): List the engine-feedback entries recorded for this project.
- [`feedback.report`](commands/feedback.md#feedbackreport-modifies-state): Record an engine gap (missing feature, bug, confusing doc) and the workaround you used.
- [`feedback.share`](commands/feedback.md#feedbackshare-modifies-state): Send the queued feedback to the engine developer now (only what the user's mode allows). _Since 0.10.0._
- [`feedback.share_preview`](commands/feedback.md#feedbackshare_preview): Show exactly what sharing would send for the entries that have a `share`, and what the sanitizer removed. _Since 0.10.0._
- [`feedback.share_status`](commands/feedback.md#feedbackshare_status): Sharing with the engine developer: the mode, the server, whether the user signed in, and the outbox. _Since 0.10.0._
- [`feedback.update`](commands/feedback.md#feedbackupdate-modifies-state): Change the status of a feedback entry (with a reason when it is rejected) or link it to an engine issue.
- [`feedback.verdicts`](commands/feedback.md#feedbackverdicts-modifies-state): Ask the feedback server what the engine developers decided about the reports this installation sent. _Since 0.16.1._

### [feel](commands/feel.md)

- [`feel.cancel`](commands/feel.md#feelcancel-modifies-state): Ends the game feel effects of an entity at once (flash, squash, shake, knockback), or of everything. _Since 0.17.0._
- [`feel.flash`](commands/feel.md#feelflash-modifies-state): Draws an entity in one colour for a moment (a hit flash): sprites, shapes and 3D meshes, fading or square. _Since 0.17.0._
- [`feel.hitStop`](commands/feel.md#feelhitstop-modifies-state): Hit-stop: freezes or slows gameplay for a moment of real time; UI, audio and the stop's own timer keep going. _Since 0.17.0._
- [`feel.knockback`](commands/feel.md#feelknockback-modifies-state): Pushes an entity away and holds `isKnockedBack` for a moment: an impulse on its physics body, else a decaying velocity. _Since 0.17.0._
- [`feel.settings`](commands/feel.md#feelsettings-modifies-state): The accessibility choices of the game feel effects: reduceMotion and reducedEffects. _Since 0.17.0._
- [`feel.shake`](commands/feel.md#feelshake-modifies-state): Camera shake: adds trauma to a camera (2D and 3D); it stacks up to `cap` and dies out over `duration`. _Since 0.17.0._
- [`feel.sound`](commands/feel.md#feelsound-modifies-state): Plays a sound once through the audio system (the same one a clip event's "sound" action uses). _Since 0.17.0._
- [`feel.spawn`](commands/feel.md#feelspawn-modifies-state): Makes an effect appear: instantiates a prefab at an entity (or at a point) the next frame. _Since 0.17.0._
- [`feel.squash`](commands/feel.md#feelsquash-modifies-state): Squash and stretch: a short scale pulse that keeps the volume and springs back to exactly the entity's scale. _Since 0.17.0._
- [`feel.state`](commands/feel.md#feelstate): What the game feel effects are doing now: hit-stop, and per entity its shake, flash, squash, knockback and drawn pose. _Since 0.17.0._

### [fs](commands/fs.md)

- [`fs.delete`](commands/fs.md#fsdelete-modifies-state): Delete a file or folder from the project.
- [`fs.edit`](commands/fs.md#fsedit-modifies-state): Replace exact text in a file (must match exactly once unless replaceAll).
- [`fs.list`](commands/fs.md#fslist): List files and folders in the project.
- [`fs.read`](commands/fs.md#fsread): Read a text file (optionally a line range).
- [`fs.search`](commands/fs.md#fssearch): Search text in project files (substring or regex).
- [`fs.write`](commands/fs.md#fswrite-modifies-state): Create or overwrite a file (text, or binary via base64; parent folders are created).

### [game](commands/game.md)

- [`game.click`](commands/game.md#gameclick-modifies-state): Click the game like a player: move the mouse, press, release; scripts see pressed/released and UI widgets get the click. _Since 0.4.0._
- [`game.input`](commands/game.md#gameinput-modifies-state): Inject input: press/release actions or keys, or set an action state, mouse position/buttons, gamepad buttons/sticks, touches.
- [`game.logs`](commands/game.md#gamelogs): Read recent log lines (engine, scripts, assets...).
- [`game.pause`](commands/game.md#gamepause-modifies-state): Pause the simulation (frame() stops simulating; game.step still works).
- [`game.render_stats`](commands/game.md#gamerender_stats): What the renderer drew in the picture now: draw calls, triangles, lights, shadow casters, texture memory. _Since 0.3.0._
- [`game.resume`](commands/game.md#gameresume-modifies-state): Resume the simulation after game.pause.
- [`game.screenshot`](commands/game.md#gamescreenshot): Capture the game view as a PNG and show it: whole, a magnified region, or a filmstrip of frames.
- [`game.state`](commands/game.md#gamestate): Dump the game state as JSON: entities, physics, script errors, recent warnings, render stats.
- [`game.state_hash`](commands/game.md#gamestate_hash): One 64-bit hash of the whole simulation state: every entity, component and field, the live particles of every emitter, the clock and the random generator. _Since 0.19.0._
- [`game.step`](commands/game.md#gamestep-modifies-state): Advance the simulation by N fixed frames (deterministic) and return a state summary.
- [`input.record`](commands/game.md#inputrecord-modifies-state): Record the input the game receives as an input replay (start / stop). _Since 0.3.0._
- [`render.inspect`](commands/game.md#renderinspect): Luminance profile of the current picture along a line, with the hard steps (seams, bands) in it. _Since 0.4.0._
- [`render.pick`](commands/game.md#renderpick): Which entities draw a design-space pixel of the picture, topmost first. _Since 0.4.0._
- [`vfx.budget`](commands/game.md#vfxbudget): What an effect document costs on a phone: live particles and the screen they cover, with the fixes. _Since 0.17.0._
- [`vfx.check`](commands/game.md#vfxcheck): Read an effect document (*.vfx.json) and list every problem, with its JSON pointer and the fix. _Since 0.17.0._
- [`vfx.filmstrip`](commands/game.md#vfxfilmstrip-modifies-state): Film an effect playing in the game: one picture with a grid of frames, to see its timing and look at once. _Since 0.17.0._
- [`vfx.list`](commands/game.md#vfxlist): The effects that play now, and the limits of an effect. _Since 0.17.0._
- [`vfx.play`](commands/game.md#vfxplay-modifies-state): Play an effect document (*.vfx.json) at a position, or on an entity. _Since 0.17.0._
- [`vfx.review`](commands/game.md#vfxreview-modifies-state): A cheap one-shot vision review of an effect: its filmstrip graded for readability, timing, palette and overdraw, with vfx.edit fixes. _Since 0.17.0._
- [`vfx.stop`](commands/game.md#vfxstop-modifies-state): End an effect started by vfx.play (or a Vfx entity). _Since 0.17.0._

### [i18n](commands/i18n.md)

- [`i18n.export`](commands/i18n.md#i18nexport-modifies-state): Write the game's string tables as a spreadsheet (CSV) or XLIFF files for translators. _Since 0.2.0._
- [`i18n.import`](commands/i18n.md#i18nimport-modifies-state): Read a translator's CSV or XLIFF file back into locales/<language>.json. _Since 0.2.0._
- [`i18n.set_language`](commands/i18n.md#i18nset_language-modifies-state): Switch the game to another language now: every Text and widget with a key is rewritten at once. _Since 0.2.0._
- [`i18n.state`](commands/i18n.md#i18nstate): Show the languages of the game: which is current, which strings each lacks compared with the default language. _Since 0.2.0._

### [jobs](commands/jobs.md)

- [`jobs.info`](commands/jobs.md#jobsinfo): The job system now: worker threads, mode, jobs run and queued last frame, how busy each thread was. _Since 0.19.0._

### [material](commands/material.md)

- [`material.info`](commands/material.md#materialinfo): Describe a custom material: lighting, alpha mode, params with types, defaults, ranges and docs, textures, programs and compile state. _Since 0.2.0._

### [physics](commands/physics.md)

- [`nav.bake`](commands/physics.md#navbake): Bake the NavMesh3D walkable grid from the static 3D colliders and return its stats. _Since 0.3.0._
- [`nav.find_path`](commands/physics.md#navfind_path): Find a walkable path between two 3D points on the baked NavMesh3D. _Since 0.3.0._
- [`nav.find_paths`](commands/physics.md#navfind_paths): Find many walkable paths on the baked NavMesh3D in one call (run in parallel on the job threads). _Since 0.19.0._
- [`nav.find_tile_path`](commands/physics.md#navfind_tile_path): Find a path over the cells of a Tilemap (or a plain cost grid) with A*. _Since 0.3.0._
- [`nav.find_tile_paths`](commands/physics.md#navfind_tile_paths): Find many tile paths on one Tilemap (or cost grid) in one call (run in parallel on the job threads). _Since 0.19.0._
- [`nav.flow_field`](commands/physics.md#navflow_field): Distance field over the cells of a Tilemap (or a plain cost grid) from one or more goal cells. _Since 0.3.0._
- [`nav.info`](commands/physics.md#navinfo): List the NavMesh3D components with their bounds, agent size, bake state and stats. _Since 0.3.0._
- [`physics.raycast`](commands/physics.md#physicsraycast): Cast a ray against colliders (2D segment or 3D ray) and return the first hit.
- [`physics.raycast_all`](commands/physics.md#physicsraycast_all): Cast a ray against colliders (2D segment or 3D ray) and return EVERY hit, nearest first. _Since 0.3.0._
- [`physics.shape_cast`](commands/physics.md#physicsshape_cast): Sweep a circle, sphere or box from one point to another and return the first collider it touches.

### [platform](commands/platform.md)

- [`platform.add_backend`](commands/platform.md#platformadd_backend-modifies-state): Set up a store backend for this game: its plugin, its build and what the store needs. _Since 0.2.0._
- [`platform.emit`](commands/platform.md#platformemit-modifies-state): Send an event to the game as the store would: a purchase, the overlay opening or closing, a sign-in change. _Since 0.2.0._
- [`platform.remote_play_connect`](commands/platform.md#platformremote_play_connect-modifies-state): A guest joins the fake platform's Remote Play Together session, as Steam would tell the game. _Since 0.3.0._
- [`platform.remote_play_disconnect`](commands/platform.md#platformremote_play_disconnect-modifies-state): A guest leaves the fake platform's Remote Play Together session. _Since 0.3.0._
- [`platform.reset`](commands/platform.md#platformreset-modifies-state): Reset the fake platform backend: nothing unlocked, bought or saved, no scripted answers, signed in, an empty request log. _Since 0.2.0._
- [`platform.respond`](commands/platform.md#platformrespond-modifies-state): Script the next answer(s) the fake platform backend gives to a method: an error, an exact result, or a change to the default. _Since 0.2.0._
- [`platform.revoke`](commands/platform.md#platformrevoke-modifies-state): Take a purchase back in the fake platform backend, as a refund does, and send the game the event a real store would. _Since 0.3.0._
- [`platform.set_ad`](commands/platform.md#platformset_ad-modifies-state): Script what the fake platform backend's test ad does: watched to the end, closed early, no ad to show, or consent refused. _Since 0.3.0._
- [`platform.set_fake`](commands/platform.md#platformset_fake-modifies-state): Change how the fake platform backend behaves: signed in or out, how many frames it holds its answers, and the time of its cloud saves. _Since 0.2.0._
- [`platform.state`](commands/platform.md#platformstate): Show which platform backend runs, its services, the player, the declared ids and, for the fake backend, everything it holds. _Since 0.2.0._

### [play](commands/play.md)

- [`play.auto`](commands/play.md#playauto-modifies-state): Let the game play itself, headless and fast, and write the run as a play session: phases, score, how it ended, problems found, pictures. _Since 0.18.0._
- [`play.report`](commands/play.md#playreport): What happened while the game was played (by the user or by play.auto): perf, spikes, warnings/errors, the problem marks and screenshots.
- [`play.sessions`](commands/play.md#playsessions): List the recent play sessions (recorded by the editor on Play .. Stop, or by play.auto), newest first.

### [project](commands/project.md)

- [`checkpoint.create`](commands/project.md#checkpointcreate-modifies-state): Save a checkpoint: a snapshot of every file of the project that checkpoint.restore can put back. _Since 0.2.0._
- [`checkpoint.diff`](commands/project.md#checkpointdiff): Show which files changed since a checkpoint (modified, added, deleted). _Since 0.2.0._
- [`checkpoint.list`](commands/project.md#checkpointlist): List the project's checkpoints, newest first. _Since 0.2.0._
- [`checkpoint.read`](commands/project.md#checkpointread-modifies-state): Read one file as it was at a checkpoint (text inline; a binary as base64 or into a file) without restoring anything. _Since 0.4.0._
- [`checkpoint.restore`](commands/project.md#checkpointrestore-modifies-state): Put the project's files back as they were at a checkpoint (the user's Revert); ask the user before calling it. _Since 0.2.0._
- [`perf.baseline`](commands/project.md#perfbaseline-modifies-state): Measure the game and write or refresh THIS runner's entry in its performance budget file (perf.json). _Since 0.2.0._
- [`perf.check`](commands/project.md#perfcheck): Measure the game and fail when it costs more than its performance budget (perf.json) allows on this runner. _Since 0.2.0._
- [`perf.measure`](commands/project.md#perfmeasure): Run the game headless for N frames and report its cost: CPU time per frame, peak memory, draw calls, entities, triangles, lights, texture memory. _Since 0.2.0._
- [`perf.profile`](commands/project.md#perfprofile): Run the game headless with the profiler on and report where the time goes: per engine system, per script behaviour class, GPU time, memory. _Since 0.2.0._
- [`player.run_ios_sim`](commands/project.md#playerrun_ios_sim-modifies-state): Play an input replay on the iOS player in the iOS Simulator (an iPhone or an iPad), turn the screen and take a screenshot. _Since 0.3.0._
- [`project.add_menu_kit`](commands/project.md#projectadd_menu_kit-modifies-state): Copy the menu kit (main menu, options, pause, loading screen, ...) into the game and merge its strings into the locales. _Since 0.3.0._
- [`project.create`](commands/project.md#projectcreate-modifies-state): Create a new game project from a template.
- [`project.export`](commands/project.md#projectexport-modifies-state): Package the game for a platform: a desktop bundle, an Android APK/AAB, an iOS project, or a web page (HTML5). _Since 0.1.2._
- [`project.info`](commands/project.md#projectinfo): Show the project settings, input actions, current scene, scenes and scripts.
- [`project.new_ci_workflow`](commands/project.md#projectnew_ci_workflow-modifies-state): Write a GitHub Actions workflow that validates, tests and exports the game on every push. _Since 0.2.0._
- [`project.new_plugin`](commands/project.md#projectnew_plugin-modifies-state): Create a native plugin (C/C++) for this game and declare it in factoria.json. _Since 0.1.6._
- [`project.serve_web`](commands/project.md#projectserve_web-modifies-state): Serve the game's web build on this computer, or on the Wi-Fi to try it on a phone; it reloads when the project changes. _Since 0.18.0._
- [`project.templates`](commands/project.md#projecttemplates): List the project templates `project.create` can start from.
- [`project.test`](commands/project.md#projecttest-modifies-state): Run the project's JavaScript tests (tests/*.test.js) headless and return the report.
- [`project.validate`](commands/project.md#projectvalidate): Check the whole project for errors: project file, scenes, assets, input bindings, scripts, feedback file.

### [publish](commands/publish.md)

- [`publish.appstore`](commands/publish.md#publishappstore-modifies-state): Upload the iOS build (.ipa) or the Mac App Store package (.pkg) to App Store Connect (xcrun altool, macOS only). _Since 0.2.0._
- [`publish.epic`](commands/publish.md#publishepic-modifies-state): Upload the desktop exports to the Epic Games Store (BuildPatchTool UploadBinary, one artifact per platform). _Since 0.2.0._
- [`publish.gog`](commands/publish.md#publishgog-modifies-state): Upload the desktop exports to GOG (Galaxy Pipeline Builder build-game, one project file per platform). _Since 0.2.0._
- [`publish.googleplay`](commands/publish.md#publishgoogleplay-modifies-state): Upload the release Android App Bundle (.aab) to Google Play (fastlane supply). _Since 0.2.0._
- [`publish.itch`](commands/publish.md#publishitch-modifies-state): Upload the desktop exports to itch.io (butler push, one channel per platform). _Since 0.2.0._
- [`publish.microsoft`](commands/publish.md#publishmicrosoft-modifies-state): Upload the Windows MSIX package to the Microsoft Store (msstore publish). _Since 0.3.0._
- [`publish.steam`](commands/publish.md#publishsteam-modifies-state): Upload the desktop exports to Steam (steamcmd, one depot per platform). _Since 0.2.0._

### [render](commands/render.md)

- [`mesh.create`](commands/render.md#meshcreate-modifies-state): Create a procedural mesh from arrays and get its id for MeshRenderer.mesh. _Since 0.9.0._
- [`mesh.destroy`](commands/render.md#meshdestroy-modifies-state): Free a procedural mesh. _Since 0.9.0._
- [`mesh.info`](commands/render.md#meshinfo): Describe one procedural mesh: counts, bounds, submeshes and materials. _Since 0.9.0._
- [`mesh.list`](commands/render.md#meshlist): List the live procedural meshes of the running scene. _Since 0.9.0._
- [`mesh.save`](commands/render.md#meshsave-modifies-state): Write a procedural mesh as a .glb file that loads back as a normal model. _Since 0.9.0._
- [`mesh.update`](commands/render.md#meshupdate-modifies-state): Replace the data of a procedural mesh; arrays left out are kept. _Since 0.9.0._

### [review](commands/review.md)

- [`review.cleanup`](commands/review.md#reviewcleanup-modifies-state): Delete the candidate files a review pick moved away long ago, and the folders of sheets that were never finished. _Since 0.18.0._
- [`review.info`](commands/review.md#reviewinfo): The manifest of one review sheet (items, facts, the choice) and its picture. _Since 0.18.0._
- [`review.list`](commands/review.md#reviewlist): List the review sheets of the project, newest first, with what was picked. _Since 0.18.0._
- [`review.pick`](commands/review.md#reviewpick-modifies-state): Record which numbered thumbnail of a review sheet the person chose, and move the other candidates' files away (the pick itself deletes nothing; review.cleanup deletes the dropped files after 7 days, or never with droppedDays 0). _Since 0.18.0._
- [`review.sheet`](commands/review.md#reviewsheet-modifies-state): Show N candidates as ONE picture with big numbers (images, scenes, prefabs, level seeds, vector art, effects) so a person can answer with one number. _Since 0.18.0._

### [scene](commands/scene.md)

- [`bones.create`](commands/scene.md#bonescreate-modifies-state): Create a chain of Bone2D entities along points, under a parent. _Since 0.7.0._
- [`load.cancel`](commands/scene.md#loadcancel-modifies-state): Stop a background load, or drop the files a finished one read ahead. _Since 0.19.0._
- [`load.status`](commands/scene.md#loadstatus): Show the background loads: progress, items, bytes, errors. _Since 0.19.0._
- [`prefab.save`](commands/scene.md#prefabsave-modifies-state): Save an entity of the running world, with its children, as a prefab file.
- [`scene.ascii_edit`](commands/scene.md#sceneascii_edit-modifies-state): Edit the ASCII map of a level file (a scene.import_ascii args file) with operations instead of rewriting rows, then rebuild the level. _Since 0.2.0._
- [`scene.destroy`](commands/scene.md#scenedestroy-modifies-state): Destroy an entity and its children.
- [`scene.format`](commands/scene.md#sceneformat-modifies-state): Rewrite scene and prefab files in the canonical compact layout, without loading them.
- [`scene.get_entity`](commands/scene.md#sceneget_entity): Get one entity with every component field (including defaults and runtime values).
- [`scene.import_ascii`](commands/scene.md#sceneimport_ascii-modifies-state): Build a Tilemap level and the objects standing on it (coins, enemies, spawn points) from ASCII rows and a legend.
- [`scene.list_entities`](commands/scene.md#scenelist_entities): List entities (id, name, tags, components) with optional filters.
- [`scene.load`](commands/scene.md#sceneload-modifies-state): Replace the running scene with a scene file.
- [`scene.preload`](commands/scene.md#scenepreload-modifies-state): Read a scene's files in the background, so a later scene.load waits for nothing. _Since 0.19.0._
- [`scene.reload`](commands/scene.md#scenereload-modifies-state): Reload the current scene from disk (discards runtime changes).
- [`scene.remove_component`](commands/scene.md#sceneremove_component-modifies-state): Remove a component from an entity.
- [`scene.save`](commands/scene.md#scenesave-modifies-state): Save the running world to a scene file (current scene path by default).
- [`scene.set_component`](commands/scene.md#sceneset_component-modifies-state): Add a component to an entity (if missing) and set the given fields.
- [`scene.set_parent`](commands/scene.md#sceneset_parent-modifies-state): Move an entity under another entity, or to the top level of the scene. _Since 0.2.0._
- [`scene.spawn`](commands/scene.md#scenespawn-modifies-state): Create an entity from entity JSON, or instantiate a prefab at a position.
- [`skin.auto_weights`](commands/scene.md#skinauto_weights-modifies-state): Write the skin's automatic weights out as explicit ones, to paint over with skin.set_weights. _Since 0.7.0._
- [`skin.bind`](commands/scene.md#skinbind-modifies-state): Skin a Sprite to bones: add the SpriteSkin, name its bones and bind it at the pose they have now. _Since 0.7.0._
- [`skin.set_weights`](commands/scene.md#skinset_weights-modifies-state): Paint the bone weights of chosen vertices: set, add or smooth. _Since 0.7.0._
- [`tilemap.cell_at`](commands/scene.md#tilemapcell_at): The cell of a Tilemap under a world point (orthogonal squares or isometric diamonds). _Since 0.3.0._
- [`tilemap.cell_to_world`](commands/scene.md#tilemapcell_to_world): The world position of the centre of a Tilemap cell (orthogonal squares or isometric diamonds). _Since 0.3.0._
- [`tilemap.generate`](commands/scene.md#tilemapgenerate-modifies-state): Generate a level from an example with Wave Function Collapse: a grid that only contains the patterns of the sample. _Since 0.17.0._
- [`tilemap.generate_cancel`](commands/scene.md#tilemapgenerate_cancel-modifies-state): Drop a generation started with tilemap.generate_start and free its memory. _Since 0.17.0._
- [`tilemap.generate_start`](commands/scene.md#tilemapgenerate_start-modifies-state): Check the arguments of tilemap.generate and start a generation that you advance yourself with tilemap.generate_step. _Since 0.17.0._
- [`tilemap.generate_step`](commands/scene.md#tilemapgenerate_step-modifies-state): Advance a generation started with tilemap.generate_start by a bounded amount of work. _Since 0.17.0._
- [`tilemap.paint_terrain`](commands/scene.md#tilemappaint_terrain-modifies-state): Paint (or erase) a terrain on a Tilemap's cells and re-tile the cells around them with its autotile rules. _Since 0.16.0._
- [`tilemap.retile`](commands/scene.md#tilemapretile-modifies-state): Re-tile every terrain cell of a Tilemap from its neighbours. _Since 0.16.0._
- [`tilemap.set_terrains`](commands/scene.md#tilemapset_terrains-modifies-state): Set a Tilemap's autotile rules from a list or a rules file (as image.tileset.build writes them). _Since 0.16.0._
- [`tilemap.set_tile`](commands/scene.md#tilemapset_tile-modifies-state): Change one tile of a Tilemap in the running scene, in place. _Since 0.3.0._
- [`tilemap.terrains`](commands/scene.md#tilemapterrains): The autotile rules of a Tilemap: its terrains, their slots and how many cells belong to each. _Since 0.16.0._

### [screen](commands/screen.md)

- [`screen.set_safe_area`](commands/screen.md#screenset_safe_area-modifies-state): Pretend the device has a notch, rounded corners or system bars (a notched phone, headless). _Since 0.2.0._

### [script](commands/script.md)

- [`script.errors`](commands/script.md#scripterrors): List script errors (load/runtime) and scene load problems.
- [`script.eval`](commands/script.md#scripteval-modifies-state): Evaluate JavaScript in the running game context (REPL) and return the value, or call an exported function of a module.
- [`script.reload`](commands/script.md#scriptreload-modifies-state): Re-import script modules edited on disk and restart the behaviours (the world is kept).
- [`script.trace`](commands/script.md#scripttrace): Debug scripts: run the game headless and record the stack, locals and watch expressions each time chosen lines run. _Since 0.2.0._
- [`storage.clear`](commands/script.md#storageclear-modifies-state): Delete one storage key (`key`) or all of them (`all`) from the game's memory and from the save folder. _Since 0.4.0._
- [`storage.list`](commands/script.md#storagelist): List the keys of the game's save storage (storage.set): the ones the running game holds and the key files in the save folder. _Since 0.4.0._

### [setup](commands/setup.md)

- [`setup.install`](commands/setup.md#setupinstall-modifies-state): Install what an export needs: the Android JDK + SDK, the players of other platforms, CMake, the AppImage tools, sokol-shdc, the VS Code debugger extension, ffmpeg, the app launcher (or open Xcode's App Store page). _Since 0.1.4._
- [`setup.status`](commands/setup.md#setupstatus): Check what this computer has for exporting: the Android JDK and SDK, the players of other platforms, CMake, Xcode, the AppImage tools, sokol-shdc, the VS Code debugger extension, ffmpeg, the FactorIA app launcher. _Since 0.1.4._

### [shader](commands/shader.md)

- [`shader.compile`](commands/shader.md#shadercompile): Compile a custom material's GLSL snippet for the dialects of some platforms and report errors with file, line and fixes. _Since 0.2.0._

### [sign](commands/sign.md)

- [`sign.macos`](commands/sign.md#signmacos-modifies-state): Sign, notarize and staple the exported macOS app (Developer ID), or sandbox and sign it as a .pkg for the Mac App Store. _Since 0.2.0._
- [`sign.windows`](commands/sign.md#signwindows-modifies-state): Sign the Windows MSIX package (and the exe) with a code-signing certificate, to install it outside the Microsoft Store. _Since 0.3.0._

### [skills](commands/skills.md)

- [`skills.list`](commands/skills.md#skillslist): List the skills (topic guides) available to a role: name, description, where each lives. _Since 0.11.0._
- [`skills.new`](commands/skills.md#skillsnew-modifies-state): Create a skill: skills/<name>/SKILL.md in the project (or in ~/.factoria/skills). _Since 0.11.0._
- [`skills.read`](commands/skills.md#skillsread): Read a skill: its SKILL.md instructions, or another file of the skill. _Since 0.11.0._

### [ui](commands/ui.md)

- [`ui.caption`](commands/ui.md#uicaption-modifies-state): Show a subtitle line on the Captions component for a few seconds. _Since 0.2.0._
- [`ui.check_layout`](commands/ui.md#uicheck_layout-modifies-state): Load each screen in each language and text size and list every text that overflows its box, overlaps another text or leaves the screen. _Since 0.2.0._
- [`ui.clear_captions`](commands/ui.md#uiclear_captions-modifies-state): Remove every subtitle from the screen now. _Since 0.2.0._
- [`ui.set_mirror_rtl`](commands/ui.md#uiset_mirror_rtl-modifies-state): Turn the mirroring of the screen-space UI in a right-to-left language on or off. _Since 0.3.0._
- [`ui.set_scale`](commands/ui.md#uiset_scale-modifies-state): Set the interface scale: every screen-space widget and Text gets bigger or smaller. _Since 0.3.0._
- [`ui.set_slider`](commands/ui.md#uiset_slider-modifies-state): Set a Slider the way a drag does: clamped, snapped to step, and ui.change is sent. _Since 0.3.0._
- [`ui.set_text_scale`](commands/ui.md#uiset_text_scale-modifies-state): Set the text size option: screen-space Text and the labels of UI widgets get bigger or smaller. _Since 0.2.0._
- [`ui.speak`](commands/ui.md#uispeak-modifies-state): Say a line aloud with the system's text to speech (or record it, headless). _Since 0.2.0._
- [`ui.state`](commands/ui.md#uistate): List the UI widgets on screen (Panel, Button, Toggle, Slider, TextField, ScrollList, TouchStick, TouchButton, and screen-space Text) and which has focus. _Since 0.1.6._
- [`ui.stop_speaking`](commands/ui.md#uistop_speaking-modifies-state): Stop what is being said by ui.speak and drop the queued lines. _Since 0.2.0._

