# Game menus: main menu, options, credits, loading screen, pause

New projects start with a camera and nothing else. When a game needs menus, the kit gives it the usual set in a
few steps: a main menu, options (video, a colour filter for colour-blind players, audio per bus, controls, language), credits that list the software inside
the runtime, a loading screen and a pause menu. Everything works with only a keyboard, only a mouse or only a gamepad,
and the player's settings are saved between runs.

FactorIA's own tests run exactly these files, driven with gamepad presses only. The kit lives in the FactorIA install
as `templates/menus/` (it is not a project template: `factoria new` does not list it), and one command copies the parts
a game wants and merges their texts into its string tables. The widgets and `ui` events the files use are in the AI guide
(section 9.22) and in `docs.components` (`Panel`, `Button`, `Toggle`, `Slider`, `ScrollList`).

## Pages

The reference is split by topic (every heading keeps its name, so `docs.read menus --heading <name>` finds it on its page):

- [How it works, and what to change](menus/MENUS_HOW.md): What each part of the kit does and what to change in it, including editing a TextField (caret, selection, clipboard, IME).
- [Recipes: slots, anchors, widgets, tooltips, charts and more](menus/MENUS_RECIPES.md): Save slots, text speed, anchors, gamepad cursor, choice cards, widgets from entities, tooltips, drag and drop, charts, a camera in the UI, a studio intro.

## Add the kit with a command

```bash
factoria call project.add_menu_kit                              # every part
factoria call project.add_menu_kit '{"parts":["pause","loading"]}'   # only these (and what they need)
```

(`project_add_menu_kit` over MCP.) Every file goes to the same path in the game, so the paths in the steps below are the
paths in your project. The parts, in the order of `templates/menus/kit.json`:

| Part | Files | Strings |
|---|---|---|
| `core` | `scripts/settings.js`, `scripts/ui/menu_stack.js`, `scripts/ui/read_aloud.js` | `menu.*` |
| `options` | `prefabs/ui/options.prefab.json`, `scripts/ui/options.js` | `options.*` |
| `textSpeed` | none (a row of the options prefab) | `options.textSpeed`, `options.speed.*` |
| `credits` | `scripts/ui/credits.js` | `credits.*` |
| `shop` | `scripts/ui/shop.js`, `scripts/store_events.js` | `shop.*` |
| `ageGate` | `prefabs/ui/age_gate.prefab.json`, `scripts/ui/age_gate.js`, `tests/age_gate.test.js` | `ageGate.*` |
| `analyticsConsent` | `prefabs/ui/analytics_consent.prefab.json`, `scripts/ui/analytics_consent.js`, `tests/analytics_consent.test.js` | `analyticsConsent.*` |
| `main-menu` | `scenes/menu.scene.json`, `scripts/main_menu.js`, `tests/recipe.test.js` | none of its own |
| `pause` | `prefabs/ui/pause.prefab.json`, `scripts/pause_menu.js` | `pause.*` |
| `loading` | `scenes/loading.scene.json`, `scripts/loading.js` | `loading.*` |
| `keyboard` | `prefabs/ui/keyboard.prefab.json`, `scripts/ui/keyboard.js` | `keyboard.*` |
| `slots` | `scripts/slots.js`, `scripts/ui/slot_screen.js`, `prefabs/ui/slots.prefab.json`, `prefabs/ui/slot_dialog.prefab.json`, `tests/slots.test.js` | `slots.*` |
| `dialogue` | `scripts/dialogue.js` | `captions.*` (sample lines) |
| `card` | `prefabs/ui/card.prefab.json`, `scripts/ui/card.js`, `tests/card.test.js` | `card.*` |
| `cameraRig` | `scripts/camera_rig.js`, `tests/camera_rig.test.js` | none |

A part brings the parts it needs: `pause` adds `core` and `options`, `textSpeed` adds `core` and `options` (and without it `options.prefab.json` has no `text_speed` row), `slots` adds `core` and `keyboard`, `ageGate` and `analyticsConsent` add `core`, `card` needs nothing else, `main-menu` adds `core`, `options` and `credits`. `cameraRig` is not a menu: it is the strategy camera of AI_GUIDE.md section 9.6.1, shipped in the kit because it is added the same way (it adds its `camera_*` input actions to `factoria.json`). The result
lists them in `requiredBy`. The shop, the age gate and the analytics question are optional for the main menu: with no `parts` (everything) it has the Shop button, the shop
panel and the lines that open the age gate and the analytics question; `{"parts":["main-menu"]}` writes a main menu without them (no `shop_button`, `shop`,
`age_gate` or `analytics_consent` in the scene, no import of `age_gate.js` or `analytics_consent.js` in `scripts/main_menu.js`), and
`{"parts":["main-menu","shop"]}`, `["main-menu","ageGate"]` or `["main-menu","analyticsConsent"]` adds just that one.
Adding a part to a game that already has the main menu changes `scenes/menu.scene.json` and `scripts/main_menu.js`: they are listed in `skipped`
(the game's files are never touched) until you pass `overwrite: true` or add the button, panel and lines yourself, as in steps 7 and 8.

- **Files.** A file the game does not have is `added`. One that is already the kit's file is `unchanged`, so running the
  command twice changes nothing. One the game has edited is left alone and listed in `skipped` with the reason, unless
  you pass `overwrite: true`, which replaces it (`overwritten`). Scenes and prefabs are written in the canonical layout
  of `scene.format`.
- **Texts.** The kit's strings are merged into `locales/<language>.json` for every language in `factoria.json`
  `"localization"`: keys the game does not have are added (listed per file in `locales[].merged`), a key it has is never
  replaced, with or without `overwrite`. The kit ships English, Spanish and Arabic; any other language gets the English
  text, which reads better than a key name until a translator replaces it (`locales[].note` says so; see
  [LOCALIZATION.md](LOCALIZATION.md)). A game without a `"localization"` section gets one with English.
- **factoria.json.** Only what the kit needs and the game lacks: the `localization` section above, and the `pause`
  input action for the `pause` part. `settings[]` in the result says what changed.
- **What is left to you** (`nextSteps[]`): the start scene and the first level, the entity with `pause_menu.js` in every
  level, the actions the options let the player rebind. These are the steps below; the command does not guess them.
- **Check.** `tests/recipe.test.js` ships with the `main-menu` part: it opens the menu itself and drives it with a
  gamepad, so it passes whatever `mainScene` is. Run `factoria validate` and `factoria test`.

## Steps

What the command does, file by file; do it by hand when you want to see each file or the command is not at hand.

1. **factoria.json.** Start on the menu, and add a `pause` action:
   `"mainScene": "scenes/menu.scene.json"` and, in `input.actions`, `"pause": ["Escape", "P", "GamepadStart"]`.
2. **Shared scripts.** `scripts/settings.js` keeps the player's settings in `storage` and applies them once per run;
   `scripts/ui/menu_stack.js` opens panels over each other and goes back.
3. **Main menu and credits.** `scenes/menu.scene.json`, `scripts/main_menu.js` and `scripts/ui/credits.js`. Put the
   game's name in the `title` Text and its first level in `MainMenu.firstScene`.
4. **Options.** `prefabs/ui/options.prefab.json` and `scripts/ui/options.js`. The Controls tab lists every action the game has in
   `input.actions` except the `ui_*` ones, labelled with the string `options.action.<action>` (the action's own name when the
   game has no such string). To pick and order them, set the `actions` property of the prefab's Script:
   `"Script": { "path": "scripts/ui/options.js", "props": { "actions": ["move", "dig", "place"] } }`; an action the game does
   not have gets no row. A game with local multiplayer (several people on one machine, each on their own pad or key
   block with `input.player(i)`) sets `"players": 2` (up to 4) in the same `props`: the Controls tab gets a "Player N" button
   on top, and each player rebinds their own keys and pad buttons, saved by player.
   The Graphics tab (the last one) lets the player pick the quality of the screen effects (`high` leaves the game's own look,
   `medium` turns off the costly ones: SSAO, SSR, depth of field, motion blur, sun shafts, radial blur; `low` also bloom, film grain,
   lens distortion and sharpen; `off` all the optional ones) and switch bloom, film grain, vignette, chromatic aberration and
   outlines one by one, a "2D lighting" button (Off, Low, Medium, High: it sets `enabled` and `quality` of every `GlobalIllumination2D`
   of the scene and of the scenes loaded later, saved as `settings.graphics.lighting2d`; until the player chooses it is `null`, the
   scene keeps its own values and the button shows them; the cycle starts from what the scene shows, so a `GlobalIllumination2D` with `enabled: false` and `quality: "medium"` shows Off and the next click is Low; on `game.platform` `ios`, `android` and `web` the engine's cascade budget turns High off (docs/rendering/RENDERING_2D_GI.md), so the button cycles Off, Low and Medium there and a saved High is applied as Medium; a game with its own scenes calls `settings.applyScene()` when each starts, as for `PostProcess`, and a scene's own High shows as Medium there; a 2D scene (one with a `Sprite`, or once the player has chosen) without a `GlobalIllumination2D` shows the choice and the tab's note says it has no effect there, while a 3D scene shows no lighting note; the lighting and HDR notes show together when both apply; `settings.lightingShown(s, platform)` is what the button shows for settings `s` on a platform, and `settings.overrideRenderSupports(fn)` is a test hook that answers `renderSupports(feature)` with `fn(feature)`, null restores the renderer), plus HDR output where `render.supports {"feature":"hdrOutput"}` says the display can show it (greyed out
   otherwise). It writes the `PostProcess` fields of the scene's cameras and volumes (exposure, tonemap, grading, the colour filter
   and fog are never touched), saves `settings.graphics` (`{quality, effects, hdr, lighting2d, preset, detected, upscaler, renderScale}`) in the same `settings` storage entry, and
   `settings.applyScene()` puts it on every scene that starts. Choosing a quality clears the switches the player touched; a
   switch wins over the quality. The menu scripts call `settings.applyOnce()` when their scene starts, so the choice reaches the
   `PostProcess` components the scene has at that moment: one a script adds or changes later is not touched until the player
   changes a Graphics setting again (or the game calls `settings.applyScene()` after it). `tests/graphics.test.js` checks it.
   **Second page: preset and upscaling.** The "Preset and upscaling" button of the tab (`gfx_page`) swaps its content for a second page
   (`quality_section`, with a Back button, `gfx_page_back`; the tab always opens on the first page): a **Preset** row (`gfx_preset_*`:
   Auto, Low, Medium, High, Ultra, Custom), an **Upscaling** row (`gfx_mode_*`: Auto, Stretch, Spatial, Temporal, MetalFX, DLSS, XeSS, FSR), a button
   that cycles the upscaling quality (`gfx_uq`: native, quality, balanced, performance, ultra performance), a render scale slider
   (`gfx_render_scale`, 0.33 to 1, two decimals) and a sharpness slider (`gfx_sharpness`, active only while the mode that draws is not
   plain stretch). The selected button of each row is highlighted. A mode this GPU does not draw (`render.supports`:
   `spatialUpscaler`, `temporalUpscaler`, `metalfx`, `dlss`, `xess`, `fsr`) is greyed out and the one note under the rows lists every such mode with its reason (not one note per button: "Spatial: needs a window with a GPU"), in the player's language: modes that share a reason (XeSS and FSR: "needs the vendor runtime on Windows") are named together, the names are joined with the locale's `options.gfx.listSep` (", " or "، " in Arabic) and the groups with `options.gfx.groupSep` ("; " or "؛"). The sharpness slider shows hundredths. A choice is applied first (`render.upscaler`, `render.latency`, `render.frameGeneration`) and saved in `settings.graphics` only when the engine accepted it: a refused call is logged, saves nothing and the page redraws with what is really on.
   **Auto** (the preset) runs `game.graphics.detect()` once, applies its pick, saves it as `detected` and shows it on the button;
   it does not detect again until the save is cleared. **How it relates to the "quality" row:** the preset drives it. Choosing Low,
   Medium, High or Ultra sets the screen-effects quality to low, medium, high and high and clears the effect switches the player
   touched, then applies the preset (`game.graphics.preset`); Custom leaves the quality as it is. Choosing a quality on the first
   page does not change the preset, so the two rows never fight: the preset is the engine's limits layer (shadows, reflections,
   level-of-detail distances...), the quality is this kit's post-effects row. An upscaler or render scale choice made on the page
   is the player's own setting and stays over the preset; choosing a preset again puts the preset's own back. Everything is
   saved in `settings.graphics` (`{quality, effects, hdr, lighting2d, preset, detected, upscaler, renderScale, dynamicResolution, latency, frameGeneration}`; `upscaler`, `latency` and `frameGeneration` hold
   only the keys the player chose, `renderScale` and `dynamicResolution` are `null` until chosen) and applied by `settings.applyOnce()` at start and on
   every change; a save from before these keys loads and changes nothing. The **Dynamic resolution** row (`gfx_dynamic`, in
   `gfx_dynamic_slot`, hidden where `render.supports` says it is not drawn) is one button that cycles Off, 30 fps, 60 fps and the
   display's refresh and sets `window.dynamicResolution` (docs/UPSCALING.md, "Dynamic resolution"); the choice is saved as the
   string `"off"`, `"30"`, `"60"` or `"display"`, and a save without it leaves the game's own setting untouched. The **Low latency** rows (docs/LATENCY.md) are the third page of the Graphics tab (`latency_section`, opened by `gfx_latency_page` on the second page, `gfx_latency_back` returns): the buttons `gfx_latency_off`, `_auto`, `_reflex`, `_antilag2` and `_xell` (`settings.LATENCY_MODES`) and the switch `gfx_latency_boost`, shown for the modes that have one (`settings.latencyHasBoost`). A mode this machine cannot run (`render.supports`: `reflex`, `antilag2`, `xell`) is greyed out and listed with its reason in the page's note (`latency_note`); the choice is applied with `render.latency` at once, saved as `settings.graphics.latency` (`{mode, boost}`, only the keys the player chose) and applied again at each start, and a save without it leaves the game's own setting (`factoria.json` `render.latency`) alone. The **Frame generation** rows (docs/FRAME_GENERATION.md) are the fourth page (`framegen_section`, opened by `gfx_fg_page` next to `gfx_latency_back` on the third, `gfx_fg_back` returns): the buttons `gfx_fg_off`, `_auto`, `_dlss`, `_fsr` and `_xess` (`settings.FRAMEGEN_MODES`), the slider `gfx_fg_minfps` (0 to 240 in steps of 1, greyed out while the mode is off; `settings.FRAMEGEN_DEFAULT_MIN_FPS` is 60) and the note `framegen_note`. A mode this machine cannot run (`render.supports`: `dlssFrameGen`, `fsrFrameGen`, `xessFrameGen`) is greyed out and its reason is in the note; the note also shows the state `render.frame_generation` reports (refused, measuring, paused below the minimum, active) and, while a mode is on with `render.latency` off, advice to pick a low-latency mode (for DLSS, that DLSS-G turns Reflex on itself). The choice is applied at once, saved as `settings.graphics.frameGeneration` (`{mode, minBaseFps}`, only the keys the player chose, `settings.setFrameGeneration`) and applied again at each start; a save without it leaves the game's own `render.frameGeneration` alone. The engine's provider owns the swapchain: a game that started with the mode off cannot turn one on at run time, and the note then shows the engine's refusal (restart the game). The second to fourth pages fit the options panel at 1280x720 (the layout tests
   `menus_rtl` and `menus_text_scale` guard it in English, Spanish and Arabic).
   The options panel is 760x636 (title 32, padding 14, `quality_section` 448 high, `graphics_section` 468), so the second to fourth pages of the Graphics tab (the eight upscaling buttons and the grouped note
   included) and the other tabs fit a 1024x642 window in English, Spanish and Arabic (`menus_rtl`
   checks it); the first page of the tab (the effects) needs 1280x720. A game that also shows the analytics row (an `analytics` section in factoria.json) or longer notes can still
   outgrow a small screen (the Back button stays visible, the log warns that the panel is larger than the screen); such a game
   lowers `spacing` of `graphics_section` or shortens its notes.
5. **Loading screen.** `scenes/loading.scene.json` and `scripts/loading.js`: it loads the first level in the background
   (`scene.load` with `{ async: true }`) and shows the real progress.
6. **Pause.** `prefabs/ui/pause.prefab.json`, `scripts/pause_menu.js`, and one entity in every level scene:
   `{ "id": "pause_menu", "components": { "Script": { "path": "scripts/pause_menu.js" } } }`.
7. **Shop (only when the game sells things).** `scripts/ui/shop.js` and the `shop` panel and `shop_button` of
   `scenes/menu.scene.json`, with the products declared in `factoria.json` `"platform"`
   ([PLATFORM.md](PLATFORM.md)). Without a store (the exported game before a store plugin is added) the button stays
   hidden; a game with nothing to sell leaves the `shop` part out (`parts` without it: the button, the panel and the script are not
   written; by hand, delete them and the three `shop` lines of `main_menu.js`). One entity with
   `scripts/store_events.js` in every level pauses the game while the store's overlay is open.
8. **Age gate (only for ads that reach children and adults).** `prefabs/ui/age_gate.prefab.json`, `scripts/ui/age_gate.js`, the
   `age_gate` panel of `scenes/menu.scene.json`, and the line in `main_menu.js` that opens it; all of them come with the `ageGate` part, and a
   game whose ads do not reach children and adults leaves it out. See "Age gate" below.
9. **On-screen keyboard (only for a game with a TextField).** `prefabs/ui/keyboard.prefab.json` and
   `scripts/ui/keyboard.js`, and one entity with that script in every scene that has a TextField (`keyboard_host` in
   `scenes/name.scene.json`). See "On-screen keyboard" below.
10. **Analytics question (only for a game with an `"analytics"` section).** `prefabs/ui/analytics_consent.prefab.json`,
   `scripts/ui/analytics_consent.js`, the `analytics_consent` panel of `scenes/menu.scene.json`, the line in `main_menu.js` that opens it and the
   `analytics_toggle` switch of the options panel (that one comes with `options`); see "Analytics question" below and [ANALYTICS.md](ANALYTICS.md).
11. **Languages.** `factoria.json` `"localization"`, one `locales/<language>.json` per language, and a `key` on every
   Text and widget the scenes and prefabs write ([LOCALIZATION.md](LOCALIZATION.md)). The scripts take their
   texts from the tables (`i18n.t`), so a game with one language keeps the section with that language and
   `locales/en.json`: `"localization": { "defaultLanguage": "en", "languages": ["en"] }`.
12. **Check.** `factoria call scene.format '{"paths":["scenes","prefabs"]}'` (the demo scene below is written short; it rewrites it in the canonical
   layout), `factoria validate`, a screenshot of the menu (`factoria run --headless --frames 3 --screenshot-at 2`),
   and a test that drives the menus with the pad, such as `tests/recipe.test.js` (`docs.read menu-kit/tests/recipe.test.js`) and `tests/keyboard.test.js` at the end of this page. `ui.state` lists every
   widget with its rectangle, focus and value.

## The files

The kit's files are not copied into this page: they are in the FactorIA install (`templates/menus/`), the same ones
`project.add_menu_kit` writes and FactorIA's own tests run, so what you read is always what the command copies.

- `docs.read {"name":"menu-kit"}` lists them with their sizes (`docs.list` names it too); on the command line
  `factoria docs read menu-kit`.
- `docs.read {"name":"menu-kit/scripts/ui/options.js"}` reads one (`factoria docs read menu-kit/scripts/ui/options.js`);
  a long file comes in parts like any page (`startLine`, `maxLines`). `kit.json` says which files make each part.
- A game that changes a file adds the part with `project.add_menu_kit` and edits its copy; it never needs to paste a
  file from here.

Two files are not part of the kit. They belong to the demo of FactorIA's tests (the menus project
`tools/cli/tests/fixtures/menus` in the repository, which holds a copy of every kit file too), and a test keeps their
text here equal to the demo's. The scene is printed in a shorter layout than the canonical one `scene.format` writes.


### `scenes/name.scene.json`

```json scenes/name.scene.json
{
  "format": "factoria.scene/1",
  "entities": [
    {
      "id": "camera",
      "components": {
        "Transform": {
          "position": [640, 360, 0]
        },
        "Camera": {
          "clearColor": [0.1, 0.12, 0.18, 1]
        }
      }
    },
    {
      "id": "name_box",
      "components": {
        "Panel": {
          "anchor": [0.5, 0.5],
          "color": [0, 0, 0, 0],
          "layout": "column",
          "spacing": 14,
          "fit": true
        }
      },
      "children": [
        {
          "id": "name_title",
          "components": {
            "Text": {
              "text": "Your name",
              "key": "name.title",
              "fontSize": 40,
              "space": "screen"
            }
          }
        },
        {
          "id": "name_field",
          "components": {
            "TextField": {
              "size": [420, 56],
              "placeholder": "Name",
              "key": "name.placeholder",
              "maxLength": 12,
              "fontSize": 28,
              "autoFocus": true
            }
          }
        },
        {
          "id": "name_next",
          "components": {
            "Button": {
              "autoSize": true,
              "text": "Continue",
              "key": "name.next"
            }
          }
        }
      ]
    },
    {
      "id": "keyboard_host",
      "components": {
        "Script": {
          "path": "scripts/ui/keyboard.js"
        }
      }
    }
  ]
}
```



### `tests/keyboard.test.js`

```js tests/keyboard.test.js
import { test, expect, game } from "factoria:test";
import { input, ui } from "factoria";
import { keysFor } from "../scripts/ui/keyboard.js";

// A player with only a gamepad types a name through the on-screen keyboard (scripts/ui/keyboard.js).
const pad = game.gamepad(0);
const field = () => game.find("name_field").get("TextField");
const open = () => game.find("keyboard").activeInHierarchy;

/** Walks the d-pad to the key that shows `ch` (the keys are a grid of 10 columns) and presses A. */
function typeKey(ch, chars) {
  const target = chars.indexOf(ch);
  const at = Number(ui.focused.id.slice("osk_key_".length));
  const dx = (target % 10) - (at % 10);
  const dy = Math.floor(target / 10) - Math.floor(at / 10);
  for (let i = 0; i < Math.abs(dx); i++) pad.tap(dx > 0 ? "DpadRight" : "DpadLeft");
  for (let i = 0; i < Math.abs(dy); i++) pad.tap(dy > 0 ? "DpadDown" : "DpadUp");
  expect(ui.focused.get("Button").text).toBe(ch);
  pad.tap("A");
}

/** Moves the focus from a key down to the row of Shift, Space, Delete and Done, then along it to `id`. */
function toAction(id) {
  for (let i = 0; i < 8 && ui.focused.id.startsWith("osk_key_"); i++) pad.tap("DpadDown");
  const order = ["osk_shift", "osk_space", "osk_delete", "osk_done"];
  for (let i = 0; i < 4 && ui.focused.id !== id; i++) pad.tap(order.indexOf(id) > order.indexOf(ui.focused.id) ? "DpadRight" : "DpadLeft");
  expect(ui.focused.id).toBe(id);
}

test("the keyboard stays closed until a pad is used, then types a name with the pad alone", () => {
  game.load("scenes/name.scene.json");
  game.step(2);
  expect(ui.focused.id).toBe("name_field"); // autoFocus at the start: the last input was not a pad
  expect(open()).toBe(false);
  pad.tap("DpadDown"); // to the button ...
  pad.tap("DpadUp"); // ... and back to the field with the pad: the keyboard opens
  expect(open()).toBe(true);
  expect(ui.focused.id).toBe("osk_key_0");

  const chars = keysFor("en");
  const changes = [];
  const stop = ui.on("change", "name_field", (e) => changes.push(e.value));
  pad.tap("A"); // "a", the first key
  typeKey("m", chars);
  pad.tap("A"); // another m
  toAction("osk_shift");
  pad.tap("A"); // upper case from now on
  pad.tap("DpadUp"); // back to the keys
  typeKey("Z", chars.map((c) => c.toUpperCase()));
  expect(field().text).toBe("ammZ");
  stop();
  expect(changes).toEqual(["a", "am", "amm", "ammZ"]);

  // Done closes the keyboard, sends ui.submit like Enter, and the focus goes back to the field without reopening it.
  const submitted = [];
  ui.on("submit", "name_field", (e) => submitted.push(e.value));
  toAction("osk_done");
  pad.tap("A");
  game.step(3);
  expect(submitted).toEqual(["ammZ"]);
  expect(open()).toBe(false);
  expect(ui.focused.id).toBe("name_field");
  expect(game.find("name_next").get("Button").interactable).toBe(true); // the menu behind the keyboard is back

  // A on the field opens it again; B closes it and keeps the text.
  pad.tap("A");
  expect(open()).toBe(true);
  pad.tap("B");
  expect(open()).toBe(false);
  expect(field().text).toBe("ammZ");
});

test("the keys follow the language and the field's maxLength", () => {
  expect(keysFor("es")).toContain("ñ");
  expect(keysFor("pt-BR")).toContain("ã");
  expect(keysFor("ru")[0]).toBe("а");
  expect(keysFor("el")[0]).toBe("α");
  expect(keysFor("ar")).toEqual(keysFor("en")); // a script with no keys of its own gets the Latin ones
  game.load("scenes/name.scene.json");
  game.step(2);
  field().text = "123456789012"; // maxLength 12: full
  pad.tap("DpadDown");
  pad.tap("DpadUp");
  pad.tap("A"); // "a" does not fit
  expect(field().text).toBe("123456789012");
});

test("a platform keyboard takes the field: the on-screen keyboard stays closed", () => {
  game.load("scenes/name.scene.json");
  game.step(2);
  // The engine sets input.platformKeyboard when a native plugin (the Steam Deck's) shows its own keyboard for the focused field.
  const engineGetter = Object.getOwnPropertyDescriptor(input, "platformKeyboard");
  Object.defineProperty(input, "platformKeyboard", { get: () => true, configurable: true });
  try {
    pad.tap("DpadDown");
    pad.tap("DpadUp"); // back to the field with the pad: the platform keyboard is up, this one is not
    expect(ui.focused.id).toBe("name_field");
    expect(open()).toBe(false);
    pad.tap("A"); // A on the field asks the platform again, not this keyboard
    expect(open()).toBe(false);
  } finally {
    Object.defineProperty(input, "platformKeyboard", engineGetter);
  }
});
```
