# Engine feedback report

Status: the four jam-sized example games reported 73 entries, all verified fixed-in-engine. Lantern Keep, the M21
reference game, reported 45 (none a blocker or major), triaged 2026-10-19: one was already fixed, two were duplicates,
and the 42 open ones became work packages, most of them M24, the rest in M20-M23. M24 fixed 37 of its entries
(M24.1-M24.16, 2026-10-20), two of them found on the way, M21 three, M22 two, M20 one and M23 the last one (MSIX,
2026-10-22): no entry is open. M1-M11 and M13-M15 are done; M12 (platform services) has its API, the Steam, Apple and
Google Play backends, AdMob ads with consent, leaderboard periods on the stores and the Steam Deck's keyboard (M27); M16
(mobile store-ready), M17 (web export), M18 (animation and production 3D), M20 (editor and tooling, 2026-10-22), M21
(docs and material for shipping), M22 (production quality and legal, 2026-10-21), M24, M25, M26, M27, M28, M29, M30 and
M31 (and M32, M33 below) are done; M23 has the Mac App Store and the Microsoft Store (MSIX) done, its consoles part is not started; M19 has the video
player, the navmesh's off-mesh links and walkable bodies (M27), tile pathfinding, behaviour trees, bus effects,
`http.fetch` and split screen (M29), the rest is not started (M10-M23 come from an external evaluation of v0.1.4,
re-triaged 2026-10-16: what it still takes to ship a game to the stores). M25, the second reference game (Clockwork
Courier: 3D, mobile first, 2026-10-22), reported 55 entries (FB-0053-FB-0055 came from the CI fix of its rope bridges),
triaged 2026-10-22: one was fixed on the way (CC/FB-0033), two were already fixed before the report (CC/FB-0007,
CC/FB-0022; their docs are added), two are duplicates, and 50 were open (11 major, 35 minor, 4 nice-to-have, no
blocker). M26's 23 packages fixed 49 of them (2026-10-24) and the game dropped their workarounds; M27 (2026-10-25) fixed
the last one, CC/FB-0051 (playing a video), the parts of three left to M12 (the real ads, the stores' leaderboard
periods, the Steam Deck's keyboard) and CC/FB-0056 (the navmesh over bridges and moving platforms), found by M26's
close-out: no entry is open. What is left of M12 and M19 is ranked in their sections and waits for a game that asks for
it. M28, the third reference game (Burrow Brigade: 2D, couch co-op, desktop and Steam first, 2026-10-25), reported 38
entries (14 major, 22 minor, 2 nice-to-have, no blocker), triaged 2026-10-25: one is a duplicate, two need docs only,
and the open ones became the 21 packages of M29 (built 2026-10-26), which also took most of what was left of M19 (tile
pathfinding and behaviour trees, audio effects, networking, split screen) and M12's analytics and remote config. M29
fixed them all (2026-10-26): no entry is open. The game dropped the workarounds that no longer had a reason; the few it
keeps on purpose are under M29, "Left open".
M30, the fourth reference game (Tidewater Market: a management game played with the mouse, web and desktop first,
2026-10-26), reported 52 entries: one was fixed on the way (TM/FB-0070, the web page downloaded the wasm twice), one
was withdrawn (TM/FB-0015), one is a duplicate, and 49 are open (9 major, 27 minor, 13 nice-to-have, no blocker),
triaged 2026-10-26: five need docs only or are already supported, and the open ones became the 26 packages of M31 (planned
2026-10-26, built 2026-10-27), which closed 46 of the 49 (each `fixed-in-engine` with a `Fixed in` note), and three stay
open (TM/FB-0003, the optional undo helper; TM/FB-0051, the Windows and Linux players of a development build; TM/FB-0055,
a Timeline component for trailers), ranked below; the game dropped the workarounds that no longer had a reason (M31,
"Left open", lists what it keeps and what each package left).
M32, the fifth reference game (Larkspur Lodge: a 3D narrative adventure for the Mac App Store, the Microsoft Store, the
iPad and the Steam Deck, 2026-10-27), reported 36 entries (2 major, 25 minor, 9 nice-to-have, no blocker), triaged
2026-10-27: one is already documented (LL/FB-0010), one is a duplicate of TM/FB-0051 (LL/FB-0804), two are half
supported already, and the 34 open ones became the 15 packages of M33 (planned 2026-10-27, built 2026-10-28), which fixed
all of them (each entry is `fixed-in-engine` with a `Fixed in <commit>` note; LL/FB-0010 was documented already and
LL/FB-0804 is a duplicate of TM/FB-0051), so no Larkspur Lodge entry is open. Three of M32's acceptance criteria are only
partly met (M32, "Left open"); M33 closed what it could of them (M33, "Left open" lists what is still unseen).
Roguestory (the user's own game, not a reference example: a 2D roguelike inside a hand-drawn book, 2026-10-28) reported
6 entries (1 major, 5 minor), and its first session showed three gaps of its own: the console had no wall-clock time, and a
delegated agent was silent for minutes, then cut off by Claude Code's 5-minute tool timeout. M34 (built 2026-10-28) fixed
all of them; Roguestory's entries are `fixed-in-engine` with a `Fixed in` note.
What only certificates, real devices or a device farm can close is under M8 and M9, "Left open". What finished
milestones built is in [ROADMAP_DONE.md](ROADMAP_DONE.md); this file keeps what they left open and the decisions to
respect.
Triage 2026-11-10: the 33 entries the examples logged since 2026-10-29 (Kindlewatch, Ember Descent, Gem Roller,
Neon Swarm, Sky Hopper, Lantern Keep) were never in this list, because the command below named the examples by hand;
KW/FB-0002 and SH/FB-0026 were fixed already and are closed, the other 31 go to M101 ("M100-M101", at the end).
Regenerate the ranked list with `factoria feedback collect examples/* --out feedback/ROADMAP.md` (it rewrites the whole
file: then put this status and the milestones section back).

33 entries from 11 project(s), 33 distinct gap(s) (efficiency entries are ranked apart, below). Ranked by the sum over projects of severity weight x trust x min(occurrences, 3) (blocker 8, major 4, minor 2, nice-to-have 1; trust 1, or 0.5 for an anonymous installation).

## 1. A game script that calls a project tool (fa.call("project.scatter_gems")) works in the editor and factoria run but fails in the exported player

- **Category:** scripting
- **Severity:** major (score 4)
- **Installations:** 1 (0 verified)
- **Total occurrences:** 1
- **Projects affected:** Gem Roller
- **Entries:** Gem Roller/FB-0016
- **Suggestion:** Have the export (and validate) warn when a game script calls fa.call with a literal command name that only a project tool registers, naming the file and line, and say in docs which commands a shipped game has. The example should bake the scattered gems into the scene, or move the scatter code into a game module that both the tool and the script import.
- **Workarounds seen:**
  - None yet in the example: run it from the project folder (factoria run), where the tool is loaded.

## 2. A pending MusicPlayer crossfade or section change survives a scene load

- **Category:** audio
- **Severity:** major (score 4)
- **Installations:** 1 (0 verified)
- **Total occurrences:** 1
- **Projects affected:** Kindlewatch
- **Entries:** Kindlewatch/FB-0004
- **Suggestion:** Drop pending crossfades and section changes when the entity that owns the MusicPlayer is destroyed (scene unload), and report in audio.music_state what is audible versus what is queued.
- **Workarounds seen:**
  - The music director starts the new scene with a hard play({song, section}) instead of goToSection, and the tests assert no script error after scene.reload.

## 3. MusicPlayer holds hundreds of MB of decoded audio, and the perf and memory numbers do not show it

- **Category:** performance
- **Severity:** major (score 4)
- **Installations:** 1 (0 verified)
- **Total occurrences:** 1
- **Projects affected:** Kindlewatch
- **Entries:** Kindlewatch/FB-0001
- **Suggestion:** Stream the ogg of a song instead of decoding it whole (or keep one decoded copy per song, not per layer and per section), count the player's buffers in audioDecodedMB and in perf.measure, and say in the MusicPlayer docs how much memory a song costs (about N MB per minute per layer).
- **Workarounds seen:**
  - None: the song lengths stayed as designed and perf.kindlewatch budgets carry a 600+ MB memory baseline. I did not shorten the songs.

## 4. No way to get players for a development build

- **Category:** platform
- **Severity:** major (score 4)
- **Installations:** 1 (0 verified)
- **Total occurrences:** 1
- **Projects affected:** Tidewater Market
- **Entries:** Tidewater Market/FB-0051
- **Suggestion:** Let setup players fetch the latest release or CI artifact for a development build, and document the emcc setup next to the web export.
- **Workarounds seen:**
  - Exported macOS (the engine's own player) and an old web player; Windows and Linux exports were refused. Later the orchestrator built the web player with the emsdk in ~/emsdk (Emscripten 6.0.10, the CI version); Windows and Linux are still refused.

## 5. A glow brighter than white cannot be written on a mesh (no HDR value or intensity)

- **Category:** rendering-3d
- **Severity:** minor (score 2)
- **Installations:** 1 (0 verified)
- **Total occurrences:** 1
- **Projects affected:** Clockwork Courier
- **Entries:** Clockwork Courier/FB-0057
- **Suggestion:** A glow intensity (or an HDR glow colour) on MeshRenderer, useful with bloom, so a glow can pass 1 without the 0..255 reading.
- **Workarounds seen:**
  - M100.4 clamped the 184 colours to channels of at most 1 (for example [1, 1, 0.4, 1]), so they glow at full colour but no brighter.

## 6. A scene that was generated keeps a copy of the prefab it was made from

- **Category:** scene
- **Severity:** minor (score 2)
- **Installations:** 1 (0 verified)
- **Total occurrences:** 1
- **Projects affected:** Sky Hopper
- **Entries:** Sky Hopper/FB-0024
- **Suggestion:** Have the generator (or scene.import_ascii) write `prefab` references only, and let validate warn about a committed scene whose entity repeats the components of its prefab.
- **Workarounds seen:**
  - Regenerated the scene with the README arguments (width 90, seed 7, difficulty 3).

## 7. A sound patch with variants renders one variant at full scale and lowering the layer gains did not help

- **Category:** audio
- **Severity:** minor (score 2)
- **Installations:** 1 (0 verified)
- **Total occurrences:** 1
- **Projects affected:** Kindlewatch
- **Entries:** Kindlewatch/FB-0011
- **Suggestion:** Make a patch's peak target a field of the patch (peakDb) that applies to every variant, and make assets.regenerate list which input it saw changed when it says unchanged.
- **Workarounds seen:**
  - import.normalize: true on the footstep files in assets.json.

## 8. IK2D targets need a script to stand on uneven ground

- **Category:** animation
- **Severity:** minor (score 2)
- **Installations:** 1 (0 verified)
- **Total occurrences:** 1
- **Projects affected:** Sky Hopper
- **Entries:** Sky Hopper/FB-0025
- **Suggestion:** An optional IK2D.ground mask (project the target onto the first collider below it, within a reach) would make planted feet a data setting.
- **Workarounds seen:**
  - scripts/player.js feet() casts a ray under each marker every fixed step and moves the IK target entity.

## 9. MusicPlayer.song reads as the new song while the old one is still audible

- **Category:** audio
- **Severity:** minor (score 2)
- **Installations:** 1 (0 verified)
- **Total occurrences:** 1
- **Projects affected:** Kindlewatch
- **Entries:** Kindlewatch/FB-0005
- **Suggestion:** Expose `song` (audible), `pendingSong` and `pendingSection` on entity.music, and in audio.music_state.
- **Workarounds seen:**
  - The director keeps its own record of the song it asked for last.

## 10. MusicPlayer.startSection is applied to crossfadeTo into another song that lacks that section

- **Category:** audio
- **Severity:** minor (score 2)
- **Installations:** 1 (0 verified)
- **Total occurrences:** 1
- **Projects affected:** Kindlewatch
- **Entries:** Kindlewatch/FB-0003
- **Suggestion:** When crossfadeTo has no `section`, start the target song at its first section (or its loop) instead of the component's startSection.
- **Workarounds seen:**
  - Every crossfade passes `section` explicitly (scripts/music_director.js, cross()).

## 11. No command to resize or crop the canvas of an image document

- **Category:** tooling
- **Severity:** minor (score 2)
- **Installations:** 1 (0 verified)
- **Total occurrences:** 1
- **Projects affected:** Kindlewatch
- **Entries:** Kindlewatch/FB-0007
- **Suggestion:** image.resize {path, width, height, anchor} that moves or crops every layer, keeping palette, ramps, frames and tags.
- **Workarounds seen:**
  - Recreate the document with image.create and repeat the image.pixel / image.draw calls (the call scripts are the recipe).

## 12. Nothing says which samples pass reachability allConnected

- **Category:** docs
- **Severity:** minor (score 2)
- **Installations:** 1 (0 verified)
- **Total occurrences:** 1
- **Projects affected:** ember-descent
- **Entries:** ember-descent/FB-0002
- **Suggestion:** Say it in docs/AI_GUIDE.md section 9.8 next to allConnected (done in the same change as this example) and let the refused-level error name the sample shape as a cause when cut-off areas are the reason for more than half of the attempts.
- **Workarounds seen:**
  - levels/sample.json is an open cave with pillars and 2-3 cell wide passages; all of tests/dungeon.test.js runs 8 run seeds through it.

## 13. Touch controls are hidden on desktop and cannot be previewed or tested by touch

- **Category:** ui
- **Severity:** minor (score 2)
- **Installations:** 1 (0 verified)
- **Total occurrences:** 1
- **Projects affected:** Kindlewatch
- **Entries:** Kindlewatch/FB-0015
- **Suggestion:** A `factoria run --touch` or screenshot option that forces touch UI on, and a game.touch helper in factoria:test that drops a finger on a TouchStick.
- **Workarounds seen:**
  - Checked the layout with a touch as the last input; the tests use the gamepad.

## 14. anim3d clips carry no provenance record, so a project cannot prove they were made by commands

- **Category:** animation
- **Severity:** minor (score 2)
- **Installations:** 1 (0 verified)
- **Total occurrences:** 1
- **Projects affected:** Kindlewatch
- **Entries:** Kindlewatch/FB-0017
- **Suggestion:** Write a provenance record for every clip the anim3d commands write.
- **Workarounds seen:**
  - tests/assets.test.js checks assets/ only; the clips are described in the README.

## 15. assets.check_mix judges raw source recordings of an audio document and a crossfaded loop still warns on loop_seam_slope

- **Category:** tooling
- **Severity:** minor (score 2)
- **Installations:** 1 (0 verified)
- **Total occurrences:** 1
- **Projects affected:** Neon Swarm
- **Entries:** Neon Swarm/FB-0020
- **Suggestion:** Skip sounds that are only the source of an audio document (or mark them in assets.json), and judge loop_seam_slope across the crossfade the loop step made.
- **Workarounds seen:**
  - Kept the 0.25 s crossfade; left the warning. The source stays next to the document so the bake can be repeated.

## 16. audio.play has no world position: one-shot sounds in 3D are flat unless an AudioSource is spawned

- **Category:** audio
- **Severity:** minor (score 2)
- **Installations:** 1 (0 verified)
- **Total occurrences:** 1
- **Projects affected:** Kindlewatch
- **Entries:** Kindlewatch/FB-0006
- **Suggestion:** audio.play({position:[x,y,z], range, rolloff}) that uses the AudioListener, with the same variants/pitch/bus options.
- **Workarounds seen:**
  - scripts/common.js playAt() (distance attenuation and pan computed by hand, with the camera's ground point as the listener).

## 17. entity.music.status.intensity is the applied intensity, entity.music.intensity the requested one, and the docs do not say

- **Category:** docs
- **Severity:** minor (score 2)
- **Installations:** 1 (0 verified)
- **Total occurrences:** 1
- **Projects affected:** Neon Swarm
- **Entries:** Neon Swarm/FB-0021
- **Suggestion:** Name the applied value (for example appliedIntensity) or say in docs/MUSIC.md which one status.intensity is.
- **Workarounds seen:**
  - The tests read entity.music.intensity for what the script asked and status.stemGains for what is audible, and wait one beat before reading status.intensity.

## 18. fa.call in factoria:test tests cannot run assets.provenance

- **Category:** tooling
- **Severity:** minor (score 2)
- **Installations:** 1 (0 verified)
- **Total occurrences:** 1
- **Projects affected:** Kindlewatch
- **Entries:** Kindlewatch/FB-0013
- **Suggestion:** Document which commands fa.call runs in tests, and add the read-only assets.* ones (provenance, list, check_art).
- **Workarounds seen:**
  - tests/assets.test.js reads assets.json and fs.list.

## 19. input.record does not record presses made with game.input by action name

- **Category:** tooling
- **Severity:** minor (score 2)
- **Installations:** 1 (0 verified)
- **Total occurrences:** 1
- **Projects affected:** Kindlewatch
- **Entries:** Kindlewatch/FB-0012
- **Suggestion:** Record an action press as the keys that produce it, or store the action name in the replay and play it back as an action.
- **Workarounds seen:**
  - Record with key names, not action names (replays/first_night.json).

## 20. model.game_ready gives a conifer a capsule collider far wider than its trunk

- **Category:** rendering-3d
- **Severity:** minor (score 2)
- **Installations:** 1 (0 verified)
- **Total occurrences:** 1
- **Projects affected:** Kindlewatch
- **Entries:** Kindlewatch/FB-0016
- **Suggestion:** Offer collider "trunk" (the lowest part's bounds or a part named for it), or a `colliderPart` argument.
- **Workarounds seen:**
  - The pine instances override the capsule radius and height in the scene.

## 21. scene.save of a loaded scene expands a prefab reference into inline entities

- **Category:** tooling
- **Severity:** minor (score 2)
- **Installations:** 1 (0 verified)
- **Total occurrences:** 1
- **Projects affected:** Kindlewatch
- **Entries:** Kindlewatch/FB-0008
- **Suggestion:** scene.save should write an instance whose prefab file is unchanged as the prefab path plus the component differences, or warn which instances it expanded.
- **Workarounds seen:**
  - Restored the reference by hand in the scene file. The game scene is written by a generator script that emits {"prefab": ..., "components": overrides} and is never saved with scene.save.

## 22. A non-looping sheet clip cannot be looped from the component

- **Category:** scripting
- **Severity:** nice-to-have (score 1)
- **Installations:** 1 (0 verified)
- **Total occurrences:** 1
- **Projects affected:** Neon Swarm
- **Entries:** Neon Swarm/FB-0019
- **Suggestion:** A tri-state loop override on SpriteAnimator (inherit / loop / once).
- **Workarounds seen:**
  - Baked the shockwave as two non-looping clips and removed the entity on clipEnded.

## 23. A rigged model costs one draw call per part, and rig.create cannot merge them

- **Category:** animation
- **Severity:** nice-to-have (score 1)
- **Installations:** 1 (0 verified)
- **Total occurrences:** 1
- **Projects affected:** Gem Roller
- **Entries:** Gem Roller/FB-0014
- **Suggestion:** Fit the rig from the parts, then merge the skinned submeshes by material when baking (skin weights are per vertex, so merging does not change the pose).
- **Workarounds seen:**
  - Accepted the cost: the example's perf budget (drawCalls 14 -> 30) was raised for it.

## 24. A section change and a layer change cannot be read as 'done' without polling status

- **Category:** scripting
- **Severity:** nice-to-have (score 1)
- **Installations:** 1 (0 verified)
- **Total occurrences:** 1
- **Projects affected:** Neon Swarm
- **Entries:** Neon Swarm/FB-0022
- **Suggestion:** goToSection and setIntensity could return the audio frame the change lands on, or take an onDone callback.
- **Workarounds seen:**
  - The tests step the game a bar and read status.section / status.stemGains; the game script does not need the answer.

## 25. A trailer needs a custom director script and a long recording

- **Category:** tooling
- **Severity:** nice-to-have (score 1)
- **Installations:** 1 (0 verified)
- **Total occurrences:** 1
- **Projects affected:** Tidewater Market
- **Entries:** Tidewater Market/FB-0055
- **Suggestion:** A Timeline or Cutscene component (camera keys, text cards, fades) and a progress line for --record-video.
- **Workarounds seen:**
  - store/trailer/trailer.js and make_trailer.py.

## 26. Hand-keyed clips (bite, attack) need many set_keys calls and a guess of the euler axes

- **Category:** animation
- **Severity:** nice-to-have (score 1)
- **Installations:** 1 (0 verified)
- **Total occurrences:** 1
- **Projects affected:** Kindlewatch
- **Entries:** Kindlewatch/FB-0018
- **Suggestion:** A `bite`/`lunge` generator (a body reaches forward and the head snaps down) and an anim3d.pose command that sets a named pose (head_down, arm_up) to key between.
- **Workarounds seen:**
  - set_keys by hand with filmstrip checks (anim/wolf_bite.anim.json, anim/warden_attack.anim.json).

## 27. No undo/redo or data-table validation helpers for game state

- **Category:** scripting
- **Severity:** nice-to-have (score 1)
- **Installations:** 1 (0 verified)
- **Total occurrences:** 1
- **Projects affected:** Tidewater Market
- **Entries:** Tidewater Market/FB-0003
- **Suggestion:** Document a recipe for validating data tables in a project tool (file, pointer, hint, did-you-mean), and offer a did-you-mean helper to scripts so each game does not write its own; optionally a small history helper.
- **Workarounds seen:**
  - scripts/game/state.js (transactions with exact deltas, undo and redo refuse and emit action.rejected), scripts/game/data.js (validateTables with file, JSON pointer, hint and didYouMean) and the project tool project.validate_data.

## 28. Rigged, animated characters cost one draw call per material part and cannot be merged

- **Category:** rendering-3d
- **Severity:** nice-to-have (score 1)
- **Installations:** 1 (0 verified)
- **Total occurrences:** 1
- **Projects affected:** Kindlewatch
- **Entries:** Kindlewatch/FB-0021
- **Suggestion:** rig.bake option mergeParts that welds parts with the same material and the same skin method.
- **Workarounds seen:**
  - None: the count stays at 75 draw calls, well under the budget of 120.

## 29. Style warnings flag assets that are deliberately different from the project style

- **Category:** tooling
- **Severity:** nice-to-have (score 1)
- **Installations:** 1 (0 verified)
- **Total occurrences:** 1
- **Projects affected:** Kindlewatch
- **Entries:** Kindlewatch/FB-0009
- **Suggestion:** Let a rule be disabled by an asset's role (ui, icon, particle) or by a tag in the provenance, and apply texelsPerUnit only to textures a 3D mesh uses.
- **Workarounds seen:**
  - style.ignore lists the sky, logo, pine art, flame, icons, panel and bar pictures in assets.json.

## 30. anim3d.generate and anim3d.retarget leave no provenance or recipe in assets.json

- **Category:** animation
- **Severity:** nice-to-have (score 1)
- **Installations:** 1 (0 verified)
- **Total occurrences:** 1
- **Projects affected:** Gem Roller
- **Entries:** Gem Roller/FB-0013
- **Suggestion:** Let anim3d.generate and anim3d.retarget write a provenance record with a recipe (inputs: the rig .glb and the source clip) like rig.bake does, so assets.regenerate {stale:true} follows a re-fit of the rig.
- **Workarounds seen:**
  - Recorded the two clips with assets.set_provenance (origin original, provider 'factoria anim3d.generate', the rig as source, the call in notes).

## 31. game.findByTag is missing from factoria:test, world.findByTag must be imported

- **Category:** tooling
- **Severity:** nice-to-have (score 1)
- **Installations:** 1 (0 verified)
- **Total occurrences:** 1
- **Projects affected:** Kindlewatch
- **Entries:** Kindlewatch/FB-0014
- **Suggestion:** Add game.findByTag (and game.findAll) beside game.find in factoria:test.
- **Workarounds seen:**
  - import { world } from "factoria" in the tests.

## 32. image.create cannot name the PNG the document bakes to

- **Category:** assets
- **Severity:** nice-to-have (score 1)
- **Installations:** 1 (0 verified)
- **Total occurrences:** 1
- **Projects affected:** Lantern Keep
- **Entries:** Lantern Keep/FB-0048
- **Suggestion:** Accept `output` in image.create.
- **Workarounds seen:**
  - The two pixel-art documents sit next to their PNGs, as in gem-roller.

## 33. sfx.bake takes no path and there is no one-line re-render of a single sound patch

- **Category:** docs
- **Severity:** nice-to-have (score 1)
- **Installations:** 1 (0 verified)
- **Total occurrences:** 1
- **Projects affected:** Kindlewatch
- **Entries:** Kindlewatch/FB-0010
- **Suggestion:** Say in sfx.bake's summary that it renders every stale patch and that sfx.render renders one, and have both accept `path`.
- **Workarounds seen:**
  - assets.regenerate {"stale":true} after every edit.



# Next engine milestones

**What comes next (2026-11-10):** M90 (0.20.0) and M91 (0.21.0) are done. Next M100 and M101 (the examples' feedback
and a third outside review, planned 2026-11-10), then M97.1 and M97.2, then M92, M93, M94, M95, M96 and M98, and only
then M71-M89 in their own order: M71 needs M95's frame graph and M75 needs M94.4. M99 waits for the user's hardware and
accounts. The reasons are in "M90-M99" and "M100-M101", at the end of this file. Every milestone opens with a triage of
the open entries of `examples/*`. Update this paragraph when a milestone lands.

Finished milestones are not kept here: each has a file in [done/](done/README.md) (one line per milestone). This file
holds the open entries, the decisions of finished milestones and the milestones that are open or partly open.

Hand-written triage section (the ranked list above is generated; regenerate it with the command in
`feedback/README.md` and keep this section). Triage date 2026-10-13, against commit `e2b0090`: of the 55
entries from the four example games, the engine already fixed most; the work packages below cover what is left,
plus two packages for gaps seen while verifying that no game has hit yet (marked *proactive*).

Re-triage 2026-10-16, after `497303d` (v0.1.4), from an external evaluation: a veteran developer tried to take a game
from `factoria new` to every store with v0.1.4 and listed 82 numbered gaps plus a few notes (the ids below are the
report's: H tools, F engine features, E exports, S store services, A asset generation, D docs, U game menus, Q production
quality; the report itself is not in the repository). Every gap was checked against the code; all of them held.
- Fixed in the same PR as this triage: E-01 (the Windows player and every exported exe are GUI programs: no console
  window, and a terminal that starts one still gets its log), E-02 (the exe's version information is the game's name
  and version), E-06 in part (every run writes `log.txt` in the save folder; crash reporting is M13), E-11 (paths over
  260 characters on Windows; with `--json` a failure prints a JSON error object), Q-07 (a missing glyph logs one warning
  per font naming the characters and a font that has them) and D-06 (GETTING_STARTED status table).
- Already listed, not repeated: E-03 and Q-02 (M8, "Left open"), H-11 and the Android shutdown part of F-10 (M9, "Found
  while implementing M9"). Q-01 (the project's age, one maintainer) and Q-08 (a strength) are not engine work.
- Everything else, and the points of the report's per-store table that no id covers, is grouped in M10-M23 below, in
  the report's order of priority: what blocks any store release first.
  None of these gaps came from the four example games, which are jam-sized and never needed menus, localization or
  stores; M21 adds a complete reference game to close that blind spot.

Triage 2026-10-19 of the 45 entries of Lantern Keep, the M21 reference game, against `04e751b` (each checked in the code
and in a scratch project with `factoria test` and `factoria call`): LK/FB-0032 was already fixed (`ui.measureText` is
exact wherever a renderer exists, tests included; only TEXT.md still says otherwise, LK/FB-0042), LK/FB-0030 is a
duplicate of LK/FB-0008 and LK/FB-0034 of LK/FB-0015 (their occurrences were merged), and every other entry still
holds. The 42 open ones are the packages of M24 below, plus LK/FB-0009 in M20, four in M21, two in M22 and LK/FB-0023
in M23.

Re-triage 2026-10-20, after M24.1-M24.6 (merges `b6c6f3b`, `1341def`, `2ee41ac`, `d891e92`, `43e03b9`, `acd5baf`): 13
Lantern Keep entries are fixed, each with a `Fixed in <commit>` note, and the game dropped their workarounds in the
`m24/bookkeeping` PR; LK/FB-0026 stays open for its matchers (M24.7). 29 Lantern Keep entries are open.

Re-triage 2026-10-20, after M24.7-M24.14 (merges `da5f957`, `7506b4b`, `343a7b8`, `7c29612`, `3768d21`, `f4071e7`, `2320973`,
`2e0fa55`): 22 more Lantern Keep entries are fixed, each with a `Fixed in <commit>` note, and the game dropped their
workarounds in the `m24/bookkeeping-2` PR (`scripts/ui/text_fit.js` is gone). Dropping it showed two new gaps,
LK/FB-0046 and LK/FB-0047 (M24.15, M24.16). 9 Lantern Keep entries are open.

Re-triage 2026-10-20, after M24.15-M24.16 (merges `62f24f9`, `7b57f09`): LK/FB-0046 and LK/FB-0047 are fixed, each with
a `Fixed in <commit>` note, and Lantern Keep dropped its workarounds in those PRs. 7 Lantern Keep entries are open:
LK/FB-0009 in M20; LK/FB-0014, LK/FB-0017, LK/FB-0022 and LK/FB-0023 in M21; LK/FB-0037 and LK/FB-0038 in M22;
LK/FB-0023 also in M23, for MSIX.

Re-triage 2026-10-20, after M21's #115-#117 (merges `02b1555`, `0e49b93`, `97f693c`): LK/FB-0014, LK/FB-0017 and
LK/FB-0022 are fixed, each with a `Fixed in <commit>` note, and Lantern Keep dropped its workarounds
(tools/make_icon.py, tools/make_screenshots.py) in those PRs. 4 Lantern Keep entries are open: LK/FB-0009 in M20;
LK/FB-0037 and LK/FB-0038 in M22; LK/FB-0023 in M23, for MSIX (its Microsoft Store docs are in, from #115).

Re-triage 2026-10-21, after M22 (merges `972974b`, `8d40daa`, `441405b`, `67fe125`, `40ebbeb` and #132): LK/FB-0037 and
LK/FB-0038 are fixed, each with a `Fixed in <commit>` note; Lantern Keep does not use those features yet. 2 Lantern Keep
entries are open: LK/FB-0009 in M20 and LK/FB-0023 in M23, for MSIX.

Re-triage 2026-10-22, after M20.1 (merge `9b92c45`, #134): LK/FB-0009 is fixed, with a `Fixed in <commit>` note; Lantern
Keep had no workaround to drop (its `levels/<id>.json` maps were already the source of truth). 1 Lantern Keep entry is
open: LK/FB-0023 in M23, for MSIX.

Re-triage 2026-10-22, after M23's Mac App Store and MSIX packages (`3ec0864`, `6364e8f`, the `m23/stores` PR): LK/FB-0023
is fixed, with a `Fixed in <commit>` note; Lantern Keep had no workaround to drop (its SHIPPING.md now points at the
export). No Lantern Keep entry is open.

Triage 2026-10-22 of the 55 entries of Clockwork Courier, the M25 reference game, against `0ffcee5` (each checked in
the code, several reproduced in a scratch project with `factoria test`, `factoria call` or `factoria validate`):
CC/FB-0033 was fixed during M25; CC/FB-0007 was already fixed (`entity.animator.get(name)`, `e3ab260`; ANIMATION.md now
shows it) and CC/FB-0022 was not an engine gap (the built-in font has ★ and ☆; TEXT.md now says so); CC/FB-0027 is a
duplicate of CC/FB-0021 and CC/FB-0053 of CC/FB-0015 (their occurrences were merged). Ten entries hold only in part, and
their notes say which part. Verifying CC/FB-0020 found a bug no game reported: a focused `TextField` does not raise the
phone's keyboard, though MOBILE.md says it does (M26.17). The 50 open entries are the packages of M26 below; parts of
three stay in M12 (the real ads and leaderboard-period backends, CC/FB-0028 and CC/FB-0030; the Steam Deck keyboard,
CC/FB-0020) and part of one in M19 (the video player, CC/FB-0051). Two M19 items moved to M26 because a game needed
them: the navmesh (M26.10) and `scene.loadAsync` (M26.7). What is left of M19 and of M12 is ranked in their sections.

Re-triage 2026-10-24, after M26 (#149-#176; each package's merge commit is in done/M26.md): 49 Clockwork Courier
entries are fixed, each with a `Fixed in <commit>` note, and the game dropped their workarounds in the `m26/bookkeeping`
PR (its own grid pathfinding, the eight copies of the level panels, the letter grid of the name screen, the dark-tint
paints, the hand resets between tests). CC/FB-0051 stays open for M19's video player; the parts left to M12 are in its
ranking. Moving the game onto the navmesh found one more entry, CC/FB-0056 (no rope bridge, seesaw or moving platform in
the mesh, no off-mesh links), ranked second in M19. M27 takes what the games asked of M12 and M19.

Re-triage 2026-10-25, after M27 (#179, #180, #182-#185; each package's merge commit is in done/M27.md): CC/FB-0051
and CC/FB-0056 are fixed, and so are the parts of CC/FB-0020, CC/FB-0028 and CC/FB-0030 left to M12; each has a
`Fixed in <commit>` note. Clockwork Courier's studio intro is a video (#182), its dogs cross the bridges (#179), and its
name screen's keyboard is the kit's again, which stays closed under Steam's (the `m27/bookkeeping` PR). No entry of any
example game is open: the ranked list above is empty.

Triage 2026-10-25 of the 38 entries of Burrow Brigade, the M28 reference game, against `c7e6ef6` (each checked in the
code; the doubtful ones reproduced in a scratch project with `factoria test` and `factoria call`): BB/FB-0028 is a
duplicate of BB/FB-0009 (the bookkeeping PR merges their occurrences), with one thing more: the `maxLights` perf budget
compares against a count that has no 2D lights, so it watches nothing. BB/FB-0024 and BB/FB-0035 need docs only
(`game.keyDown("Enter")` already submits a `TextField`; `fa.call("fs.write", ...)` works in a test). Three hold in part:
BB/FB-0031 (`optional: true` exists since `ce8b98c`, but `platform.add_backend steam` does not write it), BB/FB-0019
(`ui.layout()` is documented, but the lost click is silent) and BB/FB-0005 (the Controls tab already hides the actions a
game lacks). Verifying BB/FB-0012 found a bug no game reported: a scene that loads with the same music as the one before
plays nothing while `state().audio.music` says it plays (M29.7). The open entries became the 21 packages of M29 below; one
part of BB/FB-0036 (Thai without marked boundaries) and parts of BB/FB-0015 and BB/FB-0018 stay out (M29's last
paragraph).

Re-triage 2026-10-26, after M29 (the `m29/*` PRs; each package's commit is in done/M29.md): the 21 packages are
built and the 38 entries of Burrow Brigade are closed, each with a `Fixed in <commit>` note (BB/FB-0028 as a duplicate of
BB/FB-0009; the `m29/bookkeeping` PR). Burrow Brigade dropped its light pool and `activeLights` helper, its own A* and
behaviour tree, its whole-array tile writes, its binding table, its transport seam and its stdout recordings; its
Options offer the three window modes and a monitor, and a pad player follows its pad by id. What it keeps on purpose is
under M29, "Left open".

Triage 2026-10-26 of the 49 open entries of Tidewater Market, the M30 reference game, against `cf2664d` (each checked in
the code, by three read-only passes over the UI, the platform and export code, and the scripting and tooling code;
nothing was reproduced in a scratch project). TM/FB-0070 was fixed during M30, TM/FB-0015 was withdrawn and TM/FB-0030
is a duplicate of TM/FB-0010 (merged in M30's close-out). The ranked list counts 48 gaps because `feedback collect`
merged TM/FB-0010 (rich text) and TM/FB-0011 (an icon button), which are different (TM/FB-0072, M31.9). Five need docs
only or are already supported: TM/FB-0018 (`Button.autoShrink` and `minFontSize`, on main after 0.2.0), TM/FB-0046
(`game.press` holds an action until `release`; `game.tap` presses it for one frame), TM/FB-0063 (`fa.call` runs any
command from a test, and `i18n.state` is documented that way), TM/FB-0035 (a child is offset from its parent's
`Transform.position`, not from the panel's corner as the entry says: neither the parent's anchor nor its pivot applies)
and TM/FB-0016 (`activeInHierarchy` exists, with an empty doc string; `ui.rectOf` still returns a rectangle for a child
of a hidden panel, where `ui.state` does not). Thirteen hold in part: TM/FB-0001 (the draw order inside a layer is in
COMPONENTS.md since 2026-10-13), TM/FB-0004 (`factoria test FILE --filter` starts one engine per run, not per file),
TM/FB-0011 (a Sprite inside a Button does not take its clicks), TM/FB-0031 (a bold `.ttf` per Text works), TM/FB-0032
(`generator.seed(n)` sets the state; nothing reads it), TM/FB-0033 (the menu kit has `MenuStack`), TM/FB-0034 (exports
pack atlases by group, and Sprites keep naming the source PNGs), TM/FB-0037 (PLATFORM.md says `stats.add` is a get and a
set, but not in its test section), TM/FB-0045 (`activeVoices` is in the `state` command's `audio` only), TM/FB-0051
(the emsdk setup is in BUILDING.md, not next to the web export), TM/FB-0062 (TEXT.md explains `pyftsubset` by hand),
TM/FB-0064 (`maxTextScale` and wrapping at `maxWidth` exist) and TM/FB-0065 (column Panels stack Texts). Verifying
TM/FB-0060 found its cause, a bug: with a renderer a wrapped text measures at least its `maxWidth` (`fonts.cpp` takes
the larger of the two), while headless it measures its widest line, so a layout test passes where the window overflows
and `autoShrink` shrinks a short label for nothing (M31.4). Two more found on the way: SCRIPTING.md's test section calls
`ui.state()`, which scripts do not have (M31.3), and a `storage.set` inside a web `pagehide` handler only schedules the
500 ms IndexedDB flush, which may never run (M31.16). The open entries are the 26 packages of M31 below; the Timeline
part of TM/FB-0055, Windows and Linux players of a development build from CI artifacts (TM/FB-0051) and case and
agreement beyond gender (TM/FB-0061) stay out (M31's last paragraph).

Re-triage 2026-10-27, after M31 (the `m31/*` branches; each package's commit is in done/M31.md): the 26 packages are
built and 46 of the 49 open Tidewater Market entries are `fixed-in-engine`, each with a `Fixed in <commit>` note (the
`m31/bookkeeping` branch); TM/FB-0003, TM/FB-0051 and TM/FB-0055 stay open for the parts M31 left out. Tidewater Market
dropped the workarounds listed under M31, "Left open", and its README and SHIPPING.md lost the sentences that described
them. Its ground is one isometric Tilemap now, so its perf files say 246 entities (game), 112 (title) and 1029 (stress).

Sizes: S = under a day for an AI agent, M = 1-3 days, L = a week or more. Ids are `<game>/FB-n`
(sky-hopper = SH, neon-swarm = NS, gem-roller = GR, block-push = BP, lantern-keep = LK, clockwork-courier = CC,
burrow-brigade = BB, tidewater-market = TM, larkspur-lodge = LL, kindlewatch = KW, ember-descent = ED).

## Decisions of finished milestones

Kept here because later work has to respect them (the full story is in done/M1.md ... done/M91.md, indexed in done/README.md):
- M3: there is no `CameraFollow2D` component; a camera that follows within level bounds is the AI_GUIDE 9.6 recipe.
  `scene.import_ascii` does not keep its legend in the scene, so `factoria validate` checks the Tilemap data instead.
- M4: bloom is flat `Camera` fields (`bloom`, `bloomThreshold`, `bloomIntensity`, `bloomRadius`) because reflection has
  no nested structs. It costs about 5 ms per drawn frame at 1280x720 on llvmpipe (the target was 2 ms); a backend that
  cannot create it logs one error and draws without bloom.
- M5: gamepad bindings keep the names reserved since 0.1 (`GamepadA`, `GamepadLeftStickLeft`...), not `Gamepad:A`; a
  binding matches any of 4 pads; `input.value` is analog with a radial deadzone (`input.deadzone`, default 0.2) and an
  action is down at 0.5.
- M6: file-targeted component edits are the `edits` argument of `scene.import_ascii` (file mode, the
  `scene.set_component` code); scene, prefab and JSON files are written through `fs::write_bytes` (a temporary file
  renamed over the target).
- M8: spheres with `rollWithMotion` keep the arcade model, other spheres are rigid bodies; boxes do not roll
  (`angularDamping` is their spin drag). Mobile exports use the package's prebuilt players (`mode: prebuilt`), the
  engine checkout only when asked for or when factoria runs from a source build (`mode: source`).
- M9: the players ask for OpenGL ES 3.0 and sokol_gfx is told 3.0 even when the driver reports more: the engine uses no
  ES 3.1 feature. On Android, sokol_app's exit in `onDestroy` is turned into `_exit(0)` and the activity is
  `stateNotNeeded`, so the system starts the game again in a new process. macOS exports are signed ad hoc after every
  file is written; Developer ID signing then needs `--force`.
- M10 (2026-10-16): templates stay minimal (the empty ones are a camera and nothing else); a game's AI builds menus
  from the recipe when its game needs them. UI focus comes only through `autoFocus` or `ui.focus`, so Space or A never
  clicks a HUD button.
- M11: a plugin that does not load is a warning, and its reason becomes the script's error.
- M14: headless runs, tests and the editor start in `localization.defaultLanguage` (output and saved scenes never depend
  on the machine); a game in its own window and an exported game start in the best match of the system's languages;
  `FA_LANGUAGE` / `EngineConfig::language` override both. A component with a `key` gets its text overwritten at run time.
  The font chain is the Text's `font`, `localization.languageFonts[language]`, `localization.fallbackFonts`, then DejaVu
  Sans; there is no per-Text fallback list. `align` is explicit (Left is the left edge for right-to-left text too). The
  engine saves neither the language choice nor `ui.textScale`: the game keeps them in `storage`.
- M15: exports ship the import settings of `assets.json` and drop provenance and style.
- M24 (2026-10-20): a direction press moves the focus to the nearest widget lined up with the focused one (overlapping
  it across the direction), and only when there is none to the nearest in that half of the screen; not a 45-degree
  cone, which sent Down from a narrow tab past the row under it. Script vectors keep `length()` as the magnitude (only
  `Color` and `Rect` have a numeric `length`). `game.paused = false` restores the `time.scale` that pausing saved. A
  `storage.json` that does not parse is kept beside the new one and never repaired; the game starts with empty data.
  A dynamic 2D body's `velocity` is relative to the kinematic body it stands on (as in 3D); a game adds no platform
  speed of its own. `onEnable` follows `onStart` on the first activation, and the activation hooks run before the frame
  is drawn. `autoSize` and the right-to-left values are opt-in: `Text.align` `left` / `right` stay explicit (M14),
  `start` / `end` and `Panel.direction` (default `ltr`) follow the language; a `size` a script or file writes is the new
  design size. In file mode `scene.import_ascii` writes prefab references. The catalog's translated texts are for the
  game's own screens and the fake store; Steam, the App Store and Google Play keep theirs in their own consoles.
  M24.15-M24.16 (2026-10-20): the fallback layout (`fallbackLayout`) is chosen again every frame, and the deepest panels
  switch first; `uniformSize` counts only `autoSize` widgets; a script's `ui.layout()` does not log the fit warning.
- M22 (2026-10-21): the system's accessibility settings are `game.accessibility`, not `platform.accessibility`
  (`platform` is the store services); like the language (M14), only a game in its own window reads them, headless runs,
  tests and the editor get the defaults, and the engine applies none of them: the game starts its options from them and
  saves its own choice. `Camera.colorFilter` is the last pass of the frame (HUD included) and is not saved by itself;
  `simulate` changes only the saved screenshot. Headless runs and tests speak nothing and record the lines
  (`game.spoken()`); the web prefers voices on the device, because an online voice sends the text to its provider. A
  caption's lifetime is its sound's unless `captionSeconds` is given (a looping sound needs it). Performance budgets: a
  time over its limit fails only in CI and is measured twice first, memory, draw calls and entities always fail, and the
  engine's own CI fails on a runner with no baseline (`requireBaseline`); a game's check passes there with the entry to
  commit.

- M26 (2026-10-24): a command writes only what it is asked to: `scene.format` with neither `paths`, `all` nor `check`
  writes nothing, and `factoria.json` is patched (its order and formatting kept), never rewritten. A character is
  carried by the kinematic body it stands on (`carriedByPlatforms`, default true) and never shoves a body held by a
  joint. `game.today()` is a fixed date in tests and headless runs and the recorded one in a replay; `pauseOnSuspend` is
  on by default. A mesh under an animated node gets a rigid skin of one joint at import. `platform.release` is false in
  development runs and tests. The navmesh is a deterministic 2.5D grid baked from the static colliders. `connected: ""`
  on a joint is the world. `materialColors` replaces a material's base colour and `color` still tints the whole model.
  `fill` wins over `shrink` in a list; a slider value a script sets sends no `ui.change` (`game.setSlider` does). A
  spawn index outside the parent's children is an error, and a root takes no index. The simulation uses only
  `fa::det::` maths with no floating-point contraction, and CI compares one committed replay hash on every desktop job.
  `project.add_menu_kit` never replaces a key or a file the game edited unless asked (`overwrite`).
- M27 (2026-10-25): a plugin backend that offers only `ads` is an ads backend next to the store backend
  (`platform.ads.backend` picks one); development runs and tests keep the fake, and an export without `--release`
  always uses Google's test app id and ad units. Apple's tracking sheet comes only after Google's consent form, only
  with `trackingPrompt`, and never for a player under age; a `mixed` audience requests nothing until the game tells the
  age. A daily or weekly board is one Steam board per period. A platform keyboard takes a `TextField` through plugin API
  3 (versions 1 and 2 load unchanged) and the kit's keyboard stays closed while `input.platformKeyboard` is true. Video
  is MPEG-1 + MP2 decoded by pl_mpeg on the CPU, the same on every platform, on the game clock; other formats are
  converted at import, never played. An opaque `Video` skips its background and blending, and plain textured quads use
  a shader without the glyph, shape and light branches. A `navWalkable` body is left out of the static bake and
  re-marked where it is; off-mesh links are `NavLink3D` entities, and a path lists where it takes them.
- M29 (2026-10-26): every active `primary: true` camera draws into its `Camera.viewport`, in ascending `depth`, up to 8;
  bloom and `colorFilter` run once with the lowest-depth camera's settings and the UI is drawn once over the whole screen
  (a scene with a second primary camera that used to be ignored now draws it: `primary: false` turns one off). 2D lights
  add up in a light buffer (up to 256 per frame, 32 of them casting tile shadows, which are traced on the CPU), while a
  lit visual with a normal map, and a perspective camera, keep the per-pixel loop over the first 16. `analytics` and
  `remoteConfig` are script modules on `http.fetch`, not services: no analytics event is kept or sent before consent, and
  a game names its servers in `network.hosts`. `input.player(i)` gives each of up to four players their own actions from
  a pad or a key scheme (`input.schemes`); players do not read the mouse or touch. The tile A* (`nav.findTilePath`) and
  the `bt` module are deterministic. `window.setMode` takes `"windowed"`, `"borderless"` and `"fullscreen"`, which look
  the same on Windows and Linux. `game.click` throws, naming the widget, when it is inactive, has no area or is scrolled
  out of its `ScrollList`, instead of clicking nowhere. A scene load restarts its music unless `audio.music(path,
  {persist: true})` keeps it; bus effects and volumes stay across scene loads. A daily leaderboard without `day` is the
  local date's, and a game that wants one board worldwide passes `game.today().utc.iso`. Wrapped Thai breaks only at
  marked boundaries (U+200B). `assets.synth_sound` levels to -18 LUFS. A cloud save has no conflict signal: a game keeps
  a revision counter in the saved value.

## M8. Leftovers of M7, desktop download next steps (L, *proactive*)

Closes the "Found while implementing M7" and "Desktop download: next steps" lists (both in done/M7.md and done/M8.md). One worker
branch per package, merged together in PR #29.

Built: [done/M8.md](done/M8.md).

Left open, not fixable in this repository alone:
- Certificates: an Authenticode certificate or Azure Trusted Signing is needed before the Windows signing step does
  anything (macOS signing is set up since M9). New Authenticode certificates come on a token or a cloud HSM, so the
  `.pfx` path in `scripts/sign-windows.sh` may have to become that service's signing action.
- GitHub-hosted runners cannot run an arm64 Android emulator (no KVM on `ubuntu-24.04-arm`, no nested virtualization on
  macOS) and have no real GPUs; that needs a device farm with an account. `simctl` cannot tap, so iOS touch is not run.
- No real gamepad has been used on Linux or Android; the Android Z/RZ trigger scaling is taken from Android's docs.
- 3D: a kinematic body's own rotation within a sub-step is not swept; in an extreme pile of impacts a body lags in time
  instead of tunnelling.
- The AppImage does not update itself (AppImageUpdate/zsync would), and after an in-place update the Windows "Apps" list
  still shows the installed version.

## M12. Platform services API (L, blocker for Steam and for any monetization)

Closes S-01..S-08 (S-09 is in M23), and the Play Integrity, iCloud and Steam Deck keyboard points of the per-store
table. Needs M11.

- A `platform` JS module: achievements, stats, leaderboards, cloud saves, purchases (with restore and receipts), overlay,
  presence, and `platform.has("achievements")`. A fake backend runs in `factoria test` and headless runs, with
  `game.platform` hooks to script store answers in tests.
- Backends as M11 plugins, in this order: Steamworks (S-02; `steam_appid.txt` in development runs), StoreKit 2 and Game
  Center (S-04, S-05), Play Billing and Play Games v2. Then Epic Online Services and GOG Galaxy (S-03), ads with
  consent (Google UMP, Apple ATT; S-06), analytics and remote config (S-07), push notifications and deep links (S-08).
- Steamworks also brings the Steam Deck's on-screen keyboard (`ShowGamepadTextInput`, the floating keyboard) for M10's
  text field; M16's keyboard is mobile only.
- Play Integrity (Google Play) next to Play Billing, and iCloud as a cloud-save backend next to StoreKit.
- Later: the purchase SDKs of Android stores outside Play (Amazon Appstore, Samsung Galaxy Store, Huawei AppGallery).

Acceptance criteria:
- Achievements and a purchase flow pass with the fake backend in a test (on the M10 menus fixture).
- With the Steamworks plugin and Valve's test AppID 480, an exported desktop game unlocks an achievement (manual check,
  steps in the docs).

Done so far (package A, branch `m12/platform-api`): the API, the fake backend and plugin ABI v2; no store backend yet.
- **`fa_services`** (new module, `fa/services/platform.h`): the `"platform"` catalog of factoria.json (achievements,
  stats, leaderboards, products, per-backend store `ids`, `backend`; teaching errors, `factoria validate` and the
  project schema), the request protocol `(method, args) -> one answer`, the `PlatformServices` dispatcher (ids checked
  and `storeId` filled in before a backend sees a request; answers from any thread, delivered at the start of a frame),
  the `PlatformBackend` interface, the deterministic fake backend (scripted answers, `delayFrames`, `signedIn`, events,
  a request log) and the "none" backend. The `platform.*` commands (`state`, `reset`, `respond`, `emit`, `set_fake`).
- **Scripts**: `platform` in the `factoria` module (every call a Promise; mistakes throw with a "did you mean", store
  failures reject with `.code` and `.hint`; `platform.on` for `purchase`, `overlay`, `player`), and `game.platform`
  in `factoria:test`; `await` works in tests.
- **Plugin ABI v2** (`fa_plugin.h`): `add_backend`, `FaRequest`, `resolve`, `reject`, `emit`; version 1 plugins load
  unchanged. Backend choice: `platform.backend`, `EngineConfig::platformBackend/platformFallback`; headless runs and
  tests use the fake, an exported game without a store plugin gets "none" (never free purchases). `project.new_plugin`
  takes a `template` (the folders of `platforms/plugins/`, none yet).
- **Docs and fixture**: `docs/PLATFORM.md` (API, catalog, errors, fake store and testing, writing a backend plugin);
  the menus fixture has a shop (consumable gems, a non-consumable, restore) and `tests/platform.test.js`: buying gems
  through the pad adds them and finishes the transaction, a cancelled buy and a `network` failure grant nothing, a
  delayed answer shows "waiting", restore returns the non-consumable, an achievement unlocks during play and the
  overlay event pauses the game (the first acceptance criterion).

Done so far (package B, branch `m12/steam`): the Steamworks backend.
- **`platforms/plugins/steam`** (the `"steam"` template of `project.new_plugin`, a C++17 plugin with no Valve file in the
  repository): it loads Valve's redistributable at run time (`steam_api64.dll`, `libsteam_api.dylib`, `libsteam_api.so`,
  next to the plugin first), declares the part of the flat API it uses itself and finds the versioned interfaces by name
  (checked against SDK 1.58 to 1.64; a newer SDK such as 1.65 is used with a warning when every function the plugin calls
  is present, probing up to five interface versions above the known ones; anything else is refused with what was tried). Steam
  starts in `fa_plugin_init`
  (`SteamAPI_InitFlat`, `SteamAPI_Init` on old libraries), callbacks run by manual dispatch in the plugin's `frame`, and
  the dev app id comes from `steam_appid.txt` (project folder or working folder; 480 is Valve's test app). Every failure to
  start is a teaching log line and the engine falls back (fake in development, none in an exported game).
  Achievements (unlock, progress, list, reset), stats, leaderboards (created on first use, keep-best uploads, top, around
  and friends), Steam Cloud (`<key>.json`), DLC purchases (`pending` through the overlay cart, a `purchase` event when the
  DLC arrives), overlay, rich presence, and the events `overlay`, `purchase`, `player`. Consumables and subscriptions are
  `unavailable` (Steam's microtransactions need the game's own server). The command `steam.status` shows what the plugin found.
- **Tests**: a mock of the Steamworks library (`platforms/plugins/steam/tests/mock_steam_api.cpp`, built as a shared library
  with the redistributable's file name, in a current, an older (SDK 1.58 to 1.60), a next (one interface version above the newest known) and a far-future variant) and ctest `steam_plugin_*`
  (Linux, Windows, macOS): the real plugin in an Engine with `platformBackend="steam"` covers every method and event, stats that
  load late, Steam failing to deliver or to start, a late answer after the engine ended, a stray call result, a missing
  library, Steam not running, no app id, the services again on a library with newer interface versions (used, one warning), a
  library too far ahead (refused), and the exit on Linux and macOS (stats stored, `SteamAPI_Shutdown`). `tooling` tests build
  the plugin through `platform.add_backend` with an SDK folder and a .zip.
- **`platform.add_backend {"backend": "steam"}`**: writes and builds the plugin, copies the three libraries from the SDK folder or
  .zip, writes `steam_appid.txt` (default 480), and `factoria export` never ships that file. Docs: the Steam section of
  `docs/PLATFORM.md` with the numbered manual check against app 480, and `plugins/steam/README.md`.

Left open (Steam):
- **The manual check with app 480 has not run**: it needs a Steam client and account, which the machine that built this did
  not have (`docs/PLATFORM.md`, "Manual check with Valve's test app 480"). Everything above is tested against the mock only,
  so struct layouts, callback ids and interface versions rest on the public Steamworks headers (SDK 1.58a to 1.64); a real
  SDK 1.65 library (it replaced `ISteamUtils::IsRunningOnSteamDeck`) has not been tried either. Whether
  Steam's overlay appears over the engine's Metal (macOS), OpenGL (Linux) and Direct3D 11 (Windows) windows is unchecked.
- ~~The Steam Deck on-screen keyboard for `TextField` is not wired~~: done in M27.4 (plugin API 3, Steam's floating
  and full-screen keyboards, `input.platformKeyboard`), tested against the mock, not on a real Deck.
- Steam Inventory, microtransactions (`ISteamMicroTxn`), Steam Input and the workshop are not wrapped; there is no `SteamAPI_RestartAppIfNecessary`
  (a shipped game started outside Steam runs without platform services); prices of DLC are not shown (Steam gives them on its store page).
- On Windows the plugin does not call `SteamAPI_Shutdown` at exit (a DLL's exit handlers run after Steam's own DLL is gone);
  stats are stored every frame, so only the last frame's changes could be lost.
- Every engine that loads the plugin starts Steam, `factoria test` and MCP sessions included; the plugin API cannot tell a plugin
  which backend the engine chose, so the fake-store runs show up as "playing" in Steam. A lazy start needs an API call for
  "the engine uses your backend".

Done (package C, branch `m12/apple`): the Apple backend, `platforms/plugins/apple`, backend `"apple"` on iOS and macOS.
- **The plugin** (Swift, built with `xcrun swiftc` by its CMake file; a C file is the entry point): StoreKit 2
  purchases (products, buy with Ask to Buy, finish, restore, `purchase` events for updates and unfinished transactions;
  receipts are JWS), Game Center (sign-in with a `player` event, achievements, leaderboards, the access-point overlay),
  iCloud key-value cloud saves, and the command `apple.status`. No stats and no presence (Game Center has none).
  Tests (`apple_backend_tests`) load the real dylib into a real Engine with no signature or Apple Account: every
  request is answered once and in time, each refusal teaches.
- **Plugin manifests**: `ios/plugin.json` / `macos/plugin.json` (system frameworks, the Swift runtime, entitlements),
  merged by the exports: the iOS project links StoreKit and GameKit and the Swift runtime and is signed with
  `factoria_player.entitlements`; the macOS export writes `<game>.entitlements` for the developer's own signing.
  `factoria export --platform ios` also writes `Products.storekit` from the catalog and wires it into the Xcode
  scheme. `platform.add_backend {"backend": "apple"}` writes, declares and builds the plugin. CI: the `ios` job
  links the plugin into the simulator app and checks `Apple backend ready`, `probe backend=apple` and a Game Center
  answer (`FA_IOS_APPLE_PROBE=1`).

Left open for the Apple backend (manual checks, docs/PLATFORM.md "Manual checks"): a real purchase, Ask to Buy, restore,
Game Center sign-in, achievements, leaderboards and iCloud sync need App Store Connect, a development-signed app and a
sandbox account, so no CI job runs them. The scheme reference to `Products.storekit` and the file's schema version are
not yet checked in Xcode itself. A macOS app needs the developer's certificate and provisioning profile for Game Center
and iCloud (the export is ad hoc signed). No `cloudChanged` event when iCloud brings a newer save from another device.

Done (package D, branches `m12/integrity` and `m12/googleplay`): the Google Play backend and a new platform service.
- **`integrity`**, the eighth service (`fa_services`, `platform.integrity.token(challenge)` -> `{ token }`): a signed token
  that vouches for the app and the device, for the game's server to verify. The engine checks the challenge (16 to 500
  characters of URL-safe Base64) and the shape of the answer; the fake answers `fake-integrity-<n>`. Steam and Apple do not
  offer it (`unavailable`).
- **`platforms/plugins/googleplay`** (the `"googleplay"` template, backend `"googleplay"`, Android only): a C bridge (JNI:
  every request goes to `Backend.request` in Java, answers come back through `RegisterNatives` callbacks) and a Gradle
  module in Java on Play Billing 9.1, Play Games Services v2 22.1 and Play Integrity 1.6. Purchases (consumables are
  consumed, the rest acknowledged; pending payments; `purchase` events for unfinished purchases at start and on every
  resume; receipts are Google's signed purchase JSON and signature), the overlay (Play Games screens, the Play Store page)
  and integrity are always on; achievements, leaderboards (25 rows a call) and Saved Games only with a Play Games project
  id in `games-ids.xml` (the plugin removes Play Games' auto-start provider and starts it only then). No stats and no
  presence. Each request answers once, with a 30 s watchdog (restore 120 s). The command `googleplay.status` lists what
  the device lacks.
- **`platform.add_backend {"backend": "googleplay", "playGamesId"}`**: writes and declares the plugin, writes the project id,
  builds the bridge for arm64-v8a and x86_64 with the Android SDK's NDK, CMake and Ninja, and lists the Play Console steps
  with the catalog's ids (product ids Play refuses, achievements and leaderboards without `ids.googleplay`). The exported
  Android project now has `android.useAndroidX=true` (Billing and Play Games need AndroidX).
- **CI**: `android-apk` sets the backend up with `add_backend`, checks the APK (both libraries, the plugin's and Google's
  classes in the dex, the merged manifest and resources); `android-emulator` (an image with no Google Play) checks
  `Google Play backend ready`, the services, `googleplay.status`, and that `signIn()` and `integrity.token` come back
  through JNI as teaching `unavailable`s. Tooling tests cover the setup command and the export of the module.

Left open (Google Play): **nothing has run against Google's services.** Purchases, Play Games and Play Integrity need a
Play Console app, a build on a testing track, license testers and a phone with Google Play (docs/PLATFORM.md section 7,
"CI and manual checks"); CI's emulator has no Google Play, and this machine has no NDK, so the Java was only compiled with
`javac` against the real libraries before CI. Play Games events (increment-only counters) are not mapped to stats;
`achievements.reset()` and the "friends" overlay are `unavailable`; Play Integrity uses the classic request (no Standard
API, no cloud project number, so an app distributed outside Play cannot get tokens). Apple's App Attest is not an
`integrity` backend yet.

Left open (the next M12 packages): Epic Online Services and GOG Galaxy, push
notifications and deep links, the Android stores outside Play (ads with consent and the GDPR/COPPA screen are done in
M27.1-M27.2; analytics and remote config in M29.21). `PlatformServices` keeps no receipts or entitlement cache: a
backend answers `restore()` itself. Overlay and presence are one call each; there is no `achievements.onUnlocked`
event, rich presence has no localization, and `platform.stats.add` is a get then a set (not atomic across devices).
Cloud saves take JSON values only (no binary blobs, no conflict resolution beyond "last write wins" in the fake).

Next M12 packages, ranked 2026-10-22 with Clockwork Courier's entries: 1. ads with consent on M26.9's API and fake:
Google UMP and AdMob, Apple ATT and the GDPR/COPPA screen (CC/FB-0028); 2. leaderboard periods on Steam, Game Center and
Play Games (CC/FB-0030); 3. the Steam Deck's keyboard with Steamworks (CC/FB-0020; M26.17 makes the in-game one);
4. ~~analytics and remote config~~ (done in M29.21, on M29.20's networking); 5. push notifications and deep links;
6. Epic Online Services and GOG Galaxy; 7. the Android stores outside Play. A game asked for the first three only: they
are M27.1-M27.4, done 2026-10-25. The other four wait for a game that asks for them. Burrow Brigade asked for the
fourth (BB/FB-0020), done in M29.21 on M29.20's `http.fetch`; the remaining three wait.

## M19. Runtime features (M each, medium; take them when a game needs them)

Closes F-07 (effects), F-09, F-10 (except the Android shutdown, M9), F-11, F-14, F-16, F-18, H-07 and U-08.

- Networking: ~~`http.fetch` (a Promise) in JS on every platform~~ (done in M29.20); WebSocket in JS; real-time
  multiplayer later.
- Saves: slots with their menu (on M10), a version field with a migration hook, optional encryption, cloud through
  M12's `platform`.
- Pathfinding: ~~grid A* on a Tilemap~~ (done in M29.11), ~~a navmesh for 3D (done in M26.10)~~, ~~off-mesh links and
  walkable moving platforms on `NavMesh3D`~~ (CC/FB-0056, done in M27.6), ~~a behaviour-tree helper module~~ (done in
  M29.11).
- ~~Video: a video player component for logos and cut-scenes~~ (CC/FB-0051, done in M27.5 with pl_mpeg).
- ~~`scene.loadAsync` with progress~~ (done as `scene.preload`, M26.7).
- ~~Split screen: a viewport rectangle on Camera~~ (done in M29.19).
- ~~Audio: effects on the buses (low-pass, reverb), ducking and snapshots~~ (done in M29.16).

Acceptance criteria: each item ships with its doctest or JS test and its docs, like any command or component.

Ranked 2026-10-22: the navmesh and `scene.loadAsync` moved to M26 (M26.10, M26.7) because Clockwork Courier needed them.
The rest, in this order: 1. video, for a studio intro (CC/FB-0051; recording an .mp4 is M26.19's); 2. off-mesh links and
walkable bridges and moving platforms on `NavMesh3D` (CC/FB-0056, added 2026-10-24: Courier's dogs stop at a bridge); 3.
save slots with a version and a migration hook (every store game saves); 4. networking (M12's analytics and remote
config need it); 5. audio effects, ducking and snapshots; 6. grid A* on a Tilemap and the behaviour-tree helper (they
can share M26.10's search); 7. split screen. A game asked for the first two only: they are M27.5 and M27.6, done
2026-10-25. The other five wait for a game that asks for them. Burrow Brigade asked for four of them: networking's
`http.fetch` (M29.20; WebSocket waits), audio effects (M29.16), grid A* and the behaviour tree (M29.11) and split screen
(M29.19), all done in M29 on 2026-10-26. Save slots and WebSocket wait. Tidewater Market (M30) wrote its own three
slots with a version and a migration on `storage`, and asked only for storage that scales (TM/FB-0022, done in M31.16) and a
picture of the town for a slot (TM/FB-0020, done in M31.24); the engine's save slots still wait.

## M23. Closed stores and consoles (L each, later) — Mac App Store and MSIX DONE (the `m23/stores` PR)

Closes E-08 and S-09, plus the Mac App Store and Microsoft Store rows of the report. Needs M11 and M12.

- Mac App Store: App Sandbox entitlements, Apple Distribution signing and a provisioning profile, a `.pkg` from
  `productbuild`, upload through the App Store Connect API (today only the Developer ID flow outside the store exists).
- Microsoft Store and PC Game Pass: MSIX packaging of the game (the engine's own installer is not one), Partner Center
  upload, the Microsoft GDK for Xbox services. Lantern Keep (LK/FB-0023) asks for `export.windows.msix` (identity name,
  publisher, display name, tile logos made from the icon) writing an `.msix` next to the folder, unsigned or signed with
  a `.pfx` from the environment, then `publish.microsoft`.
- Consoles (Switch, PlayStation, Xbox): their SDKs are under NDA and cannot live in this MIT repository. What this
  repository can do is the seam: a platform layer and render-backend interface (D3D12/GDKX, NVN, AGC) that a private M11
  plugin implements, and certification checklists (TRC, Lotcheck, XR) once a licensed developer contributes them.

**Done so far (Mac App Store).** `sign.macos` takes `distribution: "appStore"`: App Sandbox entitlements (plus the
plugins' and `export.macos.entitlements`, with the identifiers read from the provisioning profile), nested code signed
with the store identity (helpers inherit the sandbox), the profile embedded, `codesign --verify --deep --strict` and a
read-back of the entitlements, then `productbuild` and `pkgutil --check-signature` for `<slug>-macos.pkg`.
`export.macos` gained `buildNumber`, `usesNonExemptEncryption` and `entitlements`; `publish.appstore` uploads the `.pkg`
(`platforms: ["macos"]`, `altool --type macos`). The macOS-only test signs an export ad hoc with the sandbox, verifies it
and runs it (the sandbox container appears); the rest is covered with a fake process runner.
Left open (Mac App Store): a real signing with Apple certificates and a real upload (they need a paid account) were not
tried; `altool --type macos` is unverified on Xcode 27; the arm64-only rule is only a `lipo` warning, not checked against
Apple's documentation; the sandbox's effect on the player (saves, network) is tried only by the ad hoc run; no
`factoria validate` check beyond the settings' own and `sign.macos`'s warnings.

**Done so far (MSIX and Microsoft Store).** `export.windows.format` / `--format msix` writes a deterministic, unsigned
`<slug>-windows.msix` from any host (shared zip writer with a ZIP64 end record as MakeAppx writes, block map, manifest,
logos from the icon, no `resources.pri`), `export.windows.msix` holds the Partner Center identity (editor Windows tab,
Export window menu, validate warning), `sign.windows` signs it with a `.pfx` (signtool, or osslsigncode 2.9 or newer;
Windows-only self-signed test certificate) and `publish.microsoft` uploads it with `msstore`. Doctests unzip the package
and check the hashes, manifest and content types with an independent reader; sign and publish run against fakes. By hand
on macOS, osslsigncode 2.14 signed an exported package and verified it.

Left open (MSIX): the package has not been installed on a real Windows PC with `Add-AppxPackage` (the acceptance
criterion below); loose qualified logos without a `resources.pri` are unverified; a real upload needs a Partner Center
account (msstore was never run for real); `testCertificate` is Windows-only; PC Game Pass and the GDK are untouched.

Acceptance criteria: a sandboxed macOS export passes `codesign --verify --strict` with the App Sandbox entitlement and
runs (met: the macOS-only doctest signs ad hoc, verifies and runs it); an MSIX of an exported game installs with
`Add-AppxPackage` (not met yet: it needs a run on a Windows PC; osslsigncode signs and verifies the package on macOS).

## Art, 3D and audio tools inside the engine (M51-M60): shared rules (planned 2026-11-03)

M50 is the CI work of another session (0.15.0); these tools start at M51.

Asked by the user (2026-11-03): would games made by AI be better with art tools inside the engine (a raster and a vector
editor, 3D modeling, sound and music tools)? Yes, if the tools are made for the AI first: an AI does not drive a brush
or drag vertices, it writes and edits data it can read, rerun and check. Building a Photoshop or a Blender clone is not
the goal; giving the AI editable sources, operations as commands and a way to see and hear the result is.

What exists to build on: provider generation (M15: `assets.generate_image`, `_sprite_sheet`, `_sound`, `_music`,
`_voice`, `_model`), the house `style` in `assets.json`, `assets.rasterize_svg`, `assets.animate_svg` and recipes with
`assets.regenerate` (M41), `assets.generate_texture`, `assets.synth_sound` (fixed presets), `assets.generate_loop`,
`assets.analyze_audio`, the engine's Vorbis encoder, `mesh.create`/`mesh.save` (M44.2), keyframed 2D clips, `Bone2D` and
`SpriteSkin` (M42), the glTF `Animator` (skinned playback, no 3D bones made in the engine). PSD imports flattened.

Rules for every milestone below:
- **No external program.** Nothing may need Blender, Photoshop, a DAW, ffmpeg or anything else the user may lack:
  everything is factoria's own code or a vendored library with a permissive license (candidates are named per package;
  each package checks the license and records it in `external/VERSIONS.md` and LEGAL.md). External programs stay what
  they are today: optional MCP servers the user adds (M43).
- **AI first.** Every capability is a command with doc strings and teaching errors. The editor panel of each area is a
  view over the same commands, with the same undo.
- **Readable sources, baked outputs.** The source of an asset is a document an AI can read and diff (`*.image.json`, SVG,
  `*.model.json`, `*.sfx.json`, `*.audio.json`, `*.song.json`); the PNG, GLB or OGG the game loads is baked from it with
  the recipe in its provenance (M41.2), so `assets.regenerate` remakes it and a changed source warns as stale.
- **See and hear every edit.** Each editing command returns a preview (the picture, a turntable, a waveform and
  spectrogram) and the checks of M51, so the loop is make, look, check, fix.
- **Offline and deterministic.** Same document and seed, same output; no key needed. An asset provider, when one is set
  up, is an optional input (a generated layer, an inpainted selection), never required.
- **Shipped like every feature.** Docs (one new doc per area, embedded), typings, `factoria validate` checks, autotest
  sections for the panels, `api_since`, and an example game that adopts the tool and records gaps in its
  `ENGINE_FEEDBACK.json`. M51-M60 ship together, in one PR and as one version (0.16.0), when M60 is done (the user, 2026-11-03).

Order: M51 first (it multiplies every later tool), then 2D images (M52-M54: most FactorIA games are 2D), then audio
(M55-M56), then 3D (M57-M59), then a reference game that uses only these tools (M60). The audio and 3D blocks do not
depend on the 2D block and can move earlier if a game asks for them.

## M62-M64: ideas taken from outside projects (planned 2026-11-05)

From the user's bookmarks (2026-11-05). Rule for these three: an outside project is only a reference for HOW something
is done. FactorIA builds its own version; no code, effect, asset or shader of the outside project is copied or bundled,
and nothing is shipped "in case a game uses it" (a repository can disappear or change its licence). What enters the
engine is a capability that helps make games: commands, a script API, a generator, an AI loop, and a few worked
examples written for the docs. Each milestone names its reference so a worker can read it, not copy it.

## M66-M69: ideas from the second look at outside projects (planned 2026-11-06)

References: dsh-game-studio (one sentence to a browser game, a self-playing playtest that reports, art candidates with a
cost card before spending, LAN play by QR, one-file HTML export) and a post about an agent that made hundreds of game
and mockup variants that nobody could review. Their ideas only: nothing of theirs is bundled, and each milestone is
FactorIA's own version over its commands. They start after the M61-M65 block ships.

## M70-M80: a renderer and runtime for every kind of game (planned 2026-11-06)

The user, 2026-11-06: FactorIA is for 2D and 3D, simple and ambitious, retro and cutting-edge games on PC, consoles,
phones and the web, so it gets everything a leading engine has, not only what a 2D game needs. Today: loading reads a
little every frame on the main thread, the game loop is single-threaded, lighting is in gamma space with no HDR, the
only screen effects are bloom and the colour filter, only the directional light casts shadows (one map, no cascades),
IBL is a procedural sky, custom materials exist for `MeshRenderer` only, there is no LOD, occlusion culling, streaming,
temporal antialiasing, upscaler or ray tracing, and the backends are sokol_gfx's (GL, GLES3, WebGL2, D3D11, Metal).

Rules for all of them:
- Off by default and free when off: a simple or retro game pays nothing (no extra pass, target or memory) for a feature
  it does not use, and its look does not change unless it opts in (linear lighting included: a project setting with a
  migration note, old projects keep gamma).
- Every feature degrades with a teaching message where a backend cannot do it (GLES3/WebGL2 without float targets or
  compute, a GPU without ray tracing), says so in `renderer.supports(feature)` and in the docs table per backend, and
  has goldens per backend in CI.
- Each is a component field or a command with doc strings, in the menu kit's graphics page where a player would set it,
  in the Inspector, and in AI_GUIDE.md with when to use it and what it costs (perf budgets, `perf.measure`).
- Simulation stays deterministic: threads never change results (fixed merge order, `world.rng`).
- Our own implementation; outside SDKs only where a vendor requires its own (M78), fetched at setup like sokol-shdc,
  never committed, with their licenses checked first.

Order: M70 and M71 first; M72 and M73 need M71; M74 needs M72; M75 needs M70; M76 needs M71; M77 stands alone;
M78 needs M76 and M77; M79 needs M73 and M77; M80 needs M71 and M72. Since 2026-11-09 M71 needs M95 (its frame graph
and render targets) and M75 needs M94.4 (broadphase and heightfield collider).

## M71. Linear HDR and a post-processing stack (L; 5 packages) — the user, 2026-11-06

- M71.1 (L) Linear HDR pipeline: `SceneSettings.colorSpace` "gamma" (today) or "linear", float render targets
  (RGBA16F, R11G11B10 where supported, RGBA8 + dithering fallback), sRGB textures marked as such, tonemapping (neutral,
  ACES, AgX, Reinhard, none), exposure (manual and automatic with adaptation speed), and HDR display output where the
  platform allows (Windows HDR10/scRGB, macOS EDR) with paper-white nits. 2D lights and sprites use the same pipeline.
- M71.2 (L) The stack: a `PostProcess` component (on a Camera, or a volume: global, box or circle in 2D/3D with blend
  distance and priority) with ordered effects: colour grading (lift/gamma/gain, white balance, curves, `.cube` LUTs),
  vignette, chromatic aberration, film grain, lens distortion, sharpen, bloom moved into it (lens dirt, threshold
  knee), outline (depth/normal edges, 2D sprite outlines), pixelate and posterize. Effects share passes where they can.
- M71.3 (L) Depth-based effects (3D): SSAO (GTAO quality levels), depth of field (bokeh, near/far, autofocus on a
  target), camera motion blur (from depth; per-object with M76), screen-space reflections, height and distance fog
  moved into the stack, sun shafts.
- M71.4 (M) 2D screen effects: shockwave and heat-haze distortion (screen-space, spawned by `feel`/vfx), radial blur,
  screen flash and fade moved into the stack, split-screen cameras each with their own stack.
- M71.5 (M) Tools: a Post-processing panel with live preview and A/B, `postprocess.*` commands, presets (cinematic,
  stylised, clean, retro hooks for M80), goldens per backend, the cost of each effect in the profiler and in docs.

## M72. Custom shaders for everything (L; 5 packages) — the user, 2026-11-06

SHADERS.md "Not available yet" becomes empty.
- M72.1 (L) Materials for `Sprite`, `Shape2D`, `Tilemap`, `Text`, particles and vfx, trails, the sky and UI images: the
  same snippet model as meshes (`fragment()`, `vertex()`), batching kept for sprites that share a material, per-sprite
  values through instance data.
- M72.2 (M) Post-process materials: a custom pass in the M71 stack (reads colour, depth, normals, previous passes),
  ordered with the built-in effects.
- M72.3 (L) Full shaders and custom lighting: own `main` and vertex layout, several passes, a custom light loop (toon
  ramps, cel bands, hatching), textures in `vertex()`, per-instance values in one instanced draw.
- M72.4 (L) Compute shaders where the backend has them (D3D11, Metal, GL 4.3, Vulkan/D3D12 with M77): GPU particles,
  culling, simulation helpers; a clear refusal on GLES3/WebGL2 with the CPU path named.
- M72.5 (L) A node graph material editor that writes the same JSON/snippet an AI writes (graph and code stay one
  document), with live preview on mesh, sprite and quad, and a library of nodes (noise, dissolve, flow, fresnel,
  triplanar, parallax occlusion).

## M73. 3D lighting of a leading engine (L; 6 packages) — the user, 2026-11-06

- M73.1 (L) Clustered forward lighting: hundreds of lights instead of 32, light cookies, IES profiles, area lights.
- M73.2 (L) Shadows: cascaded shadow maps for the directional light (stable, blended cascades), point (cube) and spot
  shadows in an atlas with a budget, soft shadows (PCF/PCSS), contact shadows, per-light resolution and distance.
- M73.3 (L) Environment: HDRI import, prefiltered environment cubemaps for IBL, reflection probes (baked and realtime,
  box projection, blending), sky models (physical sun and atmosphere, clouds) feeding IBL.
- M73.4 (L) Baked lighting: a deterministic lightmap baker (CPU path tracer, multi-threaded on M70, GPU with M79),
  lightmap UVs generated, light probes for moving objects, mixed lights; bake jobs with progress and cancel.
- M73.5 (M) Volumetrics and decals: volumetric fog and light shafts per light, projected decals (deferred-style on
  forward), screen-space subsurface for skin and wax, and a realtime GI option without ray tracing (probe grid, DDGI-style
  updated over frames).
- M73.6 (M) Materials catch up: clear coat, sheen, transmission, anisotropy, glTF extensions for them, and the
  material inspector showing which ones cost a pass.

## M74. Ambitious 2D lighting and effects (M; 4 packages) — the user, 2026-11-06

- M74.1 (M) Soft 2D shadows (penumbra by light size), shadow casters on sprites and shapes (`ShadowCaster2D` from the
  sprite's alpha or a polygon), self-shadowing off/on, more than 32 shadowed lights with an atlas.
- M74.2 (M) Emission and masks: emissive maps on sprites (feeding HDR bloom), light masks per layer, light cookies, a
  normal map generated from height or from the sprite itself, rim light. The normal map is also an image layer the AI
  and the user can edit (paint, smooth, flip a channel) with the M52 tools, previewed under a moving light.
- M74.3 (L) 2D global illumination: radiance-cascades-style GI (light bounces off coloured walls, emissive sprites
  light the scene), quality levels, off by default.
- M74.4 (M) 2D water and refraction: reflective water planes, refraction and distortion zones through M72 materials,
  shown in an example scene.

## M75. Big worlds: LOD, occlusion, streaming, terrain (L; 6 packages) — the user, 2026-11-06

- M75.1 (L) LOD: automatic mesh simplification on import (our own simplifier, deterministic), LOD groups with screen-size
  thresholds and cross-fade, impostors for far objects, HLOD for cells.
- M75.2 (L) Occlusion culling: a CPU software rasteriser of occluders on the M70 jobs (every backend) and GPU Hi-Z where
  compute exists, portals for interiors; `renderStats` counts what each culled.
- M75.3 (L) World streaming: worlds split into cells (3D scenes and 2D tilemap chunks) loaded and unloaded around the
  camera or chosen anchors on the M70 IO thread, with budgets, priorities and a debug view; an editor workflow to edit
  one big world in cells.
- M75.4 (M) Large coordinates: origin shifting (or double-precision positions) so worlds of hundreds of km keep
  precision in physics and rendering. Decide the Transform model first (double positions or origin rebasing), since
  physics, render, nav, audio, networking and saves all read positions.
- M75.5 (L) Terrain: heightmap terrain with GPU LOD, splat material layers, holes, collision, sculpt and paint tools in
  the editor and as commands, generation from noise and erosion.
- M75.6 (M) Foliage and scattering: GPU-instanced grass, trees and rocks with per-instance data, wind, LOD and culling,
  painted or scattered by rules.

## M76. Temporal antialiasing and open upscalers (L; 4 packages) — the user, 2026-11-06

- M76.1 (L) The temporal base: per-pixel motion vectors (static, moving, skinned meshes, particles, sprites), camera
  jitter, a depth buffer every pass can read, TAA with history rejection, per-object motion blur from M71.3.
- M76.2 (M) Spatial upscaling everywhere: FSR 1 (EASU + RCAS) or our own equivalent on every backend, web and phones
  included, replacing the stretch of `window.renderScale`; integer scaling kept for pixel art (orthoSize 0).
- M76.3 (L) Temporal upscalers: FSR 2/3 upscaling (open source) where compute exists, MetalFX spatial and temporal on
  Apple, with quality modes (Native AA, Quality, Balanced, Performance, Ultra Performance).
- M76.4 (M) Scaling to a budget: dynamic resolution that holds a frame-time target, graphics quality presets (Low to
  Ultra, auto-detected from the GPU and a short benchmark) that every M70-M80 feature reads, and the menu kit graphics
  page with all of it.

## M77. Modern backends: D3D12 and Vulkan (L; 6 packages) — the user, 2026-11-06

sokol_gfx stays for GL, GLES3, WebGL2, D3D11 and Metal; D3D12 and Vulkan are our own backends behind the same render
interface (external/ is not edited). They are the base of M78, M79, DirectStorage and the Xbox seam of M23.
- M77.1 (L) The render interface split so a second backend family fits (resources, pipelines, passes, barriers).
- M77.2 (L) D3D12 backend: descriptor heaps, pipeline state cache on disk, upload rings, resource barriers, debug layer
  in tests, WARP for CI.
- M77.3 (L) Vulkan backend: Windows, Linux and Android, validation layers in tests, lavapipe for CI, pipeline cache.
- M77.4 (M) Shaders: the shader tool emits DXIL and SPIR-V (with the M72 snippets), reflection kept for the material
  inspector.
- M77.5 (M) Async compute and multi-threaded command recording on the M70 jobs, bindless where supported.
- M77.6 (M) DirectStorage on Windows (GPU decompression of `game.pak` blocks) behind the M70 storage layer, and a
  backend choice in `project.json` and the launcher with automatic fallback.

## M78. Vendor upscalers, frame generation and latency (M; 4 packages) — the user, 2026-11-06

- M78.1 (S) Licences and setup: NVIDIA DLSS/Streamline, Intel XeSS, AMD FidelityFX terms checked; the SDK binaries are
  fetched by `factoria setup` on demand and shipped with exported games when used, never committed.
- M78.2 (M) DLSS Super Resolution and Ray Reconstruction (D3D12/Vulkan, D3D11 where the SDK allows), XeSS Super
  Resolution (every GPU, D3D11/D3D12/Vulkan), behind the M76 quality modes with automatic choice by GPU.
- M78.3 (M) Frame generation: DLSS Frame Generation, FSR 3 frame generation, XeSS frame generation, with UI drawn
  without artefacts and a refusal under the minimum base frame rate.
- M78.4 (S) Latency: NVIDIA Reflex, AMD Anti-Lag 2, Intel XeLL, a latency readout in the profiler.

## M79. Ray tracing (L; 5 packages) — the user, 2026-11-06

- M79.1 (L) Acceleration structures: BLAS/TLAS for meshes (skinned refit, instances), on DXR (D3D12), Vulkan RT and
  Metal RT, with `renderer.supports("raytracing")`.
- M79.2 (L) Ray-traced shadows (soft, area lights) and ambient occlusion.
- M79.3 (L) Ray-traced reflections and translucency, falling back to M71.3/M73.3 per pixel.
- M79.4 (L) Ray-traced global illumination (probes updated by rays, then per-pixel with denoising; DLSS Ray
  Reconstruction from M78 when present).
- M79.5 (M) A path-traced reference mode for screenshots, store art and checking the raster look, and GPU baking for
  M73.4 lightmaps.

## M80. Retro looks done right (M; 4 packages) — the user, 2026-11-06

- M80.1 (M) Low-resolution rendering: render at a console-like resolution (320x240, 256x224...) with integer or
  aspect-correct scaling and a sharp-bilinear option, for 2D and 3D.
- M80.2 (M) Palettes and dithering: palette quantization (built-in palettes and `.pal`/`.gpl`/image import), ordered and
  error-diffusion dithering, colour limits per sprite, 1-bit and 4-colour handheld presets. Also blue-noise dithering
  (our own generated blue-noise texture, void-and-cluster, no shipped file), at runtime and as a `blueNoise` method of
  the image tools' `dither` (today bayer2/4/8, floydSteinberg, atkinson), with `bayer16`, `clusteredDot`, `sierra`,
  `sierraLite`, `burkes`, `jarvis` and `stucki` beside it.
- M80.3 (M) Screens: CRT (scanlines, shadow mask, curvature, bloom, phosphor persistence), NTSC/PAL composite artefacts,
  LCD grid, VHS.
- M80.4 (M) Retro 3D: vertex snapping, affine texture mapping, no filtering, low colour depth, draw distance fog, per
  material or for the whole game; a retro template for 2D and one for 3D that use these presets.

## M81. Cleaner art from rough sources (M; 4 packages) — the user, 2026-11-07

From the user's X bookmarks (pixel-art grid detectors, video-to-sprite tools, parametric model kits). Ideas only: each
is FactorIA's own command, nothing of those projects is bundled, depended on or wrapped as a provider. Checked against
the roadmap and docs first: none of these is done or planned.
- M81.1 (M) Automatic pixel grid: `image.to_pixel_art {pixelSize: "auto"}` finds the art-pixel size and offset of an
  upscaled or AI-made "fake pixel art" image (edge spacing and colour runs per axis), reports the grid it found with
  its confidence, and snaps to it; `image.detect_pixel_grid` returns the grid alone. Today `pixelSize` is given by hand.
- M81.2 (M) Video to sprite sheet: `image.sheet_from_video {path, fps?, from?, to?, crop?, background?}` takes the
  frames of an imported video (the same decoders as video import), drops near-duplicates, keys out a plain background
  and bakes a sheet with its animation clip, so a filmed or generated clip becomes a game animation.
- M81.3 (S) Remove a fringe or a background: `image.clean_edges` removes the halo `assets.check_art` reports (dark or
  light fringe around the alpha edge, matte decontamination) and `image.remove_background` keys out a flat or
  near-flat background colour; both as M52 layer operations, and as a fix `assets.check_art` offers.
- M81.4 (M) Parametric kits and variants: a model document declares shared top-level knobs (size, roof pitch, wear,
  palette...) that drive its nodes' params, and `model.variants {path, count, vary?, seed}` makes a set of seeded
  variants; with M69 contact sheets to review them and a pick that saves the chosen ones as assets.

## M82. Secondary motion and more generated animation (L; 3 packages) — the user, 2026-11-08

From the user's X bookmarks (TailorRig and HairDeck for clothing and hair bones, UniMate and Prompt2Rig for motion from
a description, DirtyMoCap and a mocap clean-up app). Those are trained models; ours are procedural and live in the
engine, nothing of theirs is bundled, depended on or wrapped. Checked against the roadmap and docs first: rigs today
have only the body (plus `tail`/`chain` templates for whole models), `anim3d.generate` makes 7 kinds, and nothing
cleans an imported clip.
- M82.1 (L) Secondary chains and spring bones: `rig.add_chain {rig, part, from, segments}` adds bone chains for hair,
  capes, skirts, sleeves and ears to a fitted rig, with skin weights kept on their part (they do not leak into the legs
  or the body); a `SpringBones` component (3D, and the same for `Bone2D` chains) moves them at runtime with stiffness,
  damping, gravity and collider spheres, deterministic on the fixed step; the Animation panel shows them, and
  `anim3d.preview` can draw them settling.
- M82.2 (M) More generated actions: `anim3d.generate` kinds `jump`, `attack`, `wave`, `crouch`, `death`, `climb`,
  `sit`, `fall`, `turn` and `push`, from the rig's proportions with IK for contacts and the same `params` and
  `generated` record as today; for the humanoid, quadruped and bird templates where each makes sense (a teaching error
  otherwise). `attack` has `lunge` (a quadruped's bite: the body reaches, the head snaps down) and `chop` variants, and
  `anim3d.pose {path, rig, pose, at}` keys a named pose (`head_down`, `arm_up`...) to key between (KW/FB-0018).
- M82.3 (M) Clean an imported clip: `anim3d.clean {path, rig, out?}` filters jitter, finds the foot contacts and locks
  them (no foot skating), keeps the root over the feet, reduces keys within an error budget and reports what it changed
  with a before/after filmstrip; `anim.check` gains a `foot_skate` finding that suggests it.

## M83-M89: ideas from the user's X bookmarks of 2026-11-06..09 (planned 2026-11-09)

References: the dsh-* plugins (qa, game-studio, crew, harbor), small engines and tools for agents (67.js, Vork, raea,
Tesseract, OpenMontage, glb-viewer), art tools (parametric top-down buildings, reference-to-game, video-to-game,
image-to-sculpt, Sand3D, Aseprite AI Artist, Image-to-Pixel, kiki-pixel-gif), agent workflow tools (claude-mem,
impeccable, graphify, doop) and a playable-ads post. Ideas only: each package is FactorIA's own engine, editor or AI
feature over its own commands. Nothing of theirs is bundled, depended on or wrapped, no outside asset is shipped, and
no package connects to an outside repository, service or installed program. Checked against the roadmap, the done
list and the docs first; what already exists was left out (`checkpoint.*` and per-run Revert, `game.click`/`game.tap`
by id and `ui.state`, `api.components`, UASTC/ETC1S, the selected entity named to the AI, the token and loopback of
`project.serve_web`, `savers.projectFacts`, `ui.check_layout`, the M66-M69 pieces), and what is already planned was
added to its package (more dither methods in M80.2).

Order: free, each stands alone; M84.4 and M86 use M67 sessions; M85.1 is better after M81.1; M89.3 needs M96 (the
smaller player).

## M83. Regression tests from play sessions (M; 2 packages) — the user, 2026-11-09

Today `input.record` and `factoria run --input` replay inputs and JS tests can `game.click`, `game.tap` and `expect`,
but a `play.auto` or recorded session cannot become a test, and a test asserts on whatever frame it lands on.
- M83.1 (M) `play.to_test {session, out?}` (and the same from an `input.record` file): writes a JS test for
  `project.test` that replays the session's actions by id where it can (`game.click("start")`, not coordinates) and,
  after each step, asserts what the session saw (scene, UI state, chosen `game.state` keys, no new errors). Rules: a
  step whose result is unknown never passes (only a fresh observation decides), and a truncated view is reported as
  incomplete, never as "not there". A failing step is a teaching error with the step, the expected and seen values
  and the frame captured.
- M83.2 (S) Waiting and scope in tests: `game.settle {quietMs?, timeoutMs, keys?}` waits until the chosen state, the UI
  and tweens are still, with a bounded time and a teaching error naming what kept moving; `ui.state {within: id}`
  reads one branch of the UI. Docs (MENUS.md, AI_GUIDE.md) and tests.

## M84. The art critic compares against a reference (M; 4 packages) — the user, 2026-11-09

Today `style.references` and the measurable style guide (M51.1) exist and the artCritic looks at screenshots, but
nothing compares the game, a model or a video with a chosen reference.
- M84.1 (M) Reference packs: `style.references` entries gain an `authority` (look, palette, UI, motion, camera) so
  each reference rules one dimension, and imported videos are references too: sampled frames on a contact sheet (M69),
  their palette and cut rhythm, summarised as a brief the artist role reads before generating.
- M84.2 (M) `review.compare {reference, at?}`: the game captured at matching points next to the reference, side by
  side, with the largest differences listed per dimension (palette distance, value range, silhouette density, UI
  scale); the artCritic fixes the biggest one, and a fix is kept only when it wins a blind A/B (the critic sees A and
  B unlabelled); the result records both pictures.
- M84.3 (M) `model.compare_reference {path, image, view?}`: the model rendered from the reference's view, measured by
  silhouette overlap, contour distance and normal direction per region, reported as several numbers and a difference
  picture, never one score; the model panel shows it.
- M84.4 (S) Close-ups: `play.auto {closeUps: true}` adds crops of each character and enemy on screen to the report for
  the artCritic, and `play.best_window {session}` picks the most eventful seconds of a session as a frame grid.

## M85. 3D to 2D and pixel-art tools (M; 5 packages) — the user, 2026-11-09

Today `assets.bake_sheet` captures 2D entities only and `model.preview` renders a model to look at it, so a model
cannot become 2D game art; GIF is not read or written.
- M85.1 (M) `assets.bake_directions {model|prefab, directions: 1|2|4|8|16, angle, projection, clips?, size, pixelSize?,
  palette?}`: renders a 3D model or prefab (with its animation clips) from N directions into a sprite sheet with its
  clips per direction, ortho or perspective, lit by the style's light, snapped to a pixel grid and quantized to the
  palette when asked; with M81.4 variants it makes a whole parametric building or character kit for a 2D,
  top-down or isometric game.
- M85.2 (M) Top-down and isometric prefabs from a model: the baked sprite plus a collider from the model's footprint
  and a sorting/occlusion shape from its silhouette, so a building is placeable without hand-made colliders.
- M85.3 (S) GIF: `assets.export_gif {sheet|clip}` with our own encoder (palette per frame or global, loop, baseline
  alignment, the loop check of `assets.inspect_sheet`), and import of GIF frames as a sheet.
- M85.4 (S) Set checks and sheets: `assets.check_set {paths}` reports assets of one kit that break its shared palette,
  texel density or scale; sheet packing drops duplicate tiles; a baked PNG carries its recipe in a text chunk, so
  `assets.inspect` can rebuild it from the picture alone.
- M85.5 (S) A pixel-art rules skill written by us (readability at size, outlines, clusters, ramps, banding, pillow
  shading, animation timing) that the artist and the artCritic roles read, with a checklist the critic grades.

## M86. Trailers: a timeline and recording checks (L; 3 packages) — the user, 2026-11-09

The open part of TM/FB-0055 gets its package; today a trailer is a script and nothing checks a recording.
- M86.1 (L) A `Timeline` component and `*.timeline.json` documents: tracks of camera keys, entity animation, text
  cards, fades, sounds and music, events for scripts, scrubbed and edited in the editor next to the Animation panel,
  played in game and with `--record-video`; commands to build one from code.
- M86.2 (M) `video.check {path}` and `play.check {session}`: a recording or trailer checked for cut-off or unreadable
  text, low contrast, content outside the store safe zones, frozen or black stretches and loudness, each finding with
  its time and frame picture and how to fix it.
- M86.3 (S) Timing: cuts snapped to the music's beats and bars (the M51.4 analysis), and captions timed per word.

## M87. The editor AI: memory and working together (M; 4 packages) — the user, 2026-11-09

Today `savers.projectFacts` saves facts learned from failures, and several chats can edit one project with Revert
handling the overlaps afterwards.
- M87.1 (M) Project memory: facts, decisions and preferences the AI keeps per project, a periodic consolidation pass
  that merges duplicates, drops stale facts and links related ones, a `<private>` mark that is never stored, and a
  Memory panel where the user reads, edits and deletes them.
- M87.2 (M) `ui.lint {scene?}`: finds the generic AI look in game menus (default fonts and sizes, centred stacks of
  same-size buttons, missing hierarchy, low contrast, uneven spacing) against the project's own `DESIGN.md` for UI,
  with concrete fixes.
- M87.3 (M) `project.graph {path?}`: who uses an asset, prefab, script or scene and what it uses, unused assets, and
  what a rename or deletion would break.
- M87.4 (M) Concurrent edits: `expectedRevision` on entity and asset edits (a stale edit is a teaching error with the
  current value), a lock per folder for chats that write there, and automatic escalation to a stronger model of the
  same provider when a role fails twice, with a depth limit for nested agents.

## M88. Asset optimisation and cost views (M; 3 packages) — the user, 2026-11-09

Today the export reports sizes per folder and M64.4 checks overdraw for effects only.
- M88.1 (M) `assets.optimize_report`: size on disk and in memory per texture and mesh, against project budgets per
  platform, with the fix for each (resize, compress, simplify, share) and its saving.
- M88.2 (M) Viewport views: overdraw and cost heat maps, normals and UV density, and a before/after compare of an
  optimised asset with linked cameras.
- M88.3 (S) An analytic lighting test (a white furnace: a white sphere under uniform light must come out uniform) for
  every lighting change of M71-M73.

## M89. Engine upgrades, prototypes and playable ads (L; 3 packages) — the user, 2026-11-09

- M89.1 (M) `project.upgrade_check {to?}`: what in this project (components, fields, commands, script API) changes
  between its engine version and the installed one, from `tools/common/api_since.json` and the docs, with the edits
  to make, including the files of the menu kit a project copied (MENUS.md) that changed since it copied them.
- M89.2 (S) A "My games" wall in the editor's start window: a tile per project with its last screenshot, opened or
  played with one click.
- M89.3 (L) Playable ads export: `project.export {platform: "playable"}` writes one small HTML page (a slimmed web
  player, a size report against the networks' limits), with an MRAID-ready wrapper, an end card, an install button,
  a hint hand, a size and API check per network, and `play.auto` bots that tune the first level's difficulty.

## M90-M99: foundations and fixes from an outside review (planned 2026-11-09)

An outside reviewer read the whole repository at 0.19.0 (`b6179fab`), knowing only the roadmap, and wrote two reports:
one on the engine and one on its documentation (not in the repository). Every claim was checked in the code by three
read-only passes (runtime and core; tools, MCP and security; docs), and most hold. Where the reviewer was wrong or
went too far:
- Headless runs have a renderer: `factoria run --headless`, `test`, `call` and `mcp` create one on EGL by default, so
  animators, particle lifetimes and `ui.measureText` are exact there. Only `--no-graphics`, or a machine without EGL
  (`graphics=false`, one startup warning), loses `SpriteAnimator`, `ParticleEmitter.autoDestroy` and exact text
  measuring: that is the real bug (M91.1).
- Input edges are cleared at the end of a frame, not at its start; the effect is the same (a press seen by no fixed step
  or by several, M91.2).
- The physics replay hash already runs on Apple Silicon (`macos-latest`) besides Linux and Windows, and an empty
  `kPlatformHashes` means they all match. What is missing: Android, iOS and the web, and more than one test (M91.3).
- The exported player links `fa_runtime` only, so it has no `fs.write` of the tools, no `project.*` and no
  `publish.*`. It does carry the authoring commands that live in `fa_runtime` (wfc, level, terrain, mesh, anim, vfx;
  M96.1).
- `sg_image` appears only in a comment of the public `renderer.h`; `docs.read` takes `heading`; CHANGELOG.md and
  feedback/done/ are not embedded in the binary; the README's "versioned save slots" are Burrow Brigade's, as it says;
  the Windows `frame % 120` poll rescans empty pad slots only; `save_config` is an unused function that writes with
  default permissions before its chmod, not a chmod after `write_private` (removed in M90.4).
- The MCP server lists 405 commands now (docs/MCP.md says about 190), but Claude Code defers MCP tools and the API
  providers get M45's catalog: only other MCP clients load all of them (M97.2).

Not taken:
- Cutting M72.5, M73.4-5, M77, M78 and M79: the user decided on 2026-11-06 that FactorIA covers every kind of game.
  They stay, after the foundations below.
- One version per release instead of per milestone, CODEOWNERS and a human approval for the core, a feature freeze:
  the process stays (a minor per milestone). Doing this block first is the pause the review asks for.
- Moving the ~170 art commands into a "studio" plugin: the art tools are the user's M51-M60 and stay in the editor, the
  CLI and MCP. M96 takes them out of the player, which is what the review wanted (size and surface).
- Jolt for 3D physics: our own implementation (the rule of M70-M80); M94.4 builds the broadphase and the manifolds.
- Git LFS: the pack is 115 MiB with about 42 MB of PNG and WAV, and LFS bandwidth quotas would go on CI checkouts.
- Storing the examples' generated music as OGG instead of WAV (about 16 MB to 4): only a clone and CI fetch the
  examples, never a user's download, so the gain is small; old blobs stay in the history anyway.
- Merging the menu kit copies of six examples: a game owns its copy of the kit by design (MENUS.md). What is missing
  is updating a copy when the kit changes, added to M89.1.
- One A*: nav_grid (meshes) and nav_tiles (tilemaps) search different data; only the early "unreachable" is taken
  (M94.5).

Rules: those of every milestone (tests, docs, teaching errors), plus: each fix comes with the test that would have
caught it, and each performance package shows its gain on M93.5's benchmarks.

Order: M90 first (small). Then M91, M92 and M93, before any new feature. M94 and M95 before M71: M71 builds on M95's
frame graph and render targets, M75 on M94's broadphase and heightfield. M96 before M89.3 (a playable ad needs the
small player). M97 at any time, alongside the others. M98's packages after M91, earlier where a game asks for one. M99
when the user has the hardware and the accounts. Since 2026-11-10 M100 and M101 come first and M97.1 and M97.2 next
("M100-M101").

## M100-M101: the examples' feedback and a third outside review (planned 2026-11-10)

A third outside reviewer used the installed 0.21.0 the way a game-making AI does (`factoria new`, `validate`, `test`,
`run --headless`, `mcp`, `docs`, a project with planted mistakes) and read `engine/core`, `scene`, `script`,
`tools/common`, `tools/cli` and the CI workflows (feedback/AUDITORIA_2026-11-10.md, in Spanish). Its main finding is
a process failure: `feedback collect examples/*` gave 36 open entries from 11 projects while this file counted 3 from
9; the regeneration command named nine examples by hand, so Kindlewatch (M60, 21 entries) and Ember Descent were never
collected, and 33 entries written 2026-10-29..11-08 had no triage and no package.

Triage 2026-11-10 of those 33 entries against `bcca8383` (0.21.0), by three read-only passes (audio and music; tooling,
assets and animation; scripting and scene), several reproduced in a scratch project with `factoria test`, `call` and
`validate`:
- Already fixed, closed with a `Fixed in` note: KW/FB-0002 (the schema takes provenance kind `prefab` and `extras`
  since `479c7bd2`, M60; `model.game_ready` then `validate` gives 0 errors) and SH/FB-0026 (`validate` checks clip
  track paths since `c96ddbbd`, M42.3).
- Possible already, docs only: KW/FB-0019 (`tween(world.settings, {skyColor, ambientLight, fogDensity...})` moves the
  scene's colours; no example says so).
- Hold in part: GR/FB-0016 (the export warns since `230bc811`, `validate` does not, the warning has no line, and
  gem-roller's `scripts/game.js:16` still calls `project.scatter_gems`), ED/FB-0002 (AI_GUIDE §9.8 says it; the
  refused-level error does not), KW/FB-0005 (`status.song` is already the audible song; nothing pending is exposed),
  KW/FB-0009 (`texelsPerUnit` already follows how a texture is used), KW/FB-0010 (the summaries say it; `sfx.bake`
  takes no `path`), KW/FB-0011 (`master.normalize` exists and is per variant; the "up to date" answer did not
  reproduce, but it does not say what it compared), KW/FB-0015 (`game.touch` on a widget exists since `3b41cbc7`;
  nothing forces touch UI in a screenshot), KW/FB-0018 (M82.2 adds `attack`, not a bite or `anim3d.pose`), KW/FB-0020
  (`no_baseline` passes; no provisional entry), NS/FB-0021 (MUSIC.md's table says it since `69a4fe61`; the names do
  not), SH/FB-0024 (the generator writes prefab references now; `validate` does not warn about an inline copy).
- Duplicates across games: GR/FB-0013 = KW/FB-0017 (no provenance for anim3d clips), GR/FB-0014 = KW/FB-0021 (rigged
  parts never merged). Both stay open and are fixed by one package.
- Everything else holds as written, KW/FB-0001 and KW/FB-0004 (major) included. M91.4 streams long clips, not the
  `MusicPlayer`: `Audio::stats()` does not count `musicCache`, so `audioDecodedMB` says 3 MB in a 576 MB process.

Every claim of the review was checked; most hold. Where it was wrong or went too far:
- `"color": [255, 255, 255, 255]` is not a mistake: `json_to<Color>` reads 0..255 when any channel is over 1. The trap
  is a mixed array, `[255, 255, 255, 1]` (alpha 1/255, invisible) or `[1, 1, 1, 255]`, and the shape message that only
  says "(0..1)" (M100.4).
- `validate` does not print a scene or script error twice; a `Script.props` warning goes to the report and to stderr,
  and with `--json` log lines still reach stderr. What it missed: a module whose top level throws passes `validate`
  with exit 0 (M100.4, M100.5).
- `entity.positon` returns `undefined` rather than throwing; `entity.get("transform")` (wrong case) works silently and
  `get("NoSuch")` points at `factoria api components` with no list (M100.3).

Not taken:
- Starting each of M71-M89 only when a reference game asks for it in its ENGINE_FEEDBACK.json: the user decided on
  2026-11-06 that FactorIA covers every kind of game. They stay planned; only their place in the order moves (below).
- "No milestone of our own while an entry is untriaged": the guard is a test instead (M100.6) and a triage before each
  milestone starts, so the user's own milestones are never blocked by a backlog.
- A fast mandatory CI job and a full one per milestone: every push here is a milestone PR, so both would run on the
  same pushes. M93.1's sanitizer jobs run beside the others.
- Lowering `.mcp.json`'s 4-hour timeout: `ai_run` and long bakes take many minutes in one call (docs/MCP.md), and
  commands have their own deadlines.
- Removing the Spanish translations: they say they are behind, as the rules ask; M97.4 makes them record the English
  commit they follow.
- Checking every member access in scripts against `types/factoria.d.ts` with a type checker: M100.4 checks the
  imported names, the members of imported namespaces and literal component names, which needs no type inference.

Rules: those of every milestone, plus: each fix comes with the test that would have caught it, every example's tests
still pass under M100.2's stricter rule, and each feedback entry a package closes gets its `Fixed in` note and the game
drops its workaround in the same package.

Order: M100 then M101, before M92 (M100 is what the game AI meets on its first run; M101 is the backlog). M100.1
(the measure) runs first so there is a "before". Then M97.1 and M97.2 (the cost of the first step), then M92, M93
(its ASan+UBSan job first), M94, M95, M96 and M98. M71-M89 follow, in their own order; M87 (the editor AI) after
M97.2. A triage of every open entry of `examples/*` opens each milestone.

## M100. Errors and tests a game AI can trust (L; 10 packages) — outside review, 2026-11-10

- M100.1 (M) What a game costs an AI with no context: a script (`scripts/agent-cost.sh`) that starts a configured AI CLI
  (Claude Code, Codex, and one small model) in an empty folder outside the repository with only the installed
  `factoria` on the PATH and a fixed brief ("a platformer with three levels"), records the transcript, and reports
  through `tools/common/src/efficiency.cpp` the tokens and steps to the first playable build (`play.auto` reaches the
  last level), the engine errors met and the ones not caught (a script error seen in the log while every test passed).
  Results go to `feedback/agent-cost/<version>-<cli>.json`; run by hand (it spends quota), before M100 and after M101,
  then once per version. docs/AI_COSTS.md says how to run it and shows the latest numbers.
- M100.2 (M) A test fails when the game fails: a test during which a game script threw (callbacks, events, module
  top level) or the engine logged an `ERROR` fails, with the first error as its message (in factoria.js `testRun`,
  next to the watchdog check, over the log records between the test's `seq0` and `seq1`); a test that expects one says
  so with `game.expectErrors(/pattern/)` (or `{ expectErrors: [...] }` in the test's options), and an expected error
  that never comes fails too. The summary counts them, the exit code follows. Tests: a throwing `onUpdate`, a missing
  `audio.play` file, a `console.error` (not an error), an expected error. Every example's and template's tests pass
  under the rule; what it finds is fixed, not silenced.
- M100.3 (M) Script errors that teach: `explain_missing_api` names the object's real members and the closest one
  (`'input' has no 'axs'. Did you mean 'axis'?`, with `closest` of factoria.js), and says "this player may be older
  than the game's engine" only in an exported player (in `test`, `run`, `mcp` and the editor the engine and the player
  are one binary); `hint_for` checks "not a function" before that text. In development runs (`test`, `run`, `mcp`,
  the editor's Play) `Entity` (made in one place, `entityOf`), the namespaces (`input`, `world`, `audio`, `ui`, the
  rest of the `factoria` exports) and the `expect` matchers get the strict read Proxy the plugins and `gameApi` have
  (did you mean and the member list; symbols, `then`, `toJSON` and prototype keys pass; writes are untouched); the
  exported player has no Proxy. `entity.get/add/has/remove` with a name that matches only ignoring case warns once with
  the exact name; an unknown name lists the closest names and the count. Every example's scripts and tests pass
  (fix any expando read the Proxy finds).
- M100.4 (M) `validate` checks scripts, not only their syntax: names imported from `"factoria"` and `"factoria:test"`
  exist (did you mean); `ns.member` on an imported namespace exists (from api.json, file:line:column); a literal
  component name passed to `get`/`add`/`has`/`remove` exists; a literal `fa.call("project.*")` in a game script warns
  with file and line, reusing the export's `literal_project_calls` (GR/FB-0016); a module whose top level throws is an
  error. A colour array that mixes channels over 1 with an alpha or channel at most 1 warns (pointer, both readings),
  and `json_to<Color>`'s shape message says that 0..255 is read when a channel is over 1. Tests with planted mistakes
  of each kind; AI_GUIDE's list of common mistakes points at them.
- M100.5 (S) Output once: `validate` captures the log while it opens the session and folds load errors and warnings
  into its report (each once); with `--json` stdout is the JSON and stderr has nothing but a fatal error. `factoria
  test` prints an identical trace once and then "the same error in N more tests (names)"; the fixed sentence "(an
  exception was thrown inside the test; check the game scripts too...)" goes once per run. A test measures the output
  of a run with 10 failures of the same error.
- M100.6 (S) The feedback loop cannot fall behind silently: the regeneration command in feedback/README.md and in this
  file's status is `factoria feedback collect examples/* --out ...`; a ctest runs `feedback collect` over `examples/*`
  and fails when its count line differs from this file's, or when an open entry of an example is named nowhere in this
  file (no package, no triage line). CLAUDE.md's finishing steps run it.
- M100.7 (S) Facts that stay true: a test compares README.md's "Version x.y" with CMakeLists.txt's `VERSION`;
  generated projects get `CLAUDE.md` as one line, `@AGENTS.md` (old projects keep theirs until `project.update`);
  `factoria docs read <name>` takes `--heading`, `--start-line` and `--max-bytes` like `docs.read`, and prints the
  paging hint when it cuts; the MCP server's `instructions` and templates/common/AGENTS.md read the guide by section,
  never whole (the short AGENTS.md itself is M97.1).
- M100.8 (S) An MCP description budget: a test fails when a command's description passes 1.5 KB (what does not fit goes
  to its doc section, which the description names); `tilemap_generate` (18.7 KB) and the other big ones are cut down.
  Profiles and tool search are M97.2.
- M100.9 (M) Performance gates without noise (KW/FB-0020, and the five red `main` runs since 2026-10-31: peak-memory
  gates a few MB over, two Windows editor autotest runs and one iOS simulator run): `perf.check` enforces the
  deterministic counters (draw calls, entities, allocations per frame, bytes retained) exactly, and time and memory
  only past a wide band (warn inside it), so a baseline is never refreshed to pass; a `provisional: true` entry
  enforces only the counters; a `workflow_dispatch` job runs `perf.baseline` on each runner and uploads the entries as
  an artifact. The Windows editor autotest sections and the iOS simulator step that failed are found from those runs'
  logs and fixed or given an honest wait. So is `mcp_http_test.cpp`'s cancel case for a client without event streams
  (PR 208, Windows MSVC tests 2/3, 2026-11-10: no `HTTP/1.1 204` after `notifications/cancelled`, the test took 127 s).
  Frame time is gated on the median and the p95, never on the average or the maximum, which one slow frame decides:
  PR 208's second run failed `example_kindlewatch_perf` on linux-gcc-llvmpipe with `cpuMsAvg` 274.3 > 240 while its
  p95 was 263.1 and one frame took 4579 ms. `perf.measure` reports `cpuMsMedian` too (and keeps the average and the
  maximum in the report, not in the gate); `perf.check` names the slowest frames, so a spike is seen, not hidden.
  `editor_autotest_5` timed out in the same run and joins the autotest sections above.
  The p95 needs the wide band too, and so do the re-measures: PR 210's first run (2026-11-11, a branch with no engine
  change) failed three example budgets on macos-clang-metal-paravirtual within 40 s, each with the best of its three
  measurements. `example_kindlewatch_perf` (`cpuMsAvg` 9.255 > 8, p95 3.607, one frame of 1924 ms) and
  `example_tidewater-market_perf` (`cpuMsAvg` 13.686 > 13.602, p95 35.2 against a limit of 54.4, one frame of 293 ms)
  are the average again. `example_gem-roller_perf` failed on the p95 itself: 1.745 > 1.464 with a baseline of 0.464,
  3.8 times it. Under a millisecond the 1 ms slack is most of the limit, and the two re-measures follow the first at
  once, inside the seconds the shared runner is slow.
- M100.10 (S) DONE, bookkeeping of the review: KW/FB-0019 has its dawn example in ANIMATION.md (a `tween` of
  `world.settings`) and a script test; ED/FB-0002's docs part was already in AI_GUIDE 9.8, so only the refused-level
  error is left (M101.10); this file keeps only what is open and the decisions: the DONE milestone sections moved to
  `feedback/done/M<n>.md` (index in `feedback/done/README.md`, replacing ROADMAP_DONE.md), and CHANGELOG.md keeps
  `## Unreleased` and the last published version, with one `changelog/0.<n>.md` per older minor version.
- M100.11 (open, needs the user's OK for a paid run) A reliable agent-cost criterion: the 0.21.0 measure
  (feedback/agent-cost/0.21.0-claude.json) did not show that the game can be played to level 3. The template bot stops
  at x >= 2464, before the goal at x = 2480, and the AI never ran `play.auto`. A trustworthy criterion needs a new
  BRIEF_ID that asks for one `game.phase` per level, and a new paid run.

## M101. Found by the example games, 2026-10-29..11-08 (L; 10 packages; 31 open entries)

- M101.1 (L) Music memory (KW/FB-0001, major): `Audio::stats()` counts the `MusicSource` buffers (`musicBytes` beside
  `decodedBytes`, per song in `audio.music_state` and `perf.profile`), so `perf.measure` explains a 576 MB process;
  then stems stream from the ogg through the job system and ring buffers like M91.4's long clips, keeping one decoded
  window per playing stem instead of the whole song per layer and section. Test: a 4-layer player of N seconds reports
  its bytes, and with streaming its peak stays under a fixed budget; MUSIC.md gives MB per minute per mode.
- M101.2 (M) Music pending state (KW/FB-0004 major, KW/FB-0005, NS/FB-0022, KW/FB-0003, NS/FB-0021): an orphaned
  transport adopted by the next scene's player drops its pending crossfades and section changes (or adopts the target
  song if the crossfade already started); `status` and `audio.music_state` give `pendingSong`, `pendingSection` and
  `pendingAt`; `goToSection`, `setIntensity` and `crossfadeTo` return `{frame, time, quantize}` of the change;
  `crossfadeTo` without `section` starts the target song at its beginning, never at the component's `startSection`;
  `appliedIntensity` and `requestedIntensity` beside `intensity`. Tests for each, the reload-before-the-bar case
  included.
- M101.3 (S) `audio.play` at a place (KW/FB-0006): `{position:[x,y,z], range, rolloff}` uses the spatial
  `AudioSource` maths with the current `AudioListener` (the camera without one); M98.8's distance models, doppler and
  occlusion build on it. Kindlewatch drops its `playAt` helper.
- M101.4 (M) Sound checks (KW/FB-0011, NS/FB-0020, KW/FB-0010): `master.normalize.shared` computes one gain on the
  loudest variant for every variant; `assets.regenerate` says which inputs it compared when it answers "up to date";
  the mix check skips sounds that are only the input of an audio document's recipe (listed in `skipped`) and judges
  `loop_seam_slope` across the crossfade a `loop` step made; `sfx.bake` takes `path` (one or a list).
- M101.5 (M) Tests and replays (KW/FB-0012, KW/FB-0013, KW/FB-0014, KW/FB-0015): `input.record` records an action
  pressed through `game.input` (an `action` event, played back with `set_action_override`; test: the same world hash);
  the read-only `assets.provenance` and `assets.disclosure` are registered in the test runtime and SCRIPTING.md lists
  the commands `fa.call` has in a test, kept true by a test; `game.findByTag` and `game.findAll`; `factoria run
  --touch` and `screenshot {forceTouch}` show touch UI.
- M101.6 (M) Provenance everywhere (KW/FB-0017 = GR/FB-0013, LK/FB-0048, the suggestion of KW/FB-0002): the anim3d
  commands that write a clip write a recipe (inputs: the rig and the source clip), `assets.set_provenance` and the
  schema take kind `anim3d`, and `assets.regenerate {stale:true}` remakes a clip after a re-fit; `image.create` takes
  `output`; a test runs every recipe command once and validates what it wrote against schemas/assets.schema.json.
- M101.7 (M) Image documents and style rules (KW/FB-0007, KW/FB-0009): `image.resize {path, width, height, anchor,
  fill}` moves or crops every layer, frame and cel, keeping palette, ramps, tags and the sheet, with `undo`;
  `style.ignore` takes `{path, rules:[...]}` and a `role` (ui, icon, effect) in provenance or by glob turns off the
  rules that do not apply to it.
- M101.8 (M) Models and rigs for mobile (KW/FB-0016, KW/FB-0021 = GR/FB-0014): `model.game_ready`'s collider takes
  `part` and explicit `radius`/`height` (a pine's trunk, not its canopy); `rig.bake {mergeParts}` welds skinned
  parts that share a material after the fit (same pose hash, fewer draw calls in `renderStats`).
- M101.9 (L) `scene.save` keeps prefab instances (KW/FB-0008): an entity remembers the prefab it came from, and saving
  writes `{prefab, components: only the differences}`; loading and saving an unedited scene gives the same bytes;
  `validate` warns about an entity that repeats its prefab's components inline (SH/FB-0024).
- M101.10 (M) Small ones: the refused-level error names the sample's shape when cut-off areas refused more than half of
  the attempts (ED/FB-0002, whose docs part is in AI_GUIDE 9.8 already; counted per cause in `GenStats`); `SpriteAnimator.loopMode` (inherit, loop, once; `loop`
  stays as an alias, NS/FB-0019); `IK2D.ground` puts the target on the first collider below it within a reach, run by
  a pass that sees physics before the solver (SH/FB-0025); gem-roller bakes its gems into the scene or moves the
  scatter code into a module the tool and the script both import (GR/FB-0016).
- Elsewhere: KW/FB-0018's bite and chop go into M82.2 with `anim3d.pose`; TM/FB-0003, TM/FB-0051 and TM/FB-0055 stay
  where they were (TM/FB-0055 is M86).
- CC/FB-0057 (minor, found by M100.4: no way to write an emissive colour above white, so the clockwork-courier market
  scenes were clamped to channels of at most 1): held for M101.10 or a package of its own; `MeshRenderer` needs an
  emissive strength (HDR) that feeds bloom, and `validate` should say that a colour array with a channel over 1 is read
  as 0..255.

## M92. Safety: capabilities, files and secrets (L; 4 packages) — outside review, 2026-11-09

- M92.1 (L) Capabilities: each command declares what it can do (read, write the project, write anywhere, network, start
  a process, spend money, publish), each caller has a set (a game script in the player, in the editor's Play and in a
  test; each AI role; an MCP client, read-only or not; the CLI user), and `fa.call` from a game script gets the
  runtime set. A denied call is a teaching error that names the capability and where to grant it (a test can ask for
  more in its file). The commands reference and `api.json` show each command's capabilities.
- M92.2 (M) Paths confined in one place: every command that writes takes its paths through one `fa::fs` function (the
  project, the game's save folder, the user's export folder; an absolute path only for a caller that may write
  anywhere); `game.screenshot`, `input.record` and the rest move to it. A test walks the registry and tries `..` and
  absolute paths on every path argument.
- M92.3 (M) Secrets off command lines and inherited environments: signing passwords never in argv (each tool's file,
  environment, keychain-profile or API-key form; signtool through a certificate imported for the run); hooks and agent
  CLIs get an allow-listed environment; private files on Windows get an owner-only ACL; the permission mode of each AI
  CLI (`acceptEdits` for Claude Code today) is shown and editable in AI Settings with what it allows; the feedback
  server limits per install and per IP and holds without `cf-connecting-ip`.
- M92.4 (M) Contract tests for the AI CLIs: recorded outputs of each CLI (`stream-json` and the others) replayed by
  tests, so a CLI update that changes its format fails here, not in a user's run.

## M93. Oracles: sanitizers, fuzzing, strict builds, benchmarks (L; 5 packages) — outside review, 2026-11-09

- M93.1 (M) ASan with UBSan, and TSan, as Linux Clang CI jobs over the Debug suite (TSan over the job system, loading,
  audio and MCP server tests); what they find is fixed in the same milestone.
- M93.2 (M) Fuzzing: targets for the JSON, scene and prefab loaders, schema validation, the PNG, KTX2, glTF, font and
  audio decoders, the pak reader and MCP's JSON-RPC; a short run on every PR, a long weekly one, a corpus in the
  repository.
- M93.3 (M) Strict builds: warnings as errors in CI for GCC, Clang and MSVC (engine and tools, not `external/`);
  `.clang-format` and `.editorconfig` with one formatting commit and a check; clang-tidy with a few bug-finding checks
  over the changed files.
- M93.4 (S) Coverage per module (llvm-cov) as a CI artifact, the editor autotest included; `autotest_tools.cpp` (9755
  lines) split by section.
- M93.5 (M) Benchmarks: `fa_bench` (ECS queries, hierarchy, 2D and 3D physics, render gather, command dispatch, the
  script bridge, the audio mix) in a Release job, compared with a stored baseline; a big regression fails.

## M94. Fast core data and 3D physics at scale (L; 5 packages) — outside review, 2026-11-09

- M94.1 (L) ECS queries without copies: `each` walks the smallest pool in place, `count<T>()` and `any<T>()` replace
  `entities_with(...).empty()` (the UI code), and the hierarchy caches world matrices, active-in-hierarchy and
  pending-destroy with dirty flags.
- M94.2 (L) Typed component data: `FieldKind::ArrayI32`, `ArrayF32` and `ArrayU8` (the same JSON on disk, typed in
  memory and in scripts); `Tilemap::tiles` moves to it with a change counter, so physics, nav and render rebuild only
  the chunks that changed (today every physics step hashes every tile of every map); the other hot `Json` fields
  (about 46 in components.h) are checked one by one.
- M94.3 (M) Commands and scripts: schemas compiled once at registration (defaults, validators, regexes); the script
  bridge reads component fields through cached accessors instead of a Proxy per field.
- M94.4 (L) 3D physics at scale: a broadphase (dynamic AABB tree; today every pair is tested every substep), islands and
  sleeping, contact manifolds with several points for every shape pair, flat containers instead of `std::map` in the
  solver, and a heightfield collider for M75.5's terrain. A stack of 100 boxes comes to rest, 1000 bodies stay within a
  budget.
- M94.5 (M) Jobs and paths: per-worker job queues with stealing instead of one global mutex; `NavGrid::search` answers
  "unreachable" from its region labels before searching (still returning the closest reachable node when asked).

## M95. A render core for HDR and what follows (L; 3 packages) — outside review, 2026-11-09

- M95.1 (L) The engine's GPU layer over sokol_gfx: pipeline keys carry the colour format, sample count and depth format
  (`kColorFormat` is fixed today, which blocks M71's float targets), a pipeline and state cache, and no backend types in
  public headers. M77's D3D12 and Vulkan plug in here.
- M95.2 (L) A render scene: the world gathered once per frame and shared by every camera and view, material parameters
  hashed when they change (today `materialParams.dump()` is hashed per mesh per frame), sort keys, and `draw_job`
  (about 770 lines) split into passes.
- M95.3 (L) A frame graph: passes declare the targets they write and read, transient targets come from a pool, and
  shadows, post-processing and render targets are passes with their cost in the profiler. M71 (HDR and the stack), M72
  and M76 build on it. Test: every golden unchanged on every backend.

## M96. A smaller player: runtime and authoring apart (L; 3 packages) — outside review, 2026-11-09

- M96.1 (L) `fa_runtime` split: the authoring commands that live in it today (wfc, level, terrain, mesh, anim and vfx
  authoring...) move to a library the player does not link; the editor, the CLI and MCP keep them; the export checks
  that a game's scripts call only runtime commands, with a teaching error naming the command.
- M96.2 (S) Player size budgets per platform in CI, with a report of what each library adds.
- M96.3 (M) Script budgets: the QuickJS memory cap (768 MB today) is a project setting per platform, and a per-frame
  script time budget warns in the profiler and in `play.report` long before the watchdog cuts a callback.

## M97. Docs that are true and cheap to read (L; 5 packages) — outside review, 2026-11-09

- M97.1 (M) A cheap first step: AI_GUIDE opens with an index under 5 KB, and its §4 (a hand-written table of about
  33 KB) is generated from the registry; AGENTS.md and the `make-game` prompt read the index and the sections a task
  needs, never `components` whole (docs/COMPONENTS.md is 1.76 MB); `docs.list` gives each doc a one-line summary and
  its audience (the game's AI, the user, the engine developer).
- M97.2 (M) Paging: `docs.components` and `docs.commands {full:true}` page with a cursor; MCP `tools/list` offers
  profiles (core, a group, all) for clients without tool search, like M45's catalog does for the API providers.
- M97.3 (M) Structure: a size budget per doc (about 60 KB, references aside) checked by a test; MENUS.md's copy of the
  kit (82 % of it) served from the kit instead of embedded; COMPONENTS.md served per component instead of embedded
  whole; the docs for engine developers (releasing, extending, architecture) under `docs/design/`; the 15 docs the
  README does not link reached from its index; the README restructured (what it is, try it, docs by audience).
- M97.4 (M) Doc tests: every JS block parses and uses only existing script API (checked against the typings); every
  command, component and field a doc names exists; counts and sizes come from their source; every doc is reachable
  from the README; a translation records the English commit it follows and is flagged when the original moves on.
- M97.5 (M) Example games a user can get: the download carries none (only a clone of the repository has `examples/`),
  yet 12 embedded docs cite `examples/...` paths and the editor's start window scans `~/FactorIA/examples`, a folder no
  package creates. Each release publishes every example as its own zip (the project without `.factoria/`) with its
  hash; `project.examples` lists them (what each shows, its size) and `project.create {example}` downloads the one of
  the installed version, checks it and creates the project from it, with a teaching error offline; the start window
  gets an Examples tab built on them instead of the folder scan. Each example's README opens with what it shows and
  what to read first. Every `examples/...` citation in the docs keeps the recipe in the doc itself and names the
  example as optional ("if you got it with `project.create {example}`"); M97.4's test flags one without that. The
  base download stays without examples (user, 2026-11-09).

## M98. What games expect and the engine lacks (L; 9 packages) — outside review, 2026-11-09

- M98.1 (M) Save slots (M19): slots with their menu in the kit, a version field with a migration hook, optional
  encryption, cloud through `platform` where a backend has it, and a picture per slot (M31.24).
- M98.2 (M) WebSocket in JS on every platform (M19): the browser's on the web, a native client elsewhere, reconnects,
  tests against a local server.
- M98.3 (M) Render interpolation: a project setting (and one per entity) draws transforms between the last two fixed
  steps, so a 60 Hz simulation looks smooth at 120-144 Hz; cameras and physics bodies included.
- M98.4 (M) Android shutdown (M9): `onDestroy` and the end of the process reach the game (`onQuit`), storage is
  flushed, tested on the emulator.
- M98.5 (L) Pads on Windows beyond XInput: DualShock and DualSense, Switch Pro and generic HID pads, rumble on every
  platform that has it, hot-plug without polling.
- M98.6 (L) UI (M10's leftovers): layout and hit tests that follow rotation and scale, a layout that does not add into
  `Transform.position`, and `TextField` caret movement, selection, clipboard and IME composition on desktop, phones and
  the web.
- M98.7 (L) Editor basics: multi-selection, copy and paste of entities (between scenes too), prefab overrides shown,
  applied and reverted, and undo as commands instead of whole-scene snapshots (up to 100 full copies today).
- M98.8 (M) 3D audio beyond pan and linear fade: distance models (inverse, linear, exponential, a curve), doppler,
  cones, occlusion by physics rays, and HRTF for headphones, for `AudioSource` and for M101.3's `audio.play` at a
  position.
- M98.9 (S) A deprecation policy: `deprecated` on commands, fields and script API (since when, the replacement),
  warnings that name the replacement, removal after two minors, in `api_since.json` and the docs.

## M99. Proven on real hardware and in the stores (S each; needs the user) — outside review, 2026-11-09

What CI cannot prove, gathered from the "Left open" lists so it is not lost; each item needs the user's hardware,
certificate or account, and ends with a note of what was tried and what passed:
- Windows signing with an Authenticode certificate or Azure Trusted Signing (M8).
- Real pads on Linux and Android (M8), an Apple pad on iOS (M9), the new Windows pads (M98.5).
- The MSIX installed on a real Windows and an upload to the Mac App Store (M23); each M12 store backend with a real
  account.
- A device farm (an arm64 Android emulator, real GPUs), or a few phones and tablets run by hand with `play.auto`.
