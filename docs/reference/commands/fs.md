[Back to the index](../README.md)

# Commands: fs

## `fs.delete` (modifies state)

Delete a file or folder from the project.

Folders need recursive=true. factoria.json and ENGINE_FEEDBACK.json cannot be deleted. Not undoable unless the project is under version control. Inside .factoria/ (screenshots, saves, AI transcripts) only the scratch folder .factoria/tmp/ can be deleted, the same folder fs.write and scene.save may write to. Example: {"path":"scripts/old.js"} or {"path":".factoria/tmp","recursive":true}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | Project-relative path. |
| `recursive` | boolean | no | Delete a folder and everything in it. Default false. |

## `fs.edit` (modifies state)

Replace exact text in a file (must match exactly once unless replaceAll).

Example: {"path":"scripts/player.js","find":"speed = 300","replace":"speed = 360"}. Fails if 'find' is not found or matches several places; include more surrounding text to make it unique. Same write rule as fs.write (inside .factoria/ only .factoria/tmp/ may be edited).

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | Project-relative file path. |
| `find` | string | yes | Exact text to find (whitespace-sensitive). |
| `replace` | string | yes | Replacement text (may be empty to delete). |
| `replaceAll` | boolean | no | Replace every occurrence. Default false. |

## `fs.list`

List files and folders in the project.

Project-relative. Hides the tools' folders (.factoria, version control) except the scratch folder .factoria/tmp. Example: {"path":"scenes","recursive":true}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | no | Folder to list (default: project root). |
| `recursive` | boolean | no | Descend into subfolders. Default false. |
| `glob` | string | no | Only paths matching this glob, e.g. "**/*.js". |
| `limit` | integer | no | Maximum entries returned. Default 500. |

## `fs.read`

Read a text file (optionally a line range).

Example: {"path":"scripts/player.js","startLine":1,"endLine":80}. Binary files are refused. Set numbered=true to get line numbers for fs.edit planning.

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | Project-relative file path. |
| `startLine` | integer | no | First line (1-based). Default 1. |
| `endLine` | integer | no | Last line, inclusive (default: end of file). Default 0. |
| `numbered` | boolean | no | Prefix every line with its number and a tab. Default false. |

## `fs.search`

Search text in project files (substring or regex).

Skips binary files and .factoria/.git. Example: {"query":"RigidBody2D","glob":"**/*.json"} or {"query":"onUpdate\\(","regex":true}.

| Argument | Type | Required | Description |
|---|---|---|---|
| `query` | string | yes | Text or regular expression (ECMAScript). |
| `regex` | boolean | no | Treat query as a regular expression. Default false. |
| `caseSensitive` | boolean | no | Case-sensitive match. Default false. |
| `path` | string | no | Folder to search (default: project root). |
| `glob` | string | no | Only files matching this glob, e.g. "**/*.js". |
| `limit` | integer | no | Maximum matches returned. Default 100. |

## `fs.write` (modifies state)

Create or overwrite a file (text, or binary via base64; parent folders are created).

Example: {"path":"scripts/enemy.js","content":"export default class ..."}. For binary files such as PNG sprites pass encoding="base64" and the base64 of the bytes as content (e.g. {"path":"sprites/hero.png","encoding":"base64","content":"iVBORw0KGgo..."}). For small changes to an existing file prefer fs.edit. .json files are checked for syntax and a warning is returned if invalid; run project.validate afterwards. Writing into .factoria/ is refused except .factoria/tmp/, the scratch folder for throw-away files (the same rule as scene.save).

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | Project-relative file path. |
| `content` | string | yes | Full new file content (base64 text when encoding=base64). |
| `encoding` | string ["utf8","base64"] | no | "utf8" writes content as text; "base64" decodes it and writes the bytes (images, audio). Default "utf8". |
| `overwrite` | boolean | no | Allow replacing an existing file. Default true. |

