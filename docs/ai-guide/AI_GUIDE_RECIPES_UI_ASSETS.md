# AI guide: recipes for menus, assets and animation

Part of [AI guide](../AI_GUIDE.md): recipes 9.22 to 9.25: menus, art, sounds and models, game menus, animated characters, analytics.

### 9.22 A menu: buttons, sliders, focus and the gamepad

Widgets (section 7, UI) are entities in screen space. A `Panel` with `layout: "column"` stacks its children; the first
item has `autoFocus` so the keyboard and the gamepad work from the first frame. A scene (`scenes/menu.scene.json`) with a
title, two buttons and a volume slider:

```json
{
  "format": "factoria.scene/1",
  "entities": [
    { "id": "cam", "components": { "Camera": {} } },
    { "id": "menu", "name": "Main menu",
      "components": {
        "Transform": { "position": [0, 0, 0] },
        "Panel": { "anchor": [0.5, 0.5], "size": [360, 300], "layout": "column", "spacing": 12, "padding": [20, 20, 20, 20] } },
      "children": [
        { "id": "title", "components": { "Text": { "text": "My Game", "fontSize": 36, "space": "screen", "pivot": [0.5, 1] } } },
        { "id": "play_button", "components": { "Button": { "text": "Play", "size": [260, 56], "autoFocus": true } } },
        { "id": "volume", "components": { "Slider": { "label": "Volume", "value": 0.8, "size": [320, 44] } } },
        { "id": "quit_button", "components": { "Button": { "text": "Quit", "size": [260, 56] } } }
      ] }
  ]
}
```

```js
// scripts/menu.js, on the "menu" entity
import { Behaviour, ui, scene, game, audio } from "factoria";

export default class Menu extends Behaviour {
  onStart() {
    this.on("ui.click", (data) => {
      if (data.id === "play_button") scene.load("scenes/level1.scene.json");
      if (data.id === "quit_button") game.quit();
    });
    this.on("ui.change", (data) => { if (data.id === "volume") audio.setVolume("master", data.value); });
  }
}
```

- **Navigation is automatic.** Up / down / left / right (keys, d-pad, left stick) move the focus to the nearest widget
  in that direction (widgets lined up with the focused one first, so Right along a row of tabs stays on the row),
  `ui_submit` (Enter, Space, pad A) clicks, `ui_cancel` (Escape, pad B) sends `ui.cancel`; the mouse works too. An entity made of sprites, shapes or text that is not a Button gets all of this with the `Interactable` component (docs/MENUS.md, "Widgets from your own entities"). Nothing is
  focused until an `autoFocus` widget or `ui.focus(entity)` takes the focus, which keeps Space / A (jump) from clicking HUD
  buttons during play. Tab and Shift+Tab (`ui_next`, `ui_previous`) walk the widgets in reading order from a focused one. Rebind the eight `ui_*` actions in `factoria.json` `input.actions` if you want other keys.
- **Looks.** A plain widget is a translucent dark rectangle with a label; give `texture` + `slice` (9-slice borders in
  texture pixels) for a themed one, and `color`, `textColor`, `accentColor` to restyle. Everything is design pixels, so
  `size`, `padding` and `spacing` do not change with the window size (only with the interface size, `ui.scale`, which the player may change); use `anchor` and `pivot` to pin a panel to a corner
  or the centre.
- **Lay out for every interface size.** Players choose the interface size (`ui.scale`, 0.5 to 3; the menu kit's Options has
  it) and the text size (`ui.textScale`). Anchor panels, let a `Panel` with `fit: true` grow with its rows (and give it
  `minSize` / `maxSize` for a look that does not jump with the language), `autoSize` on the widgets, a `ScrollList` with
  `fill` where the list may be long, and never space widgets with empty `Panel` or `Text` spacers or move them by hand
  when the size changes: `padding`, `spacing` and the layout already scale. Redo script maths with `ui.on("scale", ...)`
  and `ui.on("textScale", ...)`. Prove it with `ui.check_layout {"uiScales":[1,1.5], "textScales":[1,2]}` (`docs_read
  {"name":"text"}`, "Interface size").
- **Pause menu.** The UI keeps working while `game.paused` (`time.scale` 0); section 9.24 has the pause menu.
- **Find and click things from outside.** `ui.state` lists every widget with its `rect`, `focused` and `value`. Click with `game_click {"id":"play"}` (the centre of a widget), `{"position":[x,y]}` or `{"world":[x,y]}`: it moves the mouse, presses, steps one frame, releases and steps one more, so a script sees `input.mouse.pressed` and then `released`, and a Button sends `click`. `game_input {"mouse":{"position":[x,y],"left":true}}` followed by `game_step` also gives the script a press, but it leaves the button held until a call sets `left:false` (needed for a drag, not for a click). To test a menu without a mouse, tap the pad: `game.gamepad().tap("DpadDown")`,
  `.tap("A")`, then assert on `ui.focused`, widget values or `ui.on` events (see `SCRIPTING.md`, UI).
- **Long lists** go in a `ScrollList`: the wheel scrolls it, moving the focus to an item scrolls it into view, and
  everything inside is clipped to its rectangle.

### 9.23 Art, sounds and models: generate, import, ship

Never hand-draw placeholder art pixel by pixel through `fs.write`: generate it, import it, and let the export compress
it. The full reference is `docs/ASSETS.md` (`docs_read {"name":"assets"}`).

**Generate.** `assets.generate_image` writes a PNG at the size you ask for, records where it came from, and shows you the
picture: look at it, and ask again (`overwrite: true`) with a better prompt. The house style in `assets.json` (`style`:
`prompt`, `references`, `palette`) is applied to every image, so the art stays consistent; `style: false` skips it.

```json
{"prompt": "a knight, side view, idle", "path": "assets/knight.png", "width": 64, "height": 64, "transparent": true}
```

A character that moves is a sprite sheet: `assets.generate_sprite_sheet {"prompt":"a knight walking right","path":"assets/knight_walk.png","frames":6,"columns":3,"frameWidth":64,"frameHeight":64,"fps":10}`
normalizes the grid and records it, and its result gives the components to use: `Sprite {texture}` and `SpriteAnimator
{columns, rows, firstFrame, lastFrame, fps}` on one entity. Sounds and music: `assets.generate_sound` and
`assets.generate_music` (`prompt`, `path`, `seconds`; the extension is the one the provider makes, the error names it),
speech: `assets.generate_voice {text, path, voice}`, models: `assets.generate_model {prompt, path}`; use them as the
`clip` of an `AudioSource` and the `mesh` of a `MeshRenderer`.

- **Providers.** They are configured by the user in `ai.json` (`assets` section). If a kind has none, the error shows what to
  add; do not edit `ai.json` yourself, tell the user. `provider: "fake"` works offline and makes small placeholders: use it
  to build and test the flow, then ask the user which real provider to use. Generation costs money: one call, look, then
  decide; never loop over variations.
- **What it costs, and asking.** Every generate result carries `estimatedCostUsd` (an ESTIMATE from the provider's price table,
  not an invoice; 0 for `fake` and local programs) and the project's limits (`limits.maxAssetCostUsd.perRun` and `.perDay`)
  refuse a call that would pass them, with an error that says which. A call estimated above `limits.askAboveUsd` (default
  $0.50), or small calls that add up above it since the user last said yes, is not made (cutting a batch into small calls does
  not avoid the question): in the editor the user answers a card and the call goes on; over MCP or the CLI the command returns
  `{"needsApproval": true, "plan": {...}}`. **Then tell the user what will be made, how many, with which provider and the
  estimate, and ask. Only when they say yes, call again with the same arguments and `approved: true`. Never set `approved: true`
  yourself and never raise a limit or edit `ai.json` to avoid the question.** In the editor `approved` is ignored: the user
  answers on a card. If they say no (`asset_declined`; `cancelled` means they stopped the run, do not start it again),
  carry on without the asset (a placeholder from `assets.generate_texture`, `assets.rasterize_svg` or `fake`). The same holds for
  `image.inpaint` and `image.generate_layer`. See `docs_read {"name":"ai-costs"}`.
- **Provenance.** Every generate command records `origin`, `ai`, provider, model, prompt and license in `assets.json`. Files
  you did not generate get a record with `assets.set_provenance {path, origin: "original" | "imported", ai, license, source}`
  (`ai: true` for something made with AI elsewhere). `assets.provenance {}` lists the records and the files that have none.
- **Store disclosure.** Before a release, `assets.disclosure` returns the AI-content text for Steam's survey; `factoria export`
  writes it as `AI_CONTENT_DISCLOSURE.md`. Fix the "Assets without provenance" list first.
- **Tests.** A test project uses the `fake` provider, so the check is offline and deterministic.

**The review loop: make, preview, check, fix.** Never accept a picture because it was generated: look at it the way the player
will, measure it, fix it, and repeat until the check has no `fail`.

1. **Make** it (`assets.generate_image`, `assets_generate_texture`, `assets_rasterize_svg`, `assets.import`, or an edit of the file).
2. **See** it. `assets.contact_sheet {"paths":["assets/knight.png","assets/orc.png"]}` puts a set side by side at its on-screen
   size over the game's backgrounds, light and dark, and in greyscale. `assets.preview_in_scene {"path":"assets/knight.png","scene":"scenes/level1.scene.json"}`
   places it in a copy of a real scene and returns screenshots at phone and desktop resolutions. Look at the picture; do not skip this.
   When the person must choose between candidates, put them on one numbered sheet (`review.sheet`) and ask for one number (section 9.32).
   For one asset the person chooses, make N in one call, show the one sheet it returns, ask for one number, then call `assets.pick`:
   `assets.generate_image {"prompt":"...","path":"assets/items/potion.png","count":3}` then `assets.pick {"slot":"assets/items/potion.png","n":<their number>}`.
   Only the newest sheet of a slot counts: after a regeneration, show the new sheet (a number given for an old one is refused as `superseded`).
3. **Check** it. `assets.check_art {"path":"assets/knight.png"}` gives numbers: palette fit, contrast over the real backgrounds,
   readability at the size the camera shows it, halos on alpha edges, pixel density and outline against the `style` rules of
   `assets.json`. Each rule has a verdict (`ok`, `warn`, `fail`) and a `hint` naming the command or setting that fixes it.
4. **Fix** what the hints say (regenerate with `overwrite: true` and a prompt that changes that one thing, edit the SVG, change a
   `style` value), then go back to 2. Stop when no rule is `fail` and the picture looks right in the scene. A `warn` is a
   judgement: fix it when it is cheap, or note why it is fine.
5. **Last look (optional).** With a vision model configured, `assets.review {"paths":[...],"focus":"..."}` compares the pictures
   with the style references and returns a `verdict` and concrete `fixes` (each with a command to use). It runs the check itself
   and costs one model call: use it once per asset or set, after the check is clean, not after every edit. If it fails with
   `no_model`, the user has no vision model set up: carry on with steps 2 to 4 and judge the pictures yourself.

Set the house style first (`assets.json` `style`: `prompt`, `references`, `palette`, `outline`, `lightDirection`,
`texelsPerUnit`, `pixelArt`, `value`, `saturation`; docs/ASSETS.md "House style"): the check and the review only judge what it says.

**Art without an image provider.** When `assets.generate_image` fails with `no_provider`, do not draw pixels by hand and do
not stop: the error lists which providers can make images and which keys would enable one (tell the user which), and two
commands make art offline, free, with a provenance record:

```
assets_generate_texture {"path":"assets/textures/desk.png","preset":"planks","width":1280,"height":720,"seed":4}
assets_rasterize_svg {"path":"assets/art/crest.png","width":256,"svg":"<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100'><path d='M50 6 L90 22 V52 C90 76 70 90 50 96 C30 90 10 76 10 52 V22 Z' fill='#8b1e1e' stroke='#e8c66a' stroke-width='4'/></svg>"}
```

- **Surfaces** (backgrounds, desks, covers, pages, floors, walls) are `assets_generate_texture`: `preset` is `paper`,
  `parchment`, `wood`, `planks`, `leather`, `fabric`, `linen`, `stone`, `value`, `fbm`, `cellular`, `gradient`, `radial` or
  `vignette`. `color` and `accent` recolour, `scale` and `roughness` tune, `tileable: true` makes it repeat with no seam,
  `normalMap: true` also writes `<name>_n.png` for lit sprites. Another `seed` is another take.
- **Subjects** (a crest, a silhouette, an ornament, a map symbol) are shapes you write as SVG for
  `assets_rasterize_svg`. `clip-path`, `mask` and `<pattern>` fills (line hatching) work; no text, filters, `<use>` or CSS classes (they are drawn as
  nothing and named in `warnings`); in gradients write coordinates in percent (`x2="100%"`). Keep the SVG in the project
  (`assets/art/crest.svg`, then `source`) so you can edit it and rasterize again.
- **Effects and animated art** you build from entities (Shape2D with gradients and strokes, particles, tweens, a scripted
  explosion) are baked into a sprite sheet with `assets_bake_sheet {"path":"assets/fx/burst.png","prefab":"prefabs/burst.prefab.json","frames":16,"fps":24}`:
  it plays the prefab alone in a private world and captures frames, and the sheet is one `Sprite` with a `SpriteAnimator`.
  **Bake effects to save draw calls on mobile**: a glow of five shapes or a burst of particles is many draw calls on every
  frame, a baked one is one. `clips` bakes named clips (`{"name":"die","call":"die"}` runs the behaviour's `die()`), `pivot`
  keeps the origin still (feet: `[0.5, 1]`), `frameWidth` / `frameHeight` fix the cell. Its `pivot` is counted from the
  top-left of the frame and `Sprite.pivot` from the bottom-left: set `Sprite.pivot` to `[x, 1 - y]`. It needs a GPU.
- **Edit the SVG, do not rewrite it.** Once a shape exists, `vector_boolean` (subtract a hole, merge parts), `vector_offset` (an inset line), `vector_stroke_to_path`, `vector_simplify`, `vector_smooth`, `vector_align`, `vector_distribute`, `vector_repeat` and `vector_style` change it in the file; `vector_shape`, `vector_blob`, `vector_mirror`, `vector_text_to_path` and `vector_shade` add a gear or a bubble, a mirrored half, a title as outlines and the shading and return a picture, keeping ids, groups and transforms (docs/VECTOR.md). A character drawn in named groups becomes an animatable rig with `vector_to_rig` (part atlas, joints from `<part>-pivot` shapes, a Bone2D prefab; docs/VECTOR.md, "Characters in parts").
- **Look at the picture** in the result, change one thing and call again with `overwrite: true`. The icon and the store
  images are `assets_draw_icon` and `assets_draw_capsules`; sounds are `assets_synth_sound`, or, to design one, a sound patch (`sfx_preset`, edit the `*.sfx.json`, `sfx_render`: docs/SOUND.md)). To change a recording or a render without losing the original (trim, fade, pitch, EQ, reverb, a seamless loop), write an audio document: `audio_create`, `audio_edit`, `audio_render`, `audio_bake` (`*.audio.json`, docs/SOUND.md "Audio documents"). Pixel art is an image document with `indexed` layers (docs/IMAGES.md, "Pixel art"); `image_pixel_outline`, `image_pixel_shade`, `image_pixel_dither`, `image_pixel_cleanup`, `image_pixel_rotate` and `image_pixel_scale` finish it palette-exactly (no blending), and `image_to_pixel_art` turns a painted layer or a PNG into such a layer ("Pixel helpers"). Music is composed as data: a song document `*.song.json` (tempo, key, tracks with an instrument and note text such as `C4:4 E4 G4 (Am7):2`, drum grids, sections intro/loop/outro): `music_create` writes a starting song, `music_edit` changes it, `music_check` finds notes out of key, clashes and loudness before you listen, `music_preview` renders a WAV and `music_info` draws a piano roll; `music_chord`, `music_scale`, `music_arpeggio`, `music_bassline` and `music_drums` write the parts for you (docs/MUSIC.md). A 3D model is built as data too: a model document `*.model.json` is a tree of primitives (box, rounded_box, cylinder, cone, sphere, capsule, torus, grid, stairs, arch, pipe, text), groups and transforms, with named parts, materials and vertex colours; `model_create` writes one (and bakes it to a `.glb`), `model_info` lists the operations and fields or checks and measures a document, `model_edit` adds, changes, moves or removes a node by its id, and `model_bake` builds the `.glb` (docs/MODELING.md).
- **Provenance** is recorded: a texture is `original` (not AI); an SVG you wrote counts as AI-made unless you pass
  `ai: false`. These are plain materials and vector shapes: say so to the user, who may want a real provider (or an
  artist) for the final art.

**Animations drawn with code.** Motion that follows rules (a coin that turns, a pulsing orb, a flame, a loader, rain, waves, a
UI sparkle) is code, not a drawing: `assets_animate_svg` bakes it into a sprite sheet and its `sheet` entry in one call, with
no provider and no key. Write a module `art/coin_spin.anim.js` whose default export returns the SVG of one frame from
`{t, frame, frames, fps, progress, params, rng}`, then bake it:

```
assets_animate_svg {"path":"assets/art/coin_spin.png","source":"art/coin_spin.anim.js","frames":12,"fps":12,"frameWidth":64,"padding":1,"params":{"face":"#f2c94c","back":"#b8902b"}}
```

- **Pick the way to make the motion.** Rule-based motion that stays inside a picture (spin, bob, pulse, sparkle, flicker,
  waves, loaders, a UI shimmer): draw it with code (`assets_animate_svg`). It is deterministic, small, editable (change the
  module and bake again) and free. Something the engine already animates (Shape2D, tweens, particles, scripts, a prefab that
  moves): bake it from the engine into a sheet instead of redrawing it (`assets_bake_sheet`), or just play it live. Painted
  frame-by-frame art, characters with a drawn style, anything a rule cannot express: ask an image provider (the cost is
  one call per sheet: look, then decide); with no provider, tell the user.
- **Write `progress`-driven frames.** `progress` is `frame / frames` for a looping clip, so the last frame leads into the first;
  do not use `t` for a loop unless the period divides the clip. `rng()` changes every frame (flicker); `rngFor("key")` is the same
  on every frame (what must stay put). In an `assets_animate_svg` module (and only there) `Math.random` is a seeded
  stream and `Date` a fixed day; in a game script `Date` is the real clock.
- **Look and fix.** The result has the sheet as an image, the layout and warnings (a frame that draws nothing, shapes on the
  cell edge, a loop that jumps). An error names `art/coin_spin.anim.js:LINE:COL` and the frame; the module sees only the
  language (no engine API, no DOM, no files), so take data from `params`. `clips` makes `idle` and `run` from one module; `pivot`,
  `padding`, `palette` (snap to the game's colours) and `style` (the painterly look of `assets_rasterize_svg`) are arguments.
- **Recolour and layers.** `ramp` (2 to 32 colours from dark to bright, or an image document with `ramps`) reaches the module as
  `ramp` and `rampAt(u)`, so one effect is recoloured by baking again with another `ramp`; `rampMap: true` recolours the finished
  frames by brightness (for a SMIL SVG or a module that draws in greys). `layers: ["back","front","light"]` bakes one sheet per layer
  (`hit_back.png`, `hit_front.png`, `hit_light.png`) from the same module, which receives `layer`: put `back` at a lower
  `Sprite.layer` than the character, `front` at a higher one and `light` with `Sprite.blend` `additive`, all with the same clip.
  Add `prefab` (`"prefab": "prefabs/hit.prefab.json"`, or an object with `size`, `layers` {back, front, light} as Sprite.layer
  numbers, `tags`, `name`) and the same call writes that parent with its three children, the clip and the blend, so you do not
  write them by hand; it never replaces an existing prefab unless the object has `overwrite: true`. When `factoria.json`
  targets android or ios, a sheet whose width or height is not a multiple of 4 is a warning that names the `padding` that
  fixes it (GPU compression needs multiples of 4): bake with that padding the first time.
- **SMIL.** If you already have an animated SVG (`<animate>`, `<animateTransform>`, `<animateMotion>`), give it as `svg` (or as a
  project `.svg` in `source`): it is sampled at each frame; what cannot be sampled (click events, CSS animations) is a warning.
- **Provenance** is recorded as AI-made unless you pass `ai: false`, with a `recipe` (the module and its imports, hashed) that
  makes the same sheet again.

**Importing.** A file made elsewhere (downloaded, from an artist, exported from a tool) comes in with `assets.import`
(MCP tool `assets_import`). It copies or converts the file into `assets/` and records the provenance in `assets.json`:

```
assets_import {"source":"C:/art/hero.aseprite","license":"CC-BY 4.0","author":"Ana Lopez"}
```

- **Say where it came from.** Pass `license` and `author` for anything you did not make (the credits and the store
  disclosures read them), `ai: true` for what an AI made, and `sourceUrl` for the page you downloaded it from. A URL is
  not read: download the file first. `path` picks the destination (a path under `assets/`, or a folder ending in `/`).
- **Formats.** Aseprite becomes an image document with its layers, frames and tags (baked to a sprite sheet whose clips are the tags; `flat: true` makes only the PNG sheet), PSD a layered image document (`*.image.json`, one PNG per layer) baked to a PNG, OBJ (with its MTL and textures) a `.gltf`,
  FBX a `.glb` (through FBX2glTF or Blender; the error says where to get one), a video (`.mp4`, `.mov`, `.webm`...) an
  `.mpg` (MPEG-1 + MP2, through ffmpeg: `factoria setup ffmpeg`) for the `Video` component. Images, sounds, fonts, GLB and
  glTF are copied. Not read: `.blend`, WebP, GIF, SVG (`assets_rasterize_svg` makes the PNG). The full list is in `docs_read {"name":"assets"}`.
- **Check a sheet before wiring it in.** `assets_preview_sheet {"path":"assets/art/coin_spin.png","clip":"spin","onion":true}` draws the labelled grid (frame numbers, cell edges, pivot) and warns about empty frames, ink on the edge of a cell and a loop that jumps; play the clip by name with `SpriteAnimator {"clip":"spin"}`.
- **Read `nextSteps` and `warnings`.** They hold the `Sprite` and `SpriteAnimator` fields to use for a sheet (columns,
  rows, first and last frame, fps), the size of a model, and what could not be carried over (the direction of a tag, blend
  modes, a missing texture).
- **A sheet that is not a clean grid** (frames of different sizes, a solid background, as generated and downloaded
  sheets often are): `assets_slice_sheet {"path":"assets/walk_raw.png","auto":true,"frames":8,"align":"bottom","background":"auto"}`
  finds the sprites, repacks them into a uniform grid, writes `walk_raw_sheet.png` and returns the SpriteAnimator
  fields. A regular grid you know: `{"path":"assets/walk.png","columns":4,"rows":2}` checks it against the image and
  records it.

**Shipping textures.** A mobile `factoria export` compresses every texture to a KTX2 twin (`assets/hero.png.ktx2` replaces
`assets/hero.png`; names in scenes and scripts do not change; import setting `compression`). Set `"atlas": "ui"` in a
texture's import settings (`assets.json`) to have the export pack that group into one atlas image, for sprites,
particles and UI widgets only (not tilesets or mesh textures; validate warns). `factoria run` keeps using your PNGs. Details:
`docs/ASSETS.md` > Textures.

**Shipping audio.** Audio ships with three import settings (`assets.json`, `docs_read {"name":"assets"}` "Import
settings > Audio"): `stream` (`auto` streams sounds over 10 seconds; `always`/`never` force it), `normalize` with
`targetLufs` (play every sound at the same loudness, default -16 LUFS) and `convert: "qoa"` (the export ships WAV files
as `<path>.qoa`, about 5 times smaller; scenes and scripts keep the `.wav` name). Run `assets.analyze_audio` once after
adding sounds: it measures their loudness and keeps the result in `assets.json` (needed on mobile, where the engine
never measures), and `project_validate` warns about clipped, very loud, very quiet and unevenly loud sounds.

### 9.24 Game menus: main menu, options, credits, loading screen, pause

New projects have no menus. `factoria call project.add_menu_kit` (MCP `project_add_menu_kit {"parts":[...]}`, default all
parts; it never touches a file you changed unless `overwrite` is true and adds only the texts your locales lack) copies a
complete set into the game, and `factoria docs read menus` (MCP `docs_read {"name":"menus"}`) explains it. FactorIA's own
tests drive it with a gamepad only: a main menu, options (video, audio per bus, controls, language),
credits listing the software in `FACTORIA_NOTICES.txt`, a loading screen and a pause menu, with the settings saved
between runs. In short:

1. `factoria.json`: `"mainScene": "scenes/menu.scene.json"` and a `"pause": ["Escape", "P", "GamepadStart"]` action.
2. `scripts/settings.js` (settings in `storage`, applied once per run) and `scripts/ui/menu_stack.js` (panels over
   panels, back with B / Escape).
3. The main menu and credits: `scenes/menu.scene.json`, `scripts/main_menu.js`, `scripts/ui/credits.js`.
4. Options: `prefabs/ui/options.prefab.json`, `scripts/ui/options.js`.
5. The loading screen: `scenes/loading.scene.json`, `scripts/loading.js` (it loads the first level in the background with `scene.load(path, null, { async: true })` and shows the real progress).
6. Pause: `prefabs/ui/pause.prefab.json`, `scripts/pause_menu.js`, and one `pause_menu` entity in each level.
7. A shop, only for a game with in-app purchases: `scripts/ui/shop.js`, the `shop` panel and `shop_button` of the menu
   scene, and `scripts/store_events.js` (pauses the game while the store overlay is open). It uses the `platform`
   API (`factoria docs read platform`); the kit's `tests/platform.test.js` drives it against the fake store.
8. Languages: `factoria.json` `"localization"`, `locales/<language>.json` per language and a `key` on every Text and
   widget (`factoria docs read localization`); the kit's `tests/i18n.test.js` switches the language at run time.

When you write menus of your own, the same rules apply:

- **Panels over panels.** Show one panel and hide the one below with `active`: a focused widget that becomes inactive
  loses the focus and the new panel's `autoFocus` widget takes it. Remember `ui.focused` before, and `ui.focus(...)` it
  after closing, so the player lands where they were.
- **Pause.** `game.paused = true` freezes physics, animations and every behaviour without `runWhilePaused = true`; the
  UI keeps working. Unpause in the pause behaviour's next `onUpdate`, not in the "Resume" click handler, or the A /
  Space press that clicked it also jumps. `time.scale` outlives scene loads: set `game.paused = false` before
  `scene.load`.
- **A screen that owns the input.** `Panel.modal: true` on the root Panel of a dialog: while it is active only its widgets
  get the mouse, the wheel, the arrows and the pad, nothing under it is hovered, clicked or dropped on, and
  `ui.pointerOverUi` is true everywhere. The kit's `card` part is a choice card built on it (title, wrapped body, choices
  with a detail line, a choice disabled with its reason, a result stage, `holdClock`): `factoria docs read menus`, "A choice card".
- **Settings.** Keep them in `storage` and apply them when the game starts (`session` remembers that it was done).
  `window.*` setters throw when there is no window (headless runs, tests): check `window.available`.
- **Controls.** Rebind with `input.rebind(action, list)` from the next `input.lastPressed()`, and name buttons with
  `input.buttonName(action)` (Cross on a PlayStation pad, A on an Xbox pad).
- **Quit** has no place on phones and tablets: hide it when `game.platform` is `"ios"` or `"android"`.
- **Several languages.** Put the text of a game that may be translated in `locales/<language>.json` from the start and
  give the `Text` or widget a `key`: `{ "text": "Play", "key": "menu.play" }`. The engine overwrites `text` with the
  player's language, so a script never writes it; text a script builds uses `i18n.t(key, { count })` and is written
  again on `i18n.on("change", ...)`. `i18n.setLanguage(tag)` switches at once; the choice goes in `storage`.
- **Adding a language.** Add its tag to `localization.languages`, create `locales/<tag>.json` with the keys of the default
  language's table, list a font in `localization.languageFonts` when its script is not Latin, Greek, Cyrillic, Hebrew or
  Arabic (Noto Sans has one per script), and run `factoria validate`: it names missing keys, wrong placeholders and
  plural forms, `key`s no table has, and every character no font of the language can draw (`U+65E5 '日'`). To send the
  strings to translators, `factoria call i18n.export` writes a CSV or XLIFF file and `i18n.import` reads it back.

### 9.25 Animated characters, state machines and tweens

Full reference: `docs_read {"name":"animation"}` (docs/ANIMATION.md). A skinned glTF/GLB with named animation clips plays
through the `Animator` component, on the entity that has the model's `MeshRenderer`:

```json
{ "id": "hero", "components": {
    "MeshRenderer": { "mesh": "assets/models/hero.glb" },
    "Animator": {
      "clip": "Idle",
      "events": [{ "clip": "Run", "time": 0.25, "name": "footstep" }, { "clip": "Run", "time": 0.75, "name": "footstep" }],
      "params": { "speed": 0 },
      "states": { "idle": { "clip": "Idle" }, "run": { "clip": "Run" } },
      "transitions": [ { "from": "idle", "to": "run", "when": "speed > 0.1", "fade": 0.15 },
                       { "from": "run", "to": "idle", "when": "speed <= 0.1" } ] } } }
```

```js
hero.animator.set("speed", Math.abs(vx));                       // the state machine does the rest
hero.animator.play("Attack", 0.1);                                // or drive clips by hand: cross-fade 0.1 s
hero.animator.on("footstep", () => audio.play("assets/sounds/step.wav"));
```

Animation runs in the fixed step, so headless tests and replays match (`game.step(60)` then check
`hero.animator.state` / `.time`). `import { tween, ease } from "factoria"` moves any number, vector or color over time
(2D and 3D): `tween(panel.position, { x: 0 }, { duration: 0.4, ease: "backOut" })`, `await tween(...).finished`.
The model is drawn deformed on the GPU (up to 64 joints; more joints = bind pose plus a warning), shadows included.
Each animated model is its own draw call, so keep crowds of animated characters modest.

### 9.25.2 Building a character in parts, and animating it with commands

A 2D character made of separate parts (head, body, arms, legs) animates better than a flat sheet and you can fix one pose
without redrawing everything. The recipe, in order:

1. **Parts as child Sprites, pivots at the joints.** One entity per part under the character entity; the pivot of each Sprite is
   the point it turns around (the shoulder for an arm: `pivot [0.5, 1]` for an arm that hangs down), and the child's
   `Transform.position` is where that joint sits on its parent. Order the layers with `Sprite.layer` (the far arm and leg
   behind the body, the near ones in front). Names matter: clips find parts by the names from the character down (`"body/arm_l"`).
2. **Bones where a limb must bend** (a leg, a tail, a scarf), not for rigid parts: `bones.create {parent, points: [[0,40],[0,20],[0,0]],
   names: ["thigh","shin"]}`, then `skin.bind {entity: "leg", root: "thigh", mesh: [4, 8]}` skins the leg Sprite to them at the pose
   they have now. `skin.auto_weights` writes the automatic weights out and `skin.set_weights {vertices: {rect: [x0,y0,x1,y1]},
   bone: "shin", weight: 1}` paints them (`mode: "smooth"` blends the seams). Keep the grid small.
3. **IK for feet and hands** that must touch something: an `IK2D` on the last bone with `target` an empty entity, and let the
   clip move the target instead of the bones (`{"path": "foot_target", "field": "position"}`).
4. **Clips with commands.** `anim.create_clip` then `anim.set_keys`, one track per part and field; first and last key equal for a
   loop. Hook it up: `scene.set_component {id: "hero", component: "Animator", fields: {clips: {walk: "anim/hero_walk.anim.json"}}}`.
5. **Look, then check.** `anim.filmstrip {entity: "hero", clip: "walk", frames: 8, onionSkin: true}` draws the whole motion in one
   picture; judge the arc of the limbs and any jump between poses. `anim.check {entity: "hero"}` lists what is wrong in words
   (`loop_jump`, `unknown_part`, `leaves_view`, `ik_out_of_reach`, `no_change`). Fix with `anim.set_keys`, `anim.move_keys`,
   `anim.set_interp`; every command returns an `undo`. `factoria validate` repeats the file and part checks.

```json
{"command":"anim.create_clip","args":{"path":"anim/hero_walk.anim.json","duration":0.8,"loop":true}}
{"command":"anim.set_keys","args":{"path":"anim/hero_walk.anim.json","entity":"hero","track":{"path":"body/arm_l","field":"rotation.z"},
  "keys":[{"t":0,"value":-30},{"t":0.4,"value":30,"interp":"quadInOut"},{"t":0.8,"value":-30}]}}
{"command":"anim.set_keys","args":{"path":"anim/hero_walk.anim.json","entity":"hero","track":{"path":"body/arm_r","field":"rotation.z"},
  "keys":[{"t":0,"value":30},{"t":0.4,"value":-30,"interp":"quadInOut"},{"t":0.8,"value":30}]}}
{"command":"anim.set_keys","args":{"path":"anim/hero_walk.anim.json","entity":"hero","track":{"path":"body","field":"position.y"},
  "keys":[{"t":0,"value":0},{"t":0.2,"value":3},{"t":0.4,"value":0},{"t":0.6,"value":3},{"t":0.8,"value":0}]}}
{"command":"anim.add_event","args":{"path":"anim/hero_walk.anim.json","t":0.4,"name":"footstep"}}
{"command":"anim.filmstrip","args":{"entity":"hero","clip":"walk","frames":8,"onionSkin":true}}
{"command":"anim.check","args":{"entity":"hero"}}
```

Full reference: `docs_read {"name":"animation"}`, sections "2D clips", "Commands for clips" and "Bones and IK".

### 9.25.1 Analytics with consent and remote config

For a game that must count what players do or tune values without a new build ([ANALYTICS.md](../ANALYTICS.md); `docs_read {"name":"analytics"}`).
Nothing is sent before the player says yes, so ask first, and say in the privacy policy what is sent.

1. `factoria.json`: `"network": {"hosts": ["stats.example.com"], "purpose": "..."}`, `"analytics": {"endpoint": "https://stats.example.com/events"}`
   and, for values, `"remoteConfig": {"url": "https://stats.example.com/game.json"}`. `factoria validate` checks the hosts and the numbers.
2. The question: add the menu kit part `analyticsConsent` (`project.add_menu_kit {"parts":["analyticsConsent"]}`) or call
   `analytics.setConsent(true | false)` from your own button. `analytics.consent()` is `"unknown"` until the player answers.
3. Events: `analytics.event("level_done", { level: 3, won: true })` (flat props, short codes and numbers, never typed text). It returns `false` and keeps nothing
   without consent. Batches go out at `batch` events, after `flushSeconds`, on suspend and on quit (the quit waits up to 3 seconds).
4. Values: `remoteConfig.get("enemySpeed", 1.5)` always works (cache, then the fallback). To wait for the first answer at a loading screen,
   check that the scene is still current: `const here = scene.current; remoteConfig.ready().then(() => { if (scene.current !== here) return; ... })`.
5. Tests: `game.platform.respond("http.fetch", { status: 204 })` plays the server, `game.analytics.sent()` shows what it accepted, `game.analytics.queued()` what waits,
   `game.remoteConfig.restart()` starts a new run from the cache. A test that loads a main menu in a game with analytics sets the answer first
   (`analytics.setConsent(true)`), or the question is on screen.
