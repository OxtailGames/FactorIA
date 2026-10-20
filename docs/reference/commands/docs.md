[Back to the index](../README.md)

# Commands: docs

## `docs.commands`

Reference of every available command (tool) with arguments.

Lists the commands of this session, including project tools from tools/*.js.

| Argument | Type | Required | Description |
|---|---|---|---|
| `format` | string ["markdown","json"] | no | Output format. Default "markdown". |

## `docs.components`

Reference of every component and field (types, defaults, docs).

Generated from the engine's reflection data; always accurate for this build. Use before writing scene JSON.

| Argument | Type | Required | Description |
|---|---|---|---|
| `format` | string ["markdown","json"] | no | Output format. Default "markdown". |

## `docs.list`

List the engine documentation available offline.

Start here. Returns name, title and size of each document; read one with docs.read. The document 'ai-guide' explains how to build games with FactorIA.

## `docs.read`

Read a documentation page (Markdown).

Example: {"name":"scripting"}. Long pages can be read in slices with startLine/maxLines. Names: see docs.list (e.g. ai-guide, architecture, scripting, components, licenses).

| Argument | Type | Required | Description |
|---|---|---|---|
| `name` | string | yes | Doc name ("scripting") or path ("docs/SCRIPTING.md"). |
| `startLine` | integer | no | First line to return (1-based). Default 1. |
| `maxLines` | integer | no | Maximum number of lines. Default 2000. |

## `docs.search`

Search the documentation by keywords.

Case-insensitive; every word counts, headings weigh more. Returns best sections with a snippet. Example: {"query":"input actions"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `query` | string | yes | Keywords. |
| `limit` | integer | no | Max results. Default 8. |

## `docs.write_reference` (modifies state)

Not released yet (on main after 0.1.6).

Write the browsable API reference pages (docs/reference/) and docs/COMPONENTS.md.

Writes <out>/COMPONENTS.md (the whole `factoria api --md` text, including the scripting API) and <out>/reference/: README.md (index of every component and command), components/<category>.md and commands/<category>.md, all generated from the registries of this session. Run it outside a project (the scratch session) so plugin and project commands are not included; the unit test api_reference compares the committed files with this output. The files are identical on every platform. Example: {"out":"docs"} from the repository root.

| Argument | Type | Required | Description |
|---|---|---|---|
| `out` | string | yes | Docs folder to write into (relative to the working directory), usually "docs". |

