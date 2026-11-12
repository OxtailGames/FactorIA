[Back to the index](../README.md)

# Commands: docs

## `docs.commands`

Reference of the available commands (tools) with arguments: a list of names, or one command in full.

Lists the commands of this session, including project tools from tools/*.js. With no argument it lists every command with its summary. {"name":"game.click"} returns that command with its arguments, {"filter":"ui"} the commands whose name, category or summary contains the text, {"full":true} every command in full (over 200 KB) in pages of at most maxBytes (default 40000): pass the result's nextCursor as cursor for the next page, until it is absent (cursor is not used with name; a plugin or tools/*.js loaded between two pages can make a page skip or repeat commands).

| Argument | Type | Required | Description |
|---|---|---|---|
| `name` | string | no | Exact command name (case-insensitive): returns its full reference. |
| `filter` | string | no | Keep the commands whose name, category or summary contains this text (case-insensitive). |
| `full` | boolean | no | Return the commands in full, one page at a time (see maxBytes, cursor); with filter, only the matches. Default false. |
| `cursor` | string | no | The nextCursor of the previous page: continues the list or the full reference from there. Use it with the same filter, full and format, and without name. It is the name of the next entry: if plugins or tools/*.js were loaded between two calls, entries can be skipped or repeated (a cursor that no longer exists is refused). |
| `maxBytes` | integer | no | Page size in bytes of the whole result (entries, header, next and nextCursor, JSON escaping): whole entries are added until the next would not fit (a page has at least one entry, so one huge entry can pass it). Default 40000. |
| `format` | string ["markdown","json"] | no | Output format. Default "markdown". |

## `docs.components`

Reference of components and fields (types, defaults, docs): a list of names, or one component in full.

Generated from the engine's reflection data; always accurate for this build. Use before writing scene JSON. With no argument it lists every component with a one-line summary. {"name":"Sprite"} returns that component with all its fields, {"filter":"physics"} the components whose name, category or summary contains the text, {"full":true} every component in full (over 200 KB) in pages of at most maxBytes (default 40000): pass the result's nextCursor as cursor for the next page, until it is absent (cursor is not used with name; entries loaded between two pages can shift the pages).

| Argument | Type | Required | Description |
|---|---|---|---|
| `name` | string | no | Exact component name (case-insensitive): returns its full reference. |
| `filter` | string | no | Keep the components whose name, category or summary contains this text (case-insensitive). |
| `full` | boolean | no | Return the components in full, one page at a time (see maxBytes, cursor); with filter, only the matches. Default false. |
| `cursor` | string | no | The nextCursor of the previous page: continues the list or the full reference from there. Use it with the same filter, full and format, and without name. It is the name of the next entry: if plugins or tools/*.js were loaded between two calls, entries can be skipped or repeated (a cursor that no longer exists is refused). |
| `maxBytes` | integer | no | Page size in bytes of the whole result (entries, header, next and nextCursor, JSON escaping): whole entries are added until the next would not fit (a page has at least one entry, so one huge entry can pass it). Default 40000. |
| `format` | string ["markdown","json"] | no | Output format. Default "markdown". |

## `docs.list`

List the engine documentation available offline.

Start here. Returns {docs:[{name, title, summary, audience[], path, bytes}]}: `summary` is one sentence on what the page is for, `audience` says who it is for (gameAi: the AI making a game, user: the person using the engine, engineDev: working on the engine itself), `bytes` its size. Pick by summary and read only what the task needs with docs.read (by `heading`). The document 'ai-guide' explains how to build games with FactorIA. Example: {"audience":"gameAi"}.

| Argument | Type | Required | Description |
|---|---|---|---|
| `audience` | string ["gameAi","user","engineDev"] | no | Only the docs for this audience (a doc can have several). Default: all docs. |

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

Writes <out>/COMPONENTS.md (the whole `factoria api --md` text, including the scripting API) and <out>/reference/: README.md (index of every component and command), components/<category>.md and commands/<category>.md, and it refreshes the generated tools table between the markers in section 4 of <out>/AI_GUIDE.md (an <out> without that file, or a file without the markers, gives a `warnings` entry and nothing else changes); all generated from the registries of this session. Run it outside a project (the scratch session) so plugin and project commands are not included; the unit test api_reference compares the committed files with this output. The files are identical on every platform. Example: {"out":"docs"} from the repository root.

| Argument | Type | Required | Description |
|---|---|---|---|
| `out` | string | yes | Docs folder to write into (relative to the working directory), usually "docs". |

