# Skills: topic guides every AI reads when the work needs them

A **skill** is a folder with a `SKILL.md` file and, if you want, other files beside it. The `SKILL.md` starts with two lines of
frontmatter, `name` and `description`, and then holds the instructions. The AI sees only the name and the description until it
decides the task needs that skill; then it reads the rest. So a long guide (exporting, publishing, shaders, 3D physics) costs
nothing on the steps that do not need it.

This is the **Agent Skills** format that Claude Code and Codex use. A skill written for them works here unchanged, and a skill
you write here works there.

```
skills/enemy-design/
  SKILL.md           the name, the description and the instructions
  reference.md       any other file the instructions mention (read on demand)
```

```markdown
---
name: enemy-design
description: How enemies are built in this game (patrol, chase, the health table). Read before adding or changing an enemy.
---

# Enemy design

Every enemy is the prefab `prefabs/enemy.prefab.json` with a `bt` behaviour tree ...
Numbers for each kind are in reference.md.
```

The description is what the AI chooses by: say what the skill is for **and when to read it**. It can be up to 1024 characters.
The name is 1 to 64 characters, lowercase letters, digits and single hyphens, and it is the folder's name.

## Where skills come from

| Source | Where | Who writes it |
|---|---|---|
| `project` | `<project>/skills/<name>/`, and the skill folders that the project's `.factoria/extensions.json` names | the game (commit them: every AI and every teammate gets them) |
| `user` | `~/.factoria/skills/<name>/`, and the skill folders that your `ai.json` `extensions.skills` names | you, for every project |
| `engine` | `skills/<name>/` of the FactorIA repository, baked into the binary | FactorIA |

When two skills have the same name, the project's wins over yours, and yours over the engine's. The one that loses is listed with
`shadowedBy` and is not offered, so a game can replace an engine guide with its own by creating `skills/<same-name>/`.

The engine's own skills (topic guides that used to be part of the prompt and the project's `AGENTS.md`):

| Skill | For | Offered to |
|---|---|---|
| `make-art` | the craft of the game's art and its look | orchestrator, artist |
| `make-audio` | sound effects, music, voice, mixing | orchestrator, audio |
| `review-ready` | keeping `REVIEW.md` and one-step access to every scene so reviewers can play | orchestrator, worker, artist, audio |
| `custom-shaders` | writing and compiling a material shader | orchestrator, worker, artist |
| `glow-and-effects` | bloom, additive glow, one-shot particle bursts | orchestrator, worker, artist |
| `inspect-the-picture` | zoomed regions, filmstrips, `render_inspect`, `render_pick` | orchestrator, worker, artist |
| `tile-levels` | ASCII tile maps with `scene.import_ascii`, camera bounds | orchestrator, worker |
| `physics-3d` | rolling, colliders, sleeping, platforms in 3D | orchestrator, worker |
| `web-requests` | `http.fetch` and the allowed hosts | orchestrator, worker |
| `menus-and-finishing` | the menu kit, options, pause, saves, the finishing path | orchestrator, worker |
| `publishing-and-exporting` | the per-store publishing checklist | orchestrator, worker |

A skill found in a skills folder or in a project file is offered to the orchestrator, worker, fast, artist and audio roles; the two
review roles (`artCritic`, `reviewer`) get a skill only when it lists them, because they only look and play. The orchestrator
whose artist (audio) role is switched on does not get `make-art` (`make-audio`): it hands that work over.

## How each provider gets them

| Provider | How |
|---|---|
| Built-in agent (`anthropic`, `openai-compatible`) | The system prompt has a `# Skills` section with one `name: description` line per skill the role is offered. The model reads one with the tool `skills_read {"name"}`. |
| `claude-code` | A plugin FactorIA writes for the run (`factoria-extensions`) holds a copy of the skills; Claude Code lists and loads them itself, so the prompt does not repeat the lines. `skills_read` also works. |
| `codex` | Codex reads Agent Skills from `.agents/skills` of the folder it starts in. FactorIA copies the skills of the run to `<project>/.agents/skills/factoria-r<tag>-<name>/` before it starts Codex and deletes them when the run ends; it writes a `.agents/skills/.gitignore` (`factoria-*/`) when there is none, so a run that dies leaves nothing to commit. Your own folders in `.agents/skills` are not touched. The prompt keeps the `# Skills` lines and `skills_read` works too, so an older Codex that does not scan that folder still knows the skills. |
| `generic-cli` | The prompt lines and `skills_read` through FactorIA's MCP server (a generic CLI has no skill folder to give). |

Codex: [Agent Skills](https://developers.openai.com/codex/skills) lists `$CWD/.agents/skills`, the folders up to the repository
root, `$HOME/.agents/skills` and `/etc/codex/skills`. FactorIA uses the first one because it is the only one that exists for just
this run and this project.

## Commands

| Command | What it does |
|---|---|
| `skills.list {role?}` | Every skill with `name`, `description`, `source`, `enabled`, `roles`, `dir`, and `shadowedBy` or `problem` + `fix` when it cannot be used. With `role`, only the skills that role is offered. CLI: `factoria call skills.list`. |
| `skills.read {name, file?, offset?, limit?}` | The instructions of a skill (the body of `SKILL.md`), plus the list of its other files; `file` reads one of them. Long files come in pieces (`truncated`, `nextOffset`). An unknown name or file answers with "did you mean" and the ones that exist. |
| `skills.new {name, description?, scope?}` | Writes `skills/<name>/SKILL.md` from the template into the project (`scope: "user"`: into `~/.factoria/skills`). Never overwrites a skill. |

Over MCP they are `skills_list`, `skills_read` and `skills_new`.

## Turning skills on and off per role

A skill folder with no entry is on for its default roles. To change that, add an entry under `extensions.skills` in `ai.json`
(or in the project's `.factoria/extensions.json`; see [AI_PROVIDERS.md](AI_PROVIDERS.md#extensions)):

```json
{
  "extensions": {
    "skills": {
      "make-art":  { "path": "engine:make-art", "roles": ["artist"] },
      "old-notes": { "path": "~/skills/old-notes", "enabled": false }
    }
  }
}
```

`"path": "engine:<name>"` names one of the engine's skills (an unknown name is refused with "did you mean"). `roles` replaces
the default list; `enabled: false` keeps the entry without offering the skill to anyone.

The editor does this for you: **AI > AI Settings... > Extensions > Skills** is a table with one row per skill (On, name, where it
comes from, what it is for) and one checkbox per role. A change is kept as a skill entry; **Save** writes it. See
[EDITOR.md](EDITOR.md).

## Checking a skill

`factoria validate` checks every folder of `skills/` and every skill folder the project's extensions file names. Errors give the
file and the line, what is wrong and how to fix it: no `SKILL.md` (and a `skill.md` that needs renaming), no frontmatter, a
missing `name` or `description`, a `name` that is not valid or does not match the folder ("did you mean"), a description over
1024 characters. A skill with no instructions after the frontmatter, or a frontmatter key that looks like a misspelling of one
agents know (`descripton`), is a warning. A skill that does not parse is not offered to any AI until it is fixed.

## Writing a good one

- One skill per topic, so the description can say when to read it. Several short skills beat one long one.
- Put the rules and the exact commands in `SKILL.md`; put long tables, examples and numbers in other files and name them in the
  body (`reference.md`). The AI reads those files only when it needs them.
- Check names and arguments of commands against `factoria commands` rather than from memory, as any other guide.
