# What's new in FactorIA

The editor shows these notes when it offers an update, and each release on GitHub uses its section. Newest first.

Older versions, one file per minor version with its patch releases: [0.23](changelog/0.23.md), [0.22](changelog/0.22.md), [0.21](changelog/0.21.md), [0.20](changelog/0.20.md), [0.19](changelog/0.19.md), [0.18](changelog/0.18.md), [0.17](changelog/0.17.md), [0.16](changelog/0.16.md), [0.15](changelog/0.15.md), [0.14](changelog/0.14.md), [0.13](changelog/0.13.md), [0.12](changelog/0.12.md), [0.11](changelog/0.11.md), [0.10](changelog/0.10.md), [0.9](changelog/0.9.md), [0.8](changelog/0.8.md), [0.7](changelog/0.7.md), [0.6](changelog/0.6.md), [0.5](changelog/0.5.md), [0.4](changelog/0.4.md), [0.3](changelog/0.3.md), [0.2](changelog/0.2.md), [0.1](changelog/0.1.md).

## Unreleased

- The feedback server limits every write route per installation, per network and for the whole server (verdicts and
  sign-ins gained network and global caps), and refuses write requests without `CF-Connecting-IP` (`missing_client_ip`)
  unless `ALLOW_NO_CLIENT_IP` is set for local development.
- Command capabilities (M92): `fa::Capability` / `CapabilitySet` (core/capability.h), `CommandInfo::capabilities` (derived from `readOnly` until a command declares it), named caller sets, `CommandCapabilityScope` / `command_context()`, and the `capability_denied` error from `CommandRegistry::call`; `describe()` lists `capabilities`.
- `fa::fs::resolve_for_write(path, root, allowAnywhere)` (M92.2a): the one function that confines a path a caller gives to a command that writes to the project, the save folder or the export folder (`fs::export_dir()`, default `build/exports`); `resolve_project_path` is now a wrapper over it, and `a/../b` inside the project is accepted.

## 0.24.0

FactorIA 0.24.0 (M97.1 and M97.2) makes the docs cheap for an AI to read. The AI guide opens with an index under 5 KB
and its tools table is generated from the command registry; `docs.list` gives every doc a summary and its audience;
the generated AGENTS.md and the MCP prompts read the index and only the sections a task needs. `docs.components` and
`docs.commands` come in pages with a cursor, and `factoria mcp --tools core` lets MCP clients without tool search
start from the core commands and load the rest by group.

- `docs.components` and `docs.commands` with `full:true` (and the name list of `docs.commands`, over 40 KB) come in pages: whole entries up to `maxBytes` (default 40000, max 90000, like `docs.read`), `total`, and `nextCursor` (the next entry's name) until the last page; pass it as `cursor` to continue, with the same `filter` and `format`. A cursor that is not an entry of the set fails with how to restart. `full` with `filter` now returns the matching entries in full.
- docs/AI_GUIDE.md starts with a short `## Index` (every section in under 5 KB; read it alone with `docs_read {"name":"ai-guide","heading":"Index"}`), and the tools table of its section 4 is generated from the command registry by `docs.write_reference`: one row per command category, so it no longer goes stale and is a third of its former size.
- `factoria mcp --tools core` (or a comma list such as `core,anim,physics`) lists only the core commands and the
  chosen groups, plus `tool_load`, `tool_describe` and `tool_call` to reach the rest, for MCP clients without tool
  search that would load ~400 definitions. The default `all` changes nothing. The core list and the group rules moved
  to `fa/tooling/tool_groups.h`, shared with the built-in agent's catalog.
- `docs.list` (and `factoria docs list`) gives every doc a one-sentence `summary` and an `audience` (`gameAi`, `user`,
  `engineDev`), with an `audience` filter, so an AI reads only the docs its task needs. The generated AGENTS.md, the
  MCP server instructions and the `make-game` / `add-feature` prompts now say: the AI guide's `Index` first, then
  sections by heading, components one at a time, never the whole `components` page. `factoria docs list --audience <a>`
  filters the same way.
- Polish of the docs paging and the MCP tool profiles: a page of `docs.components` / `docs.commands` counts `maxBytes` on the
  serialized result (JSON escapes included) and a `cursor` cannot be combined with `name`; `docs.write_reference` reports a
  `warnings` entry when `AI_GUIDE.md` has no generated-table markers or is missing, instead of skipping the table silently;
  with `--read-only`, `factoria mcp --tools` names the groups it hides, `tool_call` annotates read-only calls and a
  non-object `arguments` is an `isError` result.
- A rig or model file written again with the same size within the clock step of the previous write (1/64 s under the Windows
  rules) is read again by the skeleton cache, which used to keep serving the old skeleton.
