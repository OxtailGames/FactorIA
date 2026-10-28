[Back to the index](../README.md)

# Commands: docs

## `docs.commands`

Reference of the available commands (tools) with arguments: a list of names, or one command in full.

Lists the commands of this session, including project tools from tools/*.js. With no argument it lists every command with its summary (the whole reference is over 200 KB, more than an MCP tool result carries). {"name":"game.click"} returns that command with its arguments, {"filter":"ui"} the commands whose name, category or summary contains the text, {"full":true} everything.

| Argument | Type | Required | Description |
|---|---|---|---|
| `name` | string | no | Exact command name (case-insensitive): returns its full reference. |
| `filter` | string | no | Keep the commands whose name, category or summary contains this text (case-insensitive). |
| `full` | boolean | no | Return every command in full (over 200 KB: too large for most MCP clients; prefer name or filter). Default false. |
| `format` | string ["markdown","json"] | no | Output format. Default "markdown". |

## `docs.components`

Reference of components and fields (types, defaults, docs): a list of names, or one component in full.

Generated from the engine's reflection data; always accurate for this build. Use before writing scene JSON. With no argument it lists every component with a one-line summary (the whole reference is over 200 KB, more than an MCP tool result carries). {"name":"Sprite"} returns that component with all its fields, {"filter":"physics"} the components whose name, category or summary contains the text, {"full":true} everything.

| Argument | Type | Required | Description |
|---|---|---|---|
| `name` | string | no | Exact component name (case-insensitive): returns its full reference. |
| `filter` | string | no | Keep the components whose name, category or summary contains this text (case-insensitive). |
| `full` | boolean | no | Return every component in full (over 200 KB: too large for most MCP clients; prefer name or filter). Default false. |
| `format` | string ["markdown","json"] | no | Output format. Default "markdown". |

## `docs.list`

List the engine documentation available offline.

Start here. Returns name, title and size of each document; read one with docs.read. The document 'ai-guide' explains how to build games with FactorIA.

## `docs.read`

Read a documentation page (Markdown), a section or a line range; long pages come in parts.

Example: {"name":"scripting"}. A result is at most `maxBytes` (default 40000, about 10k tokens; an MCP client refuses much more), so a long page is cut and the result then carries `contents` (the headings with their line numbers) and `next`, the exact call that continues. Read one section by heading: {"name":"ai-guide","heading":"Platformer character"} (case-insensitive; an exact title wins, else a part of a title; several matches list them), or a range with startLine/maxLines. Names: see docs.list (e.g. ai-guide, architecture, scripting, components, licenses). To find where something is, docs.search returns sections with their line numbers.

| Argument | Type | Required | Description |
|---|---|---|---|
| `name` | string | yes | Doc name ("scripting") or path ("docs/SCRIPTING.md"). |
| `heading` | string | no | Read only the section with this heading (and its subsections), e.g. "Pause menu". See `contents` of a cut read. |
| `startLine` | integer | no | First line to return (1-based, default 1). With `heading`: the line to continue a long section from. |
| `maxLines` | integer | no | Maximum number of lines. Default 2000. |
| `maxBytes` | integer | no | Maximum size of `content` in bytes; the read stops at a line boundary. Default 40000. |

## `docs.search`

Search the documentation by keywords.

Case-insensitive; every word counts, headings weigh more. Returns best sections with a snippet. Example: {"query":"input actions"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `query` | string | yes | Keywords. |
| `limit` | integer | no | Max results. Default 8. |

## `docs.write_reference` (modifies state)

Since 0.2.0.

Write the browsable API reference pages (docs/reference/) and docs/COMPONENTS.md.

Writes <out>/COMPONENTS.md (the whole `factoria api --md` text, including the scripting API) and <out>/reference/: README.md (index of every component and command), components/<category>.md and commands/<category>.md, all generated from the registries of this session. Run it outside a project (the scratch session) so plugin and project commands are not included; the unit test api_reference compares the committed files with this output. The files are identical on every platform. Example: {"out":"docs"} from the repository root.

| Argument | Type | Required | Description |
|---|---|---|---|
| `out` | string | yes | Docs folder to write into (relative to the working directory), usually "docs". |

