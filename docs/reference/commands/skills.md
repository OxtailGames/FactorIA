[Back to the index](../README.md)

# Commands: skills

## `skills.list`

Not released yet (on main after 0.10.0).

List the skills (topic guides) available to a role: name, description, where each lives.

Skills are folders with a SKILL.md (Agent Skills format) that you read only when a task needs them: the engine's own (make-art, make-audio, custom-shaders...), the user's (~/.factoria/skills) and the project's (skills/). Returns {skills:[{name, description, source engine|user|project, enabled, roles, dir, entry?, shadowedBy? (another skill of the same name wins), problem + fix? (SKILL.md invalid: not offered)}], count}. With `role`, only the skills that role is offered; without it, every skill with its settings. Read one with skills.read. docs/SKILLS.md. Example: {"role":"worker"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `role` | string | no | Only the skills this role is offered (orchestrator, worker, fast, artist, audio, artCritic, reviewer). Omit for all. |

## `skills.new` (modifies state)

Not released yet (on main after 0.10.0).

Create a skill: skills/<name>/SKILL.md in the project (or in ~/.factoria/skills).

Writes a SKILL.md from the Agent Skills template: frontmatter with `name` (lowercase letters, digits and hyphens, up to 64, the folder's name) and `description` (what the skill is for and WHEN to read it, up to 1024 characters), then a body to fill in. Add other files beside it and name them in the body. Never overwrites an existing skill. scope "project" (default) writes into the project's skills/ folder, which the game's other AIs and `factoria validate` see; "user" writes into ~/.factoria/skills for every project. Returns {path, name, scope}. docs/SKILLS.md. Example: {"name":"enemy-design","description":"How enemies are built in this game. Read before adding an enemy."}

| Argument | Type | Required | Description |
|---|---|---|---|
| `name` | string | yes | Skill name and folder: lowercase letters, digits, single hyphens. |
| `description` | string | no | What the skill covers and when to read it (up to 1024 characters). |
| `scope` | string ["project","user"] | no | Where to create it. Default "project". |

## `skills.read`

Not released yet (on main after 0.10.0).

Read a skill: its SKILL.md instructions, or another file of the skill.

Loads the instructions of the skill `name` (see the Skills list in your prompt, or skills.list) before you start the kind of work it covers. Without `file` it returns the body of SKILL.md and lists the other files beside it; read one with `file` (a path relative to the skill, "reference.md"). Long files come in pieces: `truncated` and `nextOffset` say where the next call continues (`offset`, `limit` are bytes). Returns {name, source, file, description?, content, totalBytes, truncated?, nextOffset?, files?}. Unknown names and files answer with the ones that exist. docs/SKILLS.md. Example: {"name":"make-art"} or {"name":"make-art","file":"reference.md"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `name` | string | yes | Skill name, as in the Skills list. |
| `file` | string | no | File of the skill, relative to its folder. Default SKILL.md. |
| `offset` | integer | no | Byte to start at (continue a truncated read with nextOffset). |
| `limit` | integer | no | Most bytes to return. Default 60000. |
| `role` | string | no | The role asking: only the skills it is offered can be read. FactorIA fills it in for you. |

