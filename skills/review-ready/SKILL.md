---
name: review-ready
description: Keep REVIEW.md and one-step access to every scene so reviewers can play. Read before finishing a feature.
---

# Build the game so it can be reviewed
The art critics and the game reviewers play the build WITHOUT editing anything, in a few minutes. Keep these in place and up
to date as the game grows:
- REVIEW.md at the project root (never exported): the note they read first. Sections: "How to play" (controls, the goal, what
  a session looks like), "Status" (what is finished and what is a placeholder, so they do not judge placeholders as final),
  "Reach everything fast" (every scene/level/state and how to get there in one step: scene paths for scene_load, a debug
  menu or cheat keys, a tool in tools/*.js, saved states in review/, input replays), "Bot-playable flows" (replays or
  tests that play the first minutes, a whole level, the ending) and "Known issues" (what not to report again).
- Every scene and state a reviewer should see (a boss, the shop, game over, the last level) reachable in one call, not by
  playing for an hour: a project tool, a start scene prop, or a save/state loaded by REVIEW.md.
- Stable screenshots: deterministic seeds and no random camera shake or fades at the moment a screenshot is taken.
- No debug overlay in normal play: cheats and debug entry points live behind a key, an action or a tool named in REVIEW.md.

## What the reviewers do with it

The user can ask for an art critique or a game review: read-only agents play the build and score it. Keep `REVIEW.md`
(project root, never exported) up to date: how to play (controls, goal), what is finished and what is a placeholder,
how to reach EVERY scene, level and state in one step (scene paths for `scene_load`, a debug key or project tool, saved
states in `review/`), replays or tests that play the first minutes, and known issues. Keep screenshots stable (fixed
seed, no random shake at capture) and debug overlays out of normal play (`factoria docs read ai-guide`, 11.4).

A skeleton for REVIEW.md is in `review-md-template.md` (`skills_read {"name":"review-ready","file":"review-md-template.md"}`).
