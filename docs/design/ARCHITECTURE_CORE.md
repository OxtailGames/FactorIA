# FactorIA architecture: the world and reflection

Part of [FactorIA architecture](ARCHITECTURE.md) (the entry page lists every page).

## World, entities, components
`fa::World` (engine/scene/include/fa/scene/world.h) stores entities (handles)
and reflected components in type-erased pools. Every entity has `EntityInfo`
(stable string `id`, `name`, `tags`, `active`) and `Transform`. Components are
plain data; systems in other modules read them. Pointers to components are
stable until removal. `destroy()` is deferred to the end of the frame (physics treats a
pending-destroy entity as gone at once: no body, no collisions, no query hits).

### The hierarchy cache
`World::world_matrix`, `world_position`, `active_in_hierarchy` and `pending_destroy` are answered from a cache kept per
entity, instead of walking the parent chain on every call (`engine/scene/src/world.cpp`, `World::Impl`):

- **What is cached**: the world matrix (the parent's world matrix times the local TRS, from the root down: the one
  definition of `world_matrix`, cached or not) and "active in hierarchy" (own `EntityInfo.active` and every ancestor's).
  `pending_destroy` is a flag `destroy()` sets on the whole subtree (a pending subtree takes no new child, so it stays true
  until the flush). `drawn_matrix` is the same product with the game feel poses and is not cached while one runs.
- **Invalidation**: every MUTABLE access to a `Transform` or an `EntityInfo` drops the entity's entry and, below it, the
  entries that are valid: `get<T>(e)` / `get(e, type)` / `add` / `info(e)` on a non-const `World`, each callback of
  `each<Transform, ...>` / `each<EntityInfo, ...>`, `set_parent` (the child's subtree), `set_world_position`,
  `set_active`. No setter of `Transform` is involved, so any way of writing (C++, scripts, reflection, commands, the
  inspector, animation) is seen. The cost of a write is one flag when the entry was already dropped. `create()` resets the
  entry of a reused entity index.
- **The UI layout offset**: the one thing besides Transform that goes into the local matrix. The UI layout (Panel,
  ScrollList) places a child by `World::set_ui_layout_offset(e, offset)`, a per-entity x/y kept in `World::Impl` (not a
  component: not saved, not in a snapshot, erased with the entity) and added to `Transform.position` when the local matrix is
  built (`world_matrix`, `drawn_matrix`). `set_ui_layout_offset` drops the entity's entry like a Transform write does, and the
  layout runs on the main thread before the render gather, so jobs never see it change. `Transform.position` of a laid-out
  child is the author's offset from the slot. Code that adds raw positions up the parents (`ui_layout_translation`,
  `ui_rect.h`) uses `position + offset`; `set_world_position` subtracts the offset.
  `set_parent` to the same parent (a reorder) touches neither the offset nor the Transform. To another parent it drops the
  offset (the placement belonged to the old parent; the next layout pass gives a new Panel parent's child a new one). With
  `keepWorld` the whole placed spot moves into `Transform.position`, so the child keeps its world place, except under a parent
  that lays its children out (`ui_layout_places`: a Panel with a layout or fallbackLayout, a ScrollList; the child a widget or
  a screen-space Text, Sprite or Shape2D): there x and y become 0 so the child lands in its slot, as it always did (rotation,
  scale and z are kept). `ui_layout_places` looks at the component type and the space only: the layout also skips an inactive
  child and one with no rectangle (a Text with no text, a Sprite with no size), which `ui_layout_places` still answers true for,
  so such a child gets position 0 without being placed. `scene.set_parent` says `positionReset: true` when it did this.
  `clear_ui_layout_offsets_except` erases the entries the layout did not just place, in place (the map is never copied to a list
  every frame); `drawn_local_matrix` is the local part of `drawn_matrix` (no parent inverse).
- **Rules for code**: read through a `const World&` (or `std::as_const(world).get<Transform>(e)`): a read through a mutable
  `World` counts as a write and throws the cache away for nothing (`resolve_obj` in the script bridge, the UI and render
  passes already read through const). A `Transform&` or `EntityInfo&` KEPT from an earlier `get` and written after a
  `world_matrix` call is not seen: get the reference again after the read (the engine does not do it anywhere; the tests
  of `test_hierarchy_cache.cpp` check every write path against a walk up the chain, bit for bit).
- **Threads**: jobs may read (the render gather does, `world_matrix` from several threads at once): a valid entry is read
  with an acquire load and no lock, a missing one is filled under a small spin lock and published with a release store.
  Nothing may write while jobs read (the rule of every job), so an entry never changes under a reader.
  `World::hierarchy_version()` counts the invalidations that dropped a valid entry (one per write that found its entry valid,
  not one per entry of the subtree below it; `create` / `destroy` do not move it): tests use it to see that a read did not
  write, and a system can compare it with the value it saw to know that no entry was dropped since.
- **Same results on every run**: the matrices are the same bits however the entries were filled (the order of reads, the
  threads), and `game.state_hash` does not read them. Since M94.1c the product is `parent * local` from the root down
  (before it was grouped from the leaf up), which can differ in the last bit of a float from earlier versions of the
  engine for an entity two or more levels deep.

## Reflection
`fa::TypeRegistry::global()` (core/reflect.h) holds every component type with
documented fields. From it we derive: JSON load/save, `scene.set_component`, script
property access, JSON Schemas, Markdown docs and TypeScript declarations.

### Versions

`tools/common/api_since.json` says which release added each component, field (`Component.field`), command
and script export, and the generated reference prints it. A new component, field, command or script export needs an
`"unreleased"` entry there (not in the registration call); the `"script"` section is keyed by the name of each export of
`engine/script/src/js/api.json` (`tween`, `NavAPI`; the object `nav` is of type `NavAPI`, so the version of
`nav.findTilePath` is the one of `NavAPI.findTilePath`), `Type.member` for each member or static of a class or interface
(`NavAPI.findTilePath`), and the same with a `test:` prefix for the `factoria:test` module (`test:TestGame.setDate`);
the generated `types/factoria.d.ts` gets an `@since` tag from it. The test `api_since` in `tools/common/tests` lists
the exact lines to add. A release renames `## Unreleased` in CHANGELOG.md to the version (CHANGELOG.md keeps `## Unreleased` and the newest minor version with its patches, because
`.github/workflows/release.yml` reads the tag's section from it; when a release is published, the previous minor version's sections move to
`changelog/0.<minor>.md`, one file per minor version with its patches, and the index line at the top of CHANGELOG.md gets the link; the test `changelog_split` fails while CHANGELOG.md holds two minor versions (the
patches of the newest stay); the README's "Version x.y" line and the Spanish README's "al día en la versión x.y" note
change to the new minor too, checked by `readme_version`), and the same test then tells you to replace every
`"unreleased"` with it and regenerate `docs/COMPONENTS.md` and the browsable pages in `docs/reference/` (`factoria call
docs.write_reference '{"out":"docs"}'` from the repository root, checked by the test `api_reference`; the same call also
rewrites the tools table of docs/AI_GUIDE.md section 4, the block between `<!-- generated: tools table ... -->` and
`<!-- end generated -->` (one row per command category: its tool names and a one-line purpose from
`tools/common/src/ai_guide_export.cpp`, checked by the test `ai_guide_tools_table`, which also fails on a category without
a purpose; a guide without the markers gives a `warnings` entry in the result and is left alone); plus
`factoria api --dts --project examples/<name>` for the committed typings).

### Deprecations

An API that gets a better replacement is deprecated for two minor versions and then removed, never changed
silently. The one source of truth is the `"deprecated"` section of `tools/common/api_since.json`, keyed like the sections
above: `"commands"` (`scene.old`), `"components"` (`Sprite` or `Sprite.oldField`) and `"script"` (`oldExport`,
`NavAPI.oldMember`, `test:` prefix as in the since marks). To deprecate something, keep it working, add the entry (the
section ships empty), and write the migration in CHANGELOG.md:

```jsonc
"deprecated": { "commands": { "scene.old_command": {
    "since": "0.30.0",              // the version that deprecates it ("unreleased" until the release renames it)
    "use": "scene.new_command",     // the replacement, a key of the SAME section, exactly; "" when nothing replaces it
    "note": "Takes the same arguments, plus `parent`." } } }   // one sentence; required when `use` is empty (say why)
```

What it does (`fa::Deprecations`, core/deprecation.h; `fa::install_deprecations()` loads the section into it before the
first Engine, in the CLI's `main`, and `register_project_commands` and the generators call it too, so a program that does
not load the tooling, an exported game, has an empty table and pays one atomic load):
- A warning in the log (category `deprecated`, level warning) the first time in the process that the thing is used, and
  never again: a command call (`CommandRegistry::call`, still runs), a scene or prefab with the component or field (the
  loader adds it to the `LoadReport` as a warning with the JSON pointer, and still applies the value) and a call of the
  script function, class or member (the `"factoria"` prelude wraps it at start-up; a property defined non-configurable, like
  `tween.pauseAll`, cannot be wrapped and only has the typings and the reference). The text names what is deprecated,
  since which version, what to use instead (or that nothing replaces it, and the `note`) and the version that removes it:
  `Deprecated: command 'scene.old_command' (since 0.30.0) will be removed in 0.32.0. Use 'scene.new_command' instead. <note>`.
  The editor forgets which ones it warned about whenever it opens a project.
- The generated output marks it: `@deprecated 0.30.0: use `x`. Removed in 0.32.0. <note>` in the typings, a bold
  `Deprecated since 0.30.0 - use `x`. Removed in 0.32.0.` line in docs/COMPONENTS.md and docs/reference (under the heading
  of a component or command, in the description of a field), `_Deprecated._` in the reference index, a `deprecated` object
  (`since`, `use`, `note`, `removedIn`, `summary`) in `factoria api --json`, `docs.components`, `docs.commands` and the MCP
  tool's `_meta`, and the summary in the MCP tool description.
- Removal: two minor versions after `since` (deprecated in 0.30.x, removed in 0.32.0). The test `api_since` fails once
  the current version is that far, with "remove the API and this entry"; it also fails for an entry that names something
  that no longer exists (remove the entry), whose `use` does not exist or is deprecated itself, or without a `use` and a
  `note`. The removal and the deleted entry go in the same commit, with a line in CHANGELOG.md.

