# How to build a game with FactorIA (for AI agents)

Read this guide before you change a FactorIA game. Read it by section, never whole: `factoria docs read ai-guide --heading Index` (over MCP `docs_read {"name":"ai-guide","heading":"Index"}`) says which section holds what. This page keeps the essentials (sections 1 to 3) and the Index; the rest lives on the pages under `docs/ai-guide/`, linked in the Index. The `AGENTS.md` in your project repeats the short rules.

Every name here is part of this build's contracts. Check a name before you use it: `factoria api --md` lists every component field, `factoria commands` lists every command and its arguments (`factoria commands scene.spawn` shows one), and `factoria docs search <words>` searches these docs. Over MCP use `docs_components`, `docs_commands` and `docs_search`. Do not guess component fields or command arguments. An entry marked `Deprecated since X - use Y` (or `@deprecated` in the typings, a `deprecated` object in the JSON) still works, logs a warning that names its replacement, and is removed two minor versions later: use the replacement in new code.

## Index

Pages of this guide (the page name for `docs_read` is `ai-guide-<name>`; a heading is found on its page by itself, so `docs_read {"name":"ai-guide","heading":"9.4"}` works):

- [tools](ai-guide/AI_GUIDE_TOOLS.md): sections 4 to 7. Tools and CLI, skills, coordinates and units, scene and prefab files, component cheat-sheet.
- [scripts](ai-guide/AI_GUIDE_SCRIPTS.md): sections 8, 9.1 to 9.7. The JavaScript API, then platformer, top-down, spawning, HUD, collisions, camera, sounds and music.
- [tilemaps](ai-guide/AI_GUIDE_TILEMAPS.md): section 9.8. Tilemap levels, objects and tile collision.
- [recipes-world](ai-guide/AI_GUIDE_RECIPES_WORLD.md): sections 9.9 to 9.21.1. 3D scene, save data, levels, particles, patrol AI, 3D cameras and physics, glow, sweeps, 2D water and glass.
- [recipes-ui-assets](ai-guide/AI_GUIDE_RECIPES_UI_ASSETS.md): sections 9.22 to 9.25. Menus, art/sound/model pipeline, game menus, animated characters, analytics.
- [recipes-production](ai-guide/AI_GUIDE_RECIPES_PRODUCTION.md): sections 9.26 to 9.32. 2D production, enemy AI, multiplayer, split screen, render targets, game feel, choices.
- [checks](ai-guide/AI_GUIDE_CHECKS.md): sections 10 to 14. Tests, debugging and replays, common mistakes, performance, where to read more.

Read one section with `docs_read {"name":"ai-guide","heading":"<title>"}` (CLI: `factoria docs read ai-guide --heading "<title>"`): a part of the title is enough ("9.4", "Split screen"). Entries are `title -- what it holds`; the bracket after an entry names the page that holds it (the list above), and no bracket means this page.

- 1. Mental model -- entities, components, scripts, scenes
- 2. The development loop -- edit, validate, step, look, repeat
- 3. THE FEEDBACK RULE (mandatory) -- record every engine gap
- 4. Using the MCP tools and the CLI -- tool table by category, examples, notices [tools]
- 4.1 Skills: topic guides you read when the task needs one -- long guides [tools]
- 5. Coordinates, units and conventions -- axes, pixels, angles [tools]
- 6. Scene and prefab files -- JSON formats, ids, overrides [tools]
- Saving a prefab from the running game, and keeping files tidy [tools]
- 7. Component cheat-sheet -- the common components [tools]
- 8. Scripts: behaviours and the JavaScript API -- lifecycle, world, events [scripts]
- 9. Recipes -- copy-ready solutions, 9.1 to 9.32 [scripts]
- 9.1 Platformer character [scripts]
- 9.2 Top-down movement [scripts]
- 9.3 Spawning prefabs and entities [scripts]
- 9.4 HUD pinned to the screen corners [scripts]
- 9.5 Collisions, triggers and one-way platforms [scripts]
- 9.6 Camera follow with level bounds [scripts]
- 9.6.1 A strategy camera (drag, edges, wheel zoom to the cursor) [scripts]
- 9.7 Sounds and music [scripts]
- 9.8 Tilemap levels, objects and tile collision [tilemaps]
- 9.9 3D scene with a light and fog [recipes-world]
- 9.10 Save data [recipes-world]
- 9.11 Changing levels [recipes-world]
- 9.12 One-shot particle effects [recipes-world]
- 9.13 Coin pickup from the player [recipes-world]
- 9.14 Patrol AI: turn at walls and ledges [recipes-world]
- 9.15 Cross-scene state with `session` [recipes-world]
- 9.16 Level data in JSON imports [recipes-world]
- 9.17 3D chase camera [recipes-world]
- 9.18 3D rolling ball and moving platforms [recipes-world]
- 9.19 3D ground checks and raycasts [recipes-world]
- 9.20 Neon glow, exposure and tonemap: additive blend and the PostProcess stack [recipes-world]
- 9.20.1 Colour-blind players: the colour filter and the colour-blind check [recipes-world]
- 9.21 Sweep a shape instead of a ray: will it fit, how far can it go [recipes-world]
- 9.21.1 Water, heat haze and glass in 2D: the picture drawn so far [recipes-world]
- 9.22 A menu: buttons, sliders, focus and the gamepad [recipes-ui-assets]
- 9.23 Art, sounds and models: generate, import, ship [recipes-ui-assets]
- 9.24 Game menus: main menu, options, credits, loading screen, pause [recipes-ui-assets]
- 9.25 Animated characters, state machines and tweens [recipes-ui-assets]
- 9.25.2 Building a character in parts, and animating it with commands [recipes-ui-assets]
- 9.25.1 Analytics with consent and remote config [recipes-ui-assets]
- 9.26 2D production: flipped tiles, 9-slice, lights, parallax, joints [recipes-production]
- 9.27 Enemies that think and find their way: `bt` plus `nav.findTilePath` [recipes-production]
- 9.28 Local multiplayer: one player per pad or key block [recipes-production]
- 9.29 Split screen: two or four players, one camera each [recipes-production]
- 9.30 A camera in a texture: a screen on a model, a mirror, a book with working pages [recipes-production]
- 9.31 Game feel: shake, hit-stop, flash, knockback, squash [recipes-production]
- 9.32 Show choices: make N, show ONE sheet, ask for ONE number [recipes-production]
- 10. Tests -- `*.test.js`, the test API [checks]
- Physics and platforms -- the same physics on every platform [checks]
- 11. Debugging, live sessions and replays [checks]
- 11.1 Stateful debugging: `factoria session` and `call --batch` [checks]
- 11.2 Input replays [checks]
- 11.3 Other checks [checks]
- 11.4 REVIEW.md: make the game easy to review [checks]
- 11.5 Play the game yourself: `play.auto` [checks]
- 12. Common mistakes -- read before you finish [checks]
- 13. Performance -- budgets and profiling [checks]
- 14. Where to read more -- other docs and skills [checks]

## 1. Mental model

A game is a folder of text files:

```
my-game/
  factoria.json           project settings: display, physics, input actions, main scene, icon and per-platform export settings (docs: exporting)
  scenes/*.scene.json     levels: entities with components
  prefabs/*.prefab.json   reusable entities (optional)
  scripts/*.js            behaviours: game logic as JavaScript classes
  tools/*.js              project tools: commands you (and other AIs) can call
  plugins/<name>/         native plugins: C/C++ code for this game, plugins.<name>.<fn>() in scripts (optional; docs: extending, G)
  tests/*.test.js         headless tests
  data/*.json             level or balance data, imported from scripts (optional)
  assets/                 images, sounds, fonts, models (only when you need them)
  types/factoria.d.ts     generated script typings (do not edit)
  AGENTS.md               short guide for AI agents, written by `factoria new`
  ENGINE_FEEDBACK.json    engine gaps you met (see THE FEEDBACK RULE)
  .factoria/              generated output: screenshots, logs (do not edit; scratch files go in .factoria/tmp/)
```

- **Components are data.** An entity has a stable `id`, optional `name` and `tags`, and components such as `Transform`, `Sprite` or `RigidBody2D`. Engine systems (rendering, physics, audio, scripts) read them.
- **Behaviours are JavaScript.** Logic lives in classes that extend `Behaviour`. Attach one with the `Script` component: `"Script": {"path": "scripts/player.js", "props": {"speed": 300}}`. `props` override the class fields, so one script serves many entities.
- **Commands are tools.** Every engine capability is a named command, such as `scene.spawn`. Over MCP the name has `.` replaced by `_`: `scene_spawn`. The file `tools/spawn_wave.js` becomes the command `project.spawn_wave` and the MCP tool `project_spawn_wave`.
- **The simulation is fixed-step and deterministic.** It runs at `physics.fixedHz` steps per second (60 by default). The same seed and the same input give the same result, so tests are reliable. On a display faster than the simulation, `"render": {"interpolation": true}` in `factoria.json` draws every entity between its last two steps so movement is smooth at 120-144 Hz (the `Interpolation` component overrides it per entity, `entity.teleport()` marks a jump; docs/RENDERING.md, "Render interpolation").

## 2. The development loop

Repeat it for every change. Make small steps: change one thing, validate, run, look.

1. **Read.** `factoria docs read scripting` for the script API, `factoria api --md` for components, `factoria docs search "..."` for the rest. Over MCP: `docs_list`, `docs_read {"name":"scripting"}`, `docs_components`, `docs_search {"query":"..."}`.
2. **Edit** scenes, prefabs, `scripts/`, `tools/`, `tests/`, `data/` or `factoria.json`.
3. **Validate.** `factoria validate` (MCP: `project_validate`). Fix every error using its file, JSON pointer and hint. Run `factoria validate --fix-types` when the typings are out of date (it rewrites `types/factoria.d.ts`). It must be clean before you go on.
4. **Run and LOOK.** `factoria run --headless --frames 120 --screenshot-at 119 --json` (MCP: `game_step {"frames":120}`, then `game_screenshot`). The report lists the PNG paths. Open the image and check that it shows what you intended. `scriptErrors` in the report and `game_logs` show script problems. A clean validation does not prove that the scene is right. Fine detail (a seam, a join, the end of a gradient) needs a closer look: `game_screenshot {"region":[x,y,w,h],"zoom":8}`; an animation needs a filmstrip (`{"frames":24,"everyFrames":4}`); `docs_commands {"name":"game.screenshot"}` lists all its arguments.
5. **Test.** Add or update a test in `tests/*.test.js` for every behaviour. Run `factoria test` (MCP: `project_test`). A bug fix starts with a test that fails.
6. **Debug the live game** when a test is not enough: `factoria session` keeps one game running and answers one JSON request per line (section 11).
7. **Report gaps** as soon as you meet them (section 3).

Done means: `project_validate` is clean, a screenshot shows the intended result, the tests pass and cover the new behaviour, and every engine gap you met is recorded in `ENGINE_FEEDBACK.json`.

## 3. THE FEEDBACK RULE (mandatory)

Whenever the engine lacks a feature, has a bug, gives an error that does not say how to fix it, or has a wrong or missing doc, **and** you build a workaround or drop the feature: record it now, in the same turn, before you continue. Do not wait until the end of the task. Duplicates are fine: a similar open entry in the same category is merged, and its `occurrences` count goes up. Not reporting is the only wrong choice.

**Check that the gap is real before you file it.** A report that calls missing something the engine has is useless and is refused: models often invent gaps for a component field or a command that exists. Search first (`docs_search`, `docs_components` for the fields of the component you mean, the `reference` pages), or call `feedback_check {title, missing, suggestion}` (CLI `factoria call feedback.check`). `feedback_report` runs the same check and REFUSES the report, naming what exists, its doc string and the page that documents it. If the thing exists but does not work as documented, file a **bug**: say what you set, what you expected and what happened. A request for an extra option on an existing component is fine. An entry that slips through is later set to status `rejected` with a reason (by the engine, you, or the engine developer): read it in the editor's Feedback panel.

Call the MCP tool `feedback_report`, or run `factoria call feedback.report '{...}'`, or run `factoria feedback add --category ... --severity ... --title ... --missing ... --workaround ...` (`--missing` needs a few words, not one). All three write to `ENGINE_FEEDBACK.json`.

| Field | Value |
|---|---|
| `category` | one of: rendering-2d, rendering-3d, physics, audio, input, ui, scripting, scene, assets, animation, tooling, ai-integration, docs, platform, performance, networking, other |
| `severity` | `blocker` (could not build it), `major` (large or fragile workaround), `minor` (small workaround), `nice-to-have` (convenience) |
| `title` | short noun phrase, such as "No adaptive triggers". Reuse the same wording for the same gap. |
| `missing` | what you needed and what the engine did instead |
| `workaround` | what you did instead, with `workaroundFiles` (project-relative paths) |
| `suggestion` | the engine change that would remove the workaround: a field, a command or an API |

The tool requires `category`, `severity`, `title`, `missing` and `workaround`. Always add `workaroundFiles` and `suggestion` as well, because the engine team needs them. `effort` (`small`, `medium`, `large`) and `reporter` (`{"kind":"ai","agent":"...","model":"..."}`) are optional. Call `feedback_list {"status":"open"}` (or `factoria feedback list --status open`) to see what is already recorded.

Include `share` (`{title, missing, suggestion?, workaround?}`) in every report, and `reviewed: true` once you checked the docs: a copy of the gap for the engine developer, in engine terms only (component, field and command names; never the game's names, file names, paths or quotes). Check the docs first so the gap is real. Only an entry with `share` goes out by itself (in the user's Always mode); for one without it the editor's Send feedback window can only make a text from your entry's own words, which is less exact than yours. Whether anything is sent is the user's choice, for all their projects or for this one alone (`factoria feedback sharing always|ask|never`, with `--project <dir>` for one project; `feedback.share_status` shows the mode that applies here); no command changes it, so if `feedback_report` answers that sharing is not set up, tell the user once how to turn it on. `feedback.share_preview` shows what would be sent. Write `share` in engine terms and, if you can, run `ai.review_feedback {id}` after `feedback_report`: a cheap model checks that the gap is real, about the engine and not possible yet, rewrites the text if needed and marks the entry `reviewed` (on a fail it says what to change; it never sends anything). Guide: ENGINE_FEEDBACK.md, "Sharing with the engine developer".

Good example, a missing input feature:

```json
{
  "category": "input",
  "severity": "minor",
  "title": "No adaptive triggers",
  "missing": "The game wants the DualSense triggers to resist when the bow is drawn, but scripts have no trigger-effect API.",
  "workaround": "none: feature dropped. The draw is shown with a camera zoom only.",
  "suggestion": "Add input.gamepad(i).setTriggerResistance(side, start, strength) that stiffens one trigger."
}
```

Good example, a missing scene feature:

```json
{
  "category": "scene",
  "severity": "minor",
  "title": "No flip or rotate flags for single tiles",
  "missing": "A Tilemap tile index always draws the tile upright, so a mirrored slope or a rotated corner needs its own copy in the tileset image.",
  "workaround": "assets/tiles.png has a mirrored copy of every slope tile; the map uses those indices.",
  "workaroundFiles": ["assets/tiles.png", "scenes/level1.scene.json"],
  "suggestion": "Let a tile entry carry flipX, flipY and rotate flags, for example as bits of the tile index."
}
```

Bad example:

```json
{
  "category": "other",
  "severity": "major",
  "title": "It does not work",
  "missing": "stuff",
  "workaround": "changed it"
}
```

It passes the schema and is still useless. The title names no gap, `missing` does not say what was needed, the workaround names no file, and there is no suggestion, so the engine team cannot act on it. Write each entry so that a developer who has never seen your project understands the gap.

`ENGINE_FEEDBACK.json` holds the open entries. Closed ones (`fixed-in-engine`, `wont-fix`, `duplicate`, `rejected`) move to `ENGINE_FEEDBACK.archive.json` next to it when the editor opens the project or `factoria feedback archive` (command `feedback.archive`) runs. Do not edit the archive by hand. Reporting a gap that matches an archived `fixed-in-engine` entry reopens it with a note "reported again ...: regression?". `feedback.list` with `includeArchive` (CLI: `feedback list --archive`) shows the archived entries too.

**Efficiency feedback (after a long run, not during it).** The engine lacked nothing, but one stretch of your work cost many steps, minutes or tokens that a doc, a topic guide, an example or an option on a command would have saved (a system you understood only after forty steps, a doc read five times, ten calls where one would do). Run `factoria ai retrospective` (the Feedback panel's Retrospective button, MCP tool `ai_retrospective`): it measures your transcripts in `.factoria/ai/sessions`, and the fast role files at most three entries of `kind: "efficiency"` that pass the gate. You can also file one with `feedback_report` and `kind: "efficiency"`, naming the span of steps (`evidence`); the engine computes the numbers, you never write them. The gate refuses, with the reason and what to do instead: no measured span, a saving under the threshold of its fix, a fix that is not the cheapest one that works, text added to AGENTS.md that costs more than it saves, a "missing guide" for a doc that `docs_search` finds, a lesson that is true only for this game (a project fact), and a different model, effort or limit (the user's settings). The thresholds, three reports that pass and three that are refused, with the gate's words: ENGINE_FEEDBACK.md, "Efficiency feedback".

Without MCP and without the CLI, add an object to the `entries` array of `ENGINE_FEEDBACK.json` by hand. It must match `schemas/engine-feedback.schema.json`, which also requires `id` (`FB-0001`, the next free number), `date`, `occurrences` and `status`. The tools set those for you, so prefer them.
