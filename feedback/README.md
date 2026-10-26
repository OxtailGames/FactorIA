# Engine feedback loop

FactorIA is built for AI game-makers, so the games AIs make are the best test of the engine. This folder
closes the loop between those games and the engine team.

## The loop

1. **Games write feedback.** While building, an AI records every engine gap, bug, bad error message or wrong
   doc in the game's `ENGINE_FEEDBACK.json` (MCP tool `feedback_report`, `factoria feedback add`, or by hand;
   the format is in `docs/ENGINE_FEEDBACK.md` and `schemas/engine-feedback.schema.json`). Each entry says what
   was missing, the workaround used, and a suggested fix. Similar open entries merge and raise `occurrences`.
2. **Collect.** `factoria feedback collect examples/sky-hopper examples/neon-swarm examples/gem-roller examples/block-push examples/lantern-keep examples/clockwork-courier examples/burrow-brigade examples/tidewater-market --out feedback/ROADMAP.md` groups
   similar entries across games and ranks them by `sum(occurrences) x severity weight`
   (blocker 8, major 4, minor 2, nice-to-have 1). Only `open` entries count.
3. **Triage.** For each entry, check it against the current engine (a scratch project, `factoria call`, or a
   test) and set the status: `open`, `fixed-in-engine`, `duplicate` or `wont-fix`. A fixed entry gets
   `engineIssue` (commit/PR) and a note `Fixed in <commit>: <how to use the fix>`. Doc-only gaps are only
   `fixed-in-engine` once the docs really cover them.
4. **Fix.** The remaining gaps are grouped into work packages in `ROADMAP.md` ("Next engine milestones"), each
   with acceptance criteria an AI agent can implement and test.
5. **Close.** When a milestone ships, re-run triage. Games read their own notes, drop the workaround and may
   delete the entry.

## Submitting your own feedback

Built a game with FactorIA? Share your `ENGINE_FEEDBACK.json`:

- open a GitHub issue and attach the file (or paste it), or
- open a PR that adds it as `feedback/inbox/<game>.json`.

Run `factoria feedback validate <project>` first. Entries need `missing` and `workaround`; honest
workarounds are the most useful part. Do not include secrets or private paths.

## How the orchestrator uses ROADMAP.md

`ROADMAP.md` is generated, never hand-edited above the "Next engine milestones" section. The orchestrator:

1. regenerates the ranked list with `factoria feedback collect` (see the command above);
2. picks the top work package, or the one with most blockers/majors per unit of size;
3. hands the package to an engine agent with its entry ids and acceptance criteria;
4. after the change merges, runs triage again and marks the entries `fixed-in-engine`;
5. when a milestone is done, moves what it built to `ROADMAP_DONE.md` and leaves in `ROADMAP.md` only a link, what it
   left open and the decisions later work has to respect ("Decisions of finished milestones"), so every agent that
   reads the roadmap reads open work.

Layout: `ROADMAP.md` (ranked open entries + milestones), `ROADMAP_DONE.md` (what finished milestones built), `inbox/`
(submitted files, not yet triaged), and the in-repo examples under `examples/*/ENGINE_FEEDBACK.json`.
