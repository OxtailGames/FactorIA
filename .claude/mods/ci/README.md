# /ci: CI status of the pull request in Claude Code

A Claude Code mod for working on FactorIA (or any GitHub repository): `/ci` shows the CI checks of the current
branch's pull request, failures first, with durations and links to the logs of anything that is not green.

```
/ci                      # the PR of the current branch (remote "origin")
/ci 2                    # PR #2 of this repository
/ci OxtailGames/FactorIA#2
/ci prs                  # every open PR: CI counts and whether it can be merged now
/ci off                  # stop watching
```

While checks are still running it re-checks every minute, keeps a summary in the status line
(`CI #2 ⏳1 ✅5`) and shows a toast when they all finish.

It reads the GitHub REST API through `gh api`, so `gh` must be installed and logged in (or, in a Claude Code cloud
session, reach GitHub through the session's proxy).

## Install

From any Claude Code terminal session:

```
/plugin install ci --marketplace OxtailGames/FactorIA
```

Answer `y` to add the marketplace, then pick a scope. To run it from a checkout without installing:
`claude --plugin-dir .claude/mods/ci`.

## Develop

```
claude plugin validate .claude/mods/ci
claude plugin test .claude/mods/ci
```

`hooks/ci.ts` holds the pure logic (arguments, remotes, the report); `hooks/register.ts` the slash command, the
`gh`/`git` calls and the watcher; `tests/ci.test.ts` answers `git` and `gh` with canned data.
