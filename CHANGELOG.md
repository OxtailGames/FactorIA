# What's new in FactorIA

The editor shows these notes when it offers an update, and each release on GitHub uses its section. Newest first.

## Unreleased

M70 (in progress) gives the engine a job system: a pool of worker threads that engine work is split over, set by
`runtime.jobThreads`, with a hash of the whole game state that shows threads never change what the game computes.

### Changes

- **For engine developers (M70.4a):** the engine's own LZ4 and Zstandard codecs behind `fa/core/compress.h` (no outside library). `Codec::Lz4` reads and writes the LZ4 block format (levels 1 to 12: a fast greedy level 1-2, a hash chain with lazy matching from 3); `Codec::Zstd` reads every Zstandard frame the reference tool writes (all levels including `--ultra`, `--long` windows up to 128 MiB, Huffman and FSE tables of every kind, repeat offsets, skippable and concatenated frames, the content checksum; a dictionary or a larger window is an error that says so) and writes valid frames with the content size, Huffman-coded literals and FSE-coded sequences (levels 1 to 19; level 3 makes a smaller frame than `zstd -3` on the files tried). Output is deterministic on every platform. Decoders check every bound and refuse an `expectedSize` the block cannot hold before allocating. docs/ARCHITECTURE.md, "Block codecs".
- **For game authors and AIs (M70.1):** `runtime.jobThreads` in factoria.json sets the worker threads of the engine's job system: `"auto"` (the default: hardware threads - 1, at most 8 on desktop and 4 on phones; 0 in a web build), a number 0..32 written as a whole number (0 runs every job on the main thread; `"4"` in quotes and `4.0` are refused with a hint), or `"inline"` (debugging: every job runs at once on the thread that submits it). The `FA_JOB_THREADS` environment variable overrides it for one run (a bad value is reported and the file's setting is used); a bad value in the file stops the start with an error at `/runtime/jobThreads` and a "did you mean" (the words are exact there: `"Inline"` is refused with the spelling to use). `jobs.info` says what runs: workers, mode, the setting and where it came from, the jobs of the last frame, how busy each thread was, the threads waiting now and this engine's unfinished jobs (`enginePending`). `game.state_hash {perEntity?, includeRuntime?, maxEntities?}` returns one 64-bit hash of every entity, component and field, the clock and the random generator: the same at the same frame with any thread setting and in a replay (`perEntity` finds the entity that differs). The profile of `perf.profile` and `play.report` has a `threads` section (one entry per thread: job time, share of the frame, its slowest jobs by name), and the editor's Profiler panel a **Threads** tab with one row per thread (editor autotest section A2). See docs/PERFORMANCE.md, "Job threads".
- **For engine developers (M70.1):** `fa/core/jobs.h`: `jobs::start`/`stop` (reference counted; the Engine calls them; `start` returns a `Result` and refuses another thread and calls from inside a job), `jobs::Owner` and `OwnerScope` (each Engine owns the jobs and main-thread tasks queued in its init, frames, scene loads and commands: shutdown waits for its own jobs, a frame runs only its own tasks, `end_frame(owner)` lets one engine close the job statistics; `CommandRegistry::set_job_owner`), `submit(name, fn, deps)` with `Handle`, `wait`, `wait_all` and `Group`, `parallel_for` with deterministic chunks (`Chunk::rng()` from a seed and the chunk index), `parallel_map_chunks` and `parallel_reduce` that merge in chunk order, `post_main` / `run_main_thread_tasks` for results that go back to the main thread, `info()`/`info_json`, settings parsing (`parse_settings`, `parse_settings_text`, `auto_worker_count`). A wait runs only what the job it waits for needs (never an unrelated job; `parallel_for` runs only its own chunks and `Owner::wait` only what its owner needs), so it ends with 0 workers too; `parallel_for` never returns while one of its chunks runs on another thread; a wait that can never end (through any chain of waits) returns an error instead of hanging, a job that throws is caught and fails the jobs that depend on it. `fa/scene/state_hash.h` (`world_state_hash`, `entity_state_hash`, `state_hash_hex`; components go in sorted by type name, not registration order), `EngineConfig::jobThreads`, `ProjectSettings::jobThreads`, `Profiler::add_job` and `ProfFrame::lanes`. The rules a job follows to stay deterministic, and the one for log sinks (thread-safe: they run on the thread that logs), are in docs/ARCHITECTURE.md, "Jobs and threads".

## 0.18.0

FactorIA 0.18.0 (M66-M69) makes the AI cheaper to trust and quicker to check. M66 puts an estimated price on every paid picture, sound, voice, song and 3D model, refuses a call that would pass a per-run or per-day limit before anything is sent, asks the user before an expensive one, and makes 1 to 4 candidates for one asset that the user picks from (`assets.generate_image {count}`, `assets.pick`). M67 lets the game play itself: `play.auto` runs it headless and fast with a bot, reports where it got stuck, fell or crashed with screenshots, and the editor's Let the AI play shows the sessions. M68 puts the game on a phone: `project.serve_web` and File > Play on Phone... serve the web build on the local network behind a QR code with live reload and the phone's log, and the web export can be one HTML file. M69 shows many choices at once: `review.sheet` draws numbered candidates on one contact sheet, `review.pick` keeps the person's choice, and the editor's Review window lets them pick with the keyboard, compare two side by side and see the history.

### Changes

- **For game authors and AIs:** asset providers have `assetPricing` (`image` by size and quality, `voicePer1000Chars`, `soundPerSecond`, `musicPerSecond`, `model3d`, `checked`, `source`); the built-in `openai`, `elevenlabs` and `meshy` ship one, `ai.providers` shows it, and your `ai.json` can replace it. Every `assets.generate_*`, `image.inpaint` and `image.generate_layer` result has `estimatedCostUsd`, `costIsEstimate: true` and a `cost` object (basis, what the run and the project spent, when the prices were looked up); `fake` and local providers cost 0. `dryRun: true` on `image.inpaint` and `image.generate_layer` returns the estimate without calling. These are estimates, not invoices.
- **For game authors and AIs:** `limits.maxAssetCostUsd.perRun` and `.perDay` (estimated dollars; 0 = no limit) and `limits.askAboveUsd` (default 0.50) in `ai.json` and in a project's `.factoria/ai/settings.json`, checked before each call with errors that say which limit, what is spent and how to raise it (`asset_cost_limit`, `asset_cost_unknown`, `asset_cost_unavailable`, `asset_declined`). The per-day total is shared by every editor and terminal under the user-folder lock (`asset-spend.json`); a lock failure is reported and counts nothing.
- **For game authors and AIs:** a paid call above `askAboveUsd` waits for the user. In the editor a card under the chat offers Approve, Approve all for this run and Cancel while the editor stays usable; from the CLI, MCP or a script the command returns `needsApproval` with the plan and an AI must ask its user and only then repeat the call with `approved: true` (AI_GUIDE.md says so, and so does every command's description). AI Settings > Assets has a Spending limits block with its own Save limits; the Image panel's Make it counts as the approval (it goes through its own channel: the assistant's `approved` argument is ignored whenever the editor can ask the user). Small calls under `askAboveUsd` that add up above it since the last yes are asked about as one, Stop gives `cancelled` (not `asset_declined`), a refund goes back to the day it was counted on, and the ElevenLabs figures and OpenAI pictures made with a model other than `gpt-image-1` are marked unverified.
- **For engine developers:** `fa/ai/asset_cost.h` (`estimate_asset_cost` with a count for candidates, `AssetCostGuard`, `AssetRunScope`, `AssetApprover`, `asset_spent_today`, `format_usd`), `builtin_asset_pricing` and `asset_pricing_to_json` in `fa/ai/config.h`, `ProviderStatus::assetPricing`, `AiCommandOptions::assetApprover`; in the editor `AssetApprovals` (`ai_asset_approval.h`, the cards and their answers, tests in `tools/editor/tests`) and the autotest section A3 (the card in the 1024x642 window).
- **For game authors and AIs (M68.1):** `project.serve_web {lan?, stop?, player?, allowPlayerMismatch?}` plays the game's web build from a small HTTP server inside the editor, `factoria mcp` or `factoria session`. It exports the web build into `build/serve-web/` (the project's own export folder is not touched), listens on 127.0.0.1 only unless `lan` is true, on a random port, and the URL has a random token in its path (`http://<address>:<port>/<token>/`; a request without it, or for a file outside the build, is the same 404). It returns the URLs. While it runs, a changed script, scene, asset or `factoria.json` exports again (a failed export keeps the last good page and the page shows the error) and every open page reloads itself. Correct MIME types (`application/wasm`), no directory traversal (`..`, encoded dots and slashes, backslashes, absolute paths), a request head of at most 8 KB, a log body of at most 16 KB, 8 connections answered at a time and 32 waiting. `{"stop":true}` or the end of the process stops it. Without the web player installed the error says to run `factoria setup players --platforms web`. A one-shot `factoria call` ends the server when it returns. In the editor the command never waits (the UI thread must not): it answers `state: "starting"` while a helper thread starts the server and exports, and the caller repeats the call until `state` is `ready`. The token comes from the operating system's random generator (constant-time comparison), a 400, 413 or 431 answer ends with a lingering close, a path that is not valid UTF-8 is a 400 and Windows device names (`CON`, `NUL`, `COM1`...) are refused.
- **For game authors (M68.2):** File > Play on Phone... (and a **Play on phone...** button on the Export window's Web row) starts that server for the local network and shows its address as a QR code drawn by the engine (its own encoder: byte mode, error correction M, the version the address needs, the mask chosen by the penalty rules of the standard), with **Copy address**, **Open on this computer**, **Stop**, and a checklist for a phone that cannot open it: the same Wi-Fi, the firewall prompt on Windows and macOS, guest networks that isolate devices, a VPN. What the phone's page logs (`console.log/warn/error`, uncaught errors) comes back to the editor's Console with category `phone` (at most 600 lines per minute, 1000 bytes each; one warning says how many were dropped). Editor autotest section T2.
- **For game authors and AIs (M68.3):** `project.export {platform:"web", singleFile:true}` (`factoria export --platform web --single-file`, **One HTML file** in the Export window) writes `<slug>-web/<slug>.html`: one page with the player's JavaScript, the wasm, the icon and `game.pak` inlined as base64, which runs offline from a double click (`file://`). No zip. It is refused, before the page is built (64-bit size from the files), when it would be over `singleFileMaxMb` (default 64, 1 to 256, a fraction such as 1.5 is fine; `--single-file-max-mb`) and when the web player is a threaded build (a shared-memory wasm needs cross-origin isolation headers, which a file cannot have); the error says how to fix it. Contradictory arguments (`singleFile` with another platform, `singleFileMaxMb` without `singleFile`) are errors with the JSON pointer.
- **For engine developers (M68):** `fa/tooling/net.h` (the portable TCP layer `factoria mcp`'s HTTP server now uses too: listen, accept, loopback connect, timeouts, the private addresses of this computer), `fa/tooling/serve_web.h` (`WebServer`, `web_server()`, `ServeWebOptions`, `ServeWebStatus`), `fa/tooling/qr.h` (`qr_encode`, tested against the vectors of the standard), `ExportOptions::singleFile` / `singleFileMaxBytes`, the editor's `phone_model.*` and `phone_panel.cpp`.
- **For game authors and AIs (M69.1):** show choices on one sheet. `review.sheet {items, columns?, thumbSize?, label?, candidates?, dropDir?}` draws up to 48 candidates as ONE picture with numbered thumbnails (a big number, the label and a line of facts) and returns it as `$image`: images, vector art (.svg) and level seeds (`tilemap.generate` arguments with `seeds`, one thumbnail per seed) are drawn on the CPU, scenes, prefabs and effects (the middle picture of `vfx.filmstrip`) by the engine's renderer and fail with `no_gpu` before anything is written when there is no graphics device. Requests are checked first with JSON pointers and "did you mean" (two types in one item, a typo of a key, a missing file, a sheet over 8192 pixels or 16 million pixels, a level with `into`, `seed` together with `seeds`). Each sheet is kept under `.factoria/review/sheet-NNNN/` (`sheet.png`, `thumbs/NN.png`, `manifest.json` with the items, labels, facts, the exact spec of each, when it was made and `picked`). `review.pick {sheet, n, drop?, note?}` records the person's number and, with `drop`, MOVES the files of the other items marked `candidate` to `.factoria/review/dropped/<sheet id>/` (the pick deletes nothing; all or nothing, listed in the result so a move can be undone); over MCP and the CLI the number must come from the person. `review.list` and `review.info` read the sheets. A hand-edited manifest cannot make a pick move a file it could not have been asked for (every source and destination goes through `resolve_project_path` again, candidates need the right suffix and are never `factoria.json`, `assets.json`, anything under `.factoria/`, the main scene or the stage of an effect). A level may sample the Tilemap entity of the main scene or of the scene named by `sampleScene`. Each picture is shrunk to its thumbnail as soon as it is drawn and a huge header is refused before decoding (PNG, JPG, BMP, TGA). `meta` is a free object stored with the sheet and returned by `review.pick`, `review.info` and `review.list`; `review.cleanup` (also run after each new sheet) deletes the files a pick dropped after `droppedDays` (default 7; 0 keeps them) and removes sheet folders abandoned for an hour. A link to a folder inside the project cannot dodge the rules about the main scene, `.factoria/` or a stage file (the file a name really leads to is compared too), a level's `sampleScene` cannot be a candidate, a picture that is not a PNG, JPEG, BMP or TGA is a red tile, and the name of a dropped file is cut to 255 bytes (`review_drop_file_name`). The `fs.*` commands, `resolve_project_path` and the review commands also work with project paths longer than 260 characters on Windows. A hand-edited manifest with a text where a number belongs is refused or skipped with a reason, never a crash. New `fa/tooling/review.h` (`review_reserve`, `review_commit`, `review_abandon`, `review_load`, `review_list`, `review_pick`, `review_cleanup`, `review_candidate_problem`, `review_drop_file_name`) is the storage a later editor window uses. See docs/AI_GUIDE.md (9.32) and docs/ASSETS.md.
- **For game authors and AIs (M67.1-M67.3):** the game plays itself. `play.auto {scene?, seconds?, seed?, speed?, stuckSeconds?, bot?, screenshots?}` (MCP `play_auto`, `factoria call play.auto`) runs the game headless and fast with a bot for up to 3600 game seconds and writes a play session under `.factoria/sessions/` with `"source": "auto"`: perf, spikes, warnings and script errors, `phases` (the scenes it loaded and the `game.phase(name)` marks, with game times and a screenshot each), `score`, how it ended (`won`, `lost`, `timeout`, `stuck`, `broken`, `quit`, `aborted`) and a screenshot at the end. `play.report` and `play.sessions` read it like an editor session (`play.report` also takes `phase`). The bot is the game's `scripts/autoplay.js`: `game.autoplay((bot) => ["move_right"])` is called once per step with the state (`time`, `step`, `scene`, `actions`, a seeded `bot.rng`...) and answers the actions to hold, or `{actions, end: "won"|"lost", score, note}`; `game.phase(name, {ends?})` marks a stage. A shipped game never runs it (`factoria export` leaves `scripts/autoplay.js` out). Without the file a generic explorer holds the declared actions in seeded patterns. The 2d-platformer template ships a hook that finishes its sample level. Deterministic: game seconds and fixed steps only, the same seed gives the same input, phases, ending and numbers. Stuck and broken detection ends the run with a mark, a screenshot and the step: nothing moves for `stuckSeconds`, a menu with no way out, a script that fails every step, a fall out of the world, a position that is not a number. `input.json` is the bot's input in the replay format and the result's `replay` command plays it again with `factoria run --headless --input`. With no GPU the run has no pictures and says so in the session's notes. See docs/DEBUGGING.md, "Let the game play itself", and docs/SCRIPTING.md, "The bot".
- **Review round of M67.1-M67.3:** a fall is only reported for bodies that fall (dynamic bodies with gravity, character controllers) and its limit follows a world that grows (a top-down game, a generated level and a late-built tilemap no longer "fall"); the stuck signature also counts the entity count, the UI texts (a clock or a label animation does not count as progress) and the hook's score; a hook file that fails to import ends the run `broken` with a `hook` mark instead of silently playing the explorer, and one that never calls `game.autoplay` is a note (a problem with `bot: "hook"`); the default `stuckSeconds` never exceeds `seconds`; the internal wall-clock cap is 800 s (a safety net below the 900 s of the child process); `scripts/autoplay.js` is left out of an export whatever its capitalization; project folders with accents work on Windows (UTF-8 paths: new `fa::fs::path_from_utf8` and `path_to_utf8`); the replay command quotes a scene path with spaces; `scriptErrorEvents` is now `errorsLogged`; docs/CLI.md no longer claims `--no-graphics` removes the pictures (use `"screenshots": false`).
- **For game authors and AIs (M67.4):** the loop is closed. docs/AI_GUIDE.md (new 11.5) and the `AGENTS.md` that new projects get say to run `play.auto` after a feature and before asking the user to play, and how to read its report (`ended`, `endedWhy`, the marks, the phases, the score and the notes). The editor has a **Play** menu: **Let the AI Play** runs `play.auto` on the saved project in a `factoria` process of its own (the editor stays free; elapsed time, the bot's last line and **Cancel**, a cancelled run writes no session), and **Play Sessions...** opens the new **Play sessions** window: every session of `.factoria/sessions/`, the AI's marked **AI** with how it ended, each with its report, **Attach to the AI chat** and the replay command. When a run ends a toast opens its report. The AI panel's **Attach last play session** picks the last session the person played; it takes one of the bot's only when there is none of the person's, and says so (toast and a note in the message). Game reviewers use `play.auto` as support after playing by hand (the reviewer prompt, `review_task` and the `review-ready` skill: the bot reaches the phases the reviewer did not, backs an opinion with numbers, and its success says nothing about clarity or fairness); `play.auto` is allowed for read-only roles (the art critic's prompt does not mention it, but a role cannot be refused one read-only tool). Lantern Keep swaps its test bot (`tests/helpers/autoplay.js`) for the game's own hook `scripts/autoplay.js`: the JS tests drive the same `decide` step by step (`tests/helpers/level.js`) and the new ctest `example_lantern-keep_autoplay` runs the real `play.auto` on every level and from the main menu and checks each ends `won`. `play.auto` called by the AI inside the editor no longer freezes the window: it runs in its child process on the AI's thread and the AI panel's Stop kills it. A project folder with accents works for Let the AI Play and for the AI's `play.auto` (the path goes to the child as UTF-8; known Windows limit: a folder with characters outside the system code page cannot be passed to the child yet). `play.auto` takes its pictures in `.factoria/cache/play-auto-<pid>-<n>/` and moves them into the session when the run ends (a cancelled run leaves no session folder; the next run deletes what a killed one left), and once its session is written keeps the newest 30 automatic sessions.
- **For engine developers (M67):** `fa/runtime/play_auto.h` (`play_auto`, `PlayAutoOptions`), `fa/tooling/play_auto.h` (the command), `PlaySession` gains `source`, `phases`, `score`, `ended`, `endedWhy`, `endScreenshot`, `notes`, `scriptErrors`, `autoInfo`, and `PlayMark` gains `kind` and `step`; `ScriptSystem::autoplay_begin`, `autoplay_step`, `autoplay_take_phases`, `autoplay_end` and `error_events`.
- **For game authors and AIs (M66.3):** candidates for one asset. `assets.generate_image {count}` (1 to 4; 1 is the old call) makes that many candidates for the slot `path`, written next to it as `<name>.candidate-<n>.png` with seeds `seed`, `seed+1`... (from the prompt when no seed is given) and each its own provenance, and ONE review sheet that shows them (`meta.kind` `"assetCandidates"`, drop folder `.factoria/assets/candidates`); the sheet comes back as `$image` with the next steps. The estimate, the limits and the approval cover the whole batch before the first picture; a provider failure part way names the candidates written and what they cost and gives back the rest of the estimate. `assets.pick {slot, n, sheet?, note?, overwrite?}` answers the newest candidates sheet of the slot (a regeneration replaces the older one, which is refused as `superseded`, and its result says so; a candidate file whose SHA-256 no longer matches the sheet is refused the same way) through `review.pick`'s lock and all-or-nothing moves: the chosen candidate becomes the slot with its provenance (plus the sheet, the number picked and the batch estimate), the candidates' entries leave `assets.json`, the others (and an old slot file, with `overwrite`) move to `.factoria/assets/candidates/<sheet id>/`, which `review.cleanup` empties after 7 days. `already_picked`, `superseded`, `not_found` with suggestions and `busy` say what to do; plain `review.pick` refuses a candidates sheet and names `assets.pick`, and reports a file open in another program as `busy` (it was `failed`). The editor's Review window calls it with `{sheet, n, slot}`. For engine developers: `ReviewPickOptions::step` (a caller's own change inside a pick's all or nothing), `review_sheet`, `review_newest` and `kReviewAssetCandidatesKind` in `fa/tooling/review.h` and `AssetCostGuard::commit_part`.
- **For game authors (M69.2):** the editor's **Review window** (View > Review, docs/EDITOR.md "Review window"). It lists the project's review sheets (still waiting first, newest first) and shows one big (fit, zoom, scroll), each numbered thumbnail clickable with its label and facts. **1-9** select, the **arrows** move, **Enter** asks first: the confirmation lists the files that move to the drop folder, takes a note and offers **Keep the other files where they are** (`drop: false`), and the pick runs `review.pick` in a child `factoria` (the window keeps drawing while files move) and shows the files moved and the warnings, or says that a file is open in another program. **Compare** puts two numbers side by side (the candidates' own pictures or their thumbnails), **History** lists past picks (who, when, which number, the note, each dropped file `moved`, `expired` or `gone`) and opens an answered sheet read-only. A sheet of asset candidates (`meta.kind` `"assetCandidates"`) shows its slot and is answered with `assets.pick` in a child `factoria`, after which the slot's picture is reloaded; an older sheet of the same slot (the newest is the one with the highest number, answered or not, as `assets.pick` decides) is marked superseded and read-only, and a `factoria` without that command makes the window say so. What the window picks is the sheet, the number and the note of the moment Confirm is pressed; a pick waits while the picture reader still has files of that sheet open. The note is cut at 500 bytes on a character boundary (an accented note can no longer stop the editor). The Level generator's **Sheet of seeds** makes a sheet of N seeds of its settings with `review.sheet` in a child `factoria` (the editor keeps drawing, Cancel stops it) and opens it; picking one sets that seed in the Level generator. A `review.sheet` the AI or an MCP client runs, and an `assets.generate_image` with a `count` an AI runs (its toast names the slot), are offered in a toast ("Open in Review") that does not take the focus. Pictures are read and decoded on a worker thread (a picture whose header says more than 8192 x 8192 pixels is refused before it is decoded), uploaded one per frame, shrunk on upload (4096 px a side for a sheet) and freed when the window stops drawing them; Compare keeps showing the pictures it has while a pick runs and asks for no new one. Closing the editor or switching project waits up to 15 s for a running pick, then stops it. For engine developers: `fa::image_size` (`fa/core/image.h`, a picture's size from its header) and `CommandRegistry::handler` (wrap a registered command). Editor autotest section R4; the model, the reader and the child job are tested in `tools/editor/tests/review_tests.cpp`.
- **Polish round of M66-M69:** the Image panel's Make it plans its request on the same thread as the provider call (a mistake shows under the panel as a failure with nothing charged) and counts into a run of its own, so `limits.maxAssetCostUsd.perRun` covers the panel's calls of the open project, not the CLI's; the notice of a refund that could not be written waits for a call that goes ahead instead of being lost with one that is refused; the approval card keeps its buttons in view with a long provider name; a Review pick killed after 15 s on closing or switching project is logged and, if the editor stays, told in a toast; a waiting pick says it waits for the window to let go of the files, the extra lines of a pick open in a tooltip, and the Level generator's sheet of seeds says it opens in the Review window; `review.sheet`'s and `assets.generate_image`'s `$image` paths keep accented names as UTF-8.

## 0.17.0

FactorIA 0.17.0 (M61-M65) lets each project set its own AI and makes games feel and look alive. M61 gives a project its own AI settings (roles, limits, asset routes and sites, token savers, tool servers and extensions) on top of your defaults, edited in the editor or with `ai.settings.get`/`ai.settings.set`, and lets each project share feedback its own way under a lock that several programs respect. M62 adds game feel as engine features: camera shake, hit-stop, flash, knockback and squash and stretch, run from animation events, plus palette-ramped effects drawn by code in back, front and light layers. M63 generates levels from an example with Wave Function Collapse (`tilemap.generate`), with constraints, reachability, markers placed by walking distance, and generation while the game runs. M64 makes particles rich enough for smoke, fire and pixel-art sparks, bundles them with lights, sounds and commands into effect documents with their own editor panel, and reviews an effect's budget before it ships. M65 adds efficiency feedback: an AI reports what cost it time and tokens, a retrospective finds it in the recorded runs, and the engine developers rank it by the saving across installations.

### Changes

- **For game authors and AIs:** camera shake, hit-stop, flash, knockback, and squash and stretch. `camera.shake(amount, { duration, frequency, maxOffset, maxAngle, cap, camera })` adds trauma to a camera (2D and 3D; the shake is trauma squared, deterministic noise seeded from the world's RNG without consuming it). `time.hitStop(seconds, { scale })` freezes or slows the game for REAL seconds while the UI, audio, `runWhilePaused` behaviours and the other effects keep going (overlapping calls do not add up: the longest wins, the smallest scale applies; a pause stays unbroken; `time.hitStopRemaining`). `entity.flash({ color, duration, fade, strength })` draws sprites, shapes and 3D meshes in one colour (the same on OpenGL, Direct3D 11, Metal and web; a mesh's flash is emission, so it shows in the dark). `entity.knockback(direction, { speed, lockTime, decay })` adds an impulse to a dynamic physics body, else moves the entity with a decaying velocity, and `entity.isKnockedBack` / `knockbackRemaining` is the loss of control. `entity.squash({ amount, duration, axis })` is a volume-preserving scale pulse back to exactly the entity's own scale. Shake, flash and squash are a draw-time pose: Transforms, saves, physics and scripts never see them, so nothing is left behind. Accessibility: `feel.reduceMotion` (shake and squash x0.25, hit-stop x0.5) and `feel.reducedEffects` (flash at most 0.35 and always fading) follow the system's reduce motion unless the game sets them; the menu kit's `settings.js` sets both from its "reduced effects" option. With no active camera `camera.shake` does nothing and logs one warning; the default knockback speed is 6 metres per second (6 times `physics.pixelsPerMeter` in 2D); a game's reduce-motion choices end when an engine starts or an editor Play session stops, and `feel.*` commands do not mark the scene edited. New commands `feel.shake`, `feel.hitStop`, `feel.flash`, `feel.knockback`, `feel.squash`, `feel.cancel`, `feel.settings`, `feel.state`, and every action is also data (`feel.do({ action: "flash", ... }, target)`). See docs/GAME_FEEL.md.
- **For game authors and AIs (M62.2):** clip events carry game feel actions as data. An event of a 2D or 3D clip file (`{t, name?, data?, feel?}`), of `Animator.events` (`{clip, time, name?, feel?}`) and of the new `SpriteAnimator.events` (`{frame, clip?, name?, data?, feel?}`, one per sheet frame) takes `feel`: one action object or an array, the same form as `feel.do`, run for the entity that plays the clip. An event needs a `name`, `feel` or both. Firing is deterministic: once per loop pass, frames skipped by a long step still fire in order, a seek fires nothing. Two new actions and commands: `spawn {prefab, offset?, local?, lifetime?}` instantiates an effect prefab at the entity (the next effects update, never inside an iteration; `lifetime` seconds of game time destroy it: a hit-stop or a pause holds the count; at most 64 spawns wait for one frame, the extra ones are dropped with one warning per scene; `project.validate` warns about a `spawn` without `lifetime` whose prefab has no Script or `autoDestroy` particles) and `sound {path, volume?, pitch?, pan?, bus?}` plays a sound through the audio system (`feel.spawn`, `feel.sound`); `knockback` also answers to `push`, and `knockback` and `spawn` take `local: true` (the direction or offset in the entity's own space, so a mirrored sprite flips it). Loading a clip checks every action and reports a typo with its JSON pointer (`/events/2/feel/0/action`) and a "did you mean"; `project.validate` also checks that a prefab or sound file exists. An action that fails while the game runs is logged once per scene and the rest of the event still runs, and an inline `Animator.events` or `SpriteAnimator.events` entry with a wrong JSON type (`"action": 5`, `"name": 5`) is skipped with one warning per scene (component, JSON pointer, fix) instead of throwing in the frame loop; `project.validate` reports them as errors. `anim.add_event`, `anim.set_event`, `anim3d.add_event` and `anim3d.set_event` take `feel`; the editor's 2D and 3D Animation panels have a `feel` box in the event inspector and the 2D one has a preset button per action.
- **For game authors and AIs (M62.3):** effects as code with a palette. `assets.animate_svg` takes `ramp` (2 to 32 colours from dark to bright, or an image document with `ramps` and `rampIndex`): a module receives `ramp` and `rampAt(u)`, so one effect is recoloured by baking again with another ramp, and `rampMap: true` recolours the finished frames by brightness (for a SMIL SVG or a module that draws in greys). `layers: ["back", "front", "light"]` bakes one sheet per layer next to `path` (`hit_back.png`, `hit_front.png`, `hit_light.png`) from the same module, which receives `layer`; the sheets share the grid, frames, fps, clips, pivot and padding so they play in step (back under the character, front over it, light with `Sprite.blend` additive). The ramp and the layers are in the recipe, so `assets.regenerate` and `project.validate` keep them. Warnings: a ramp the module never reads, a layer that draws nothing in any frame. See docs/ASSETS.md.
- **For engine developers (M62.2):** `feel_check_action` (an action checked without a world), `feel_run_clip_actions`, `feel_event_actions`, `feel_spawn`, `feel_sound`, `feel_take_sounds` (`Audio::update` drains the sound queue, at most 64 wait), `read_event_feel` and `check_sprite_events` (`anim_clip.h`, `sprite_animator.h`), `sprite_animator_fire_events`, and `ClipEvent::feel` / `AnimClipEvent::feel`; `ClipEvent::name` may be empty.
- **For game authors and AIs (M62.4):** `docs/EFFECTS.md` (`docs_read {"name":"effects"}`): the loop for a drawn effect (the palette from the style, a draft with `assets.animate_svg`, a filmstrip at the size the player sees with `assets.contact_sheet`, a look that judges readability, anticipation, impact, recovery and palette, one change, bake again) and three worked effects with the real calls: an impact, a pickup and a fire loop. The `glow-and-effects` skill (artist role) carries the loop, `make-art` points to it. No effect library: each effect is written for the game's palette.
- **For engine developers (M62.4):** tests that an effect document's `command` parts run `feel.shake`, `feel.hitStop` and `feel.flash` through the feel commands at their frame (engine/runtime), and that `vfx.play` `scale` scales the entity and the offsets of the parts, not `startSize` or a light's `radius`. docs/EFFECTS.md points at `vfx.budget`, `vfx.filmstrip` and `vfx.review` for effect documents and `assets.review` for baked sheets.
- **For game authors (M62.4):** Sky Hopper uses the three: the coin plays a sparkle baked from `assets/src/anim/coin_sparkle.anim.js` (a gold `ramp`, `back`, `front` and `light` layers, `prefabs/coin_sparkle.prefab.json`), a stomp shakes the camera and holds the game for 0.05 s, a hurt flashes the hero red and shakes and holds longer, and the jump's squash is an event of `anim/hero_jump.anim.json`. Its tests are in `tests/feel.test.js`, and the gaps found are in its `ENGINE_FEEDBACK.json`.
- **For game authors:** Kindlewatch uses the engine's shake (`camera.shake`) instead of its own camera code and applies the player's reduced effects through `feel`.
- **For engine developers:** `fa/scene/feel.h` (`FeelState` in `World::feel()`, `feel_shake`, `feel_hit_stop`, `feel_flash`, `feel_knockback`, `feel_squash`, `feel_cancel`, `feel_apply_action`, `feel_begin_frame`, `feel_update`, `feel_fixed_update`), `World::drawn_matrix()` (the draw-time pose that only fa_render's drawing uses; bounds, picking, UI hit-tests, lights and the animation commands keep `world_matrix()`, and the camera's shake offset and roll are part of `OrthoView`, the script-side pointer mapping), `ScriptSystem::time_scale()` is now the effective scale and `user_time_scale()` the script's. The 2D quad shader has a flash variant (`mode + 32`, colour in `color2`; headers regenerated with `tools/shaders/compile_shaders.sh`), 3D flashes go through the existing emission path.
- **For game authors and AIs:** `ParticleEmitter` gains, all off by default so an existing scene loads and looks the same: a colour gradient (`colorGradient`) and keyed curves for size, speed and alpha over a particle's life (`sizeCurve`, `speedCurve`, `alphaCurve`); a flipbook (`flipbookColumns`, `flipbookRows`, `flipbookFrames`, `flipbookFps`, `flipbookRandomStart`); `startRotation`, `spin`, `alignToVelocity`, `drag` and seeded turbulence (`noiseStrength`, `noiseScale`, `noiseSpeed`); emission shapes `point`, `circle`, `box`, `cone`, `edge` and `mesh` (`shape`, `shapeSize`, `shapeFrom` volume or edge, `shapeDirection`, `shapeMesh`) and `inheritVelocity`; trails (`trail` `particle` or `emitter`, `trailTime`, `trailWidth`, `trailWidthCurve`, `trailGradient`); sub-emitters on birth, death and collision (`subEmitters`: an inline patch, a prefab file or another emitter's entity id); collision with a plane or a Tilemap (`collision`, `collisionPlane`, `collisionTilemap`, `collisionBounce`, `collisionFriction`, `collisionLifetimeLoss`, `collisionKill`); and a pixel mode (`pixelMode`, `pixelSize`, `palette`) that draws whole-pixel squares snapped to a palette. Particles are deterministic (`seed`) and bounded: at most 10000 live particles per emitter, 32 trail points per particle (16384 per emitter, from one pool) and 8 sub-emitters, 32 particles per event and 256 sub-emitter particles per step. Curves, gradients and the sub-emitter list that do not parse are reported with their file and JSON pointer by `factoria validate` and when a scene loads, and logged once at run time. docs/PARTICLES.md has the reference and three worked examples (hit spark, smoke puff, pixel fire), each run by a test.
- **For engine developers:** `fa/scene/curve.h` (`Curve`, `Gradient`, keyed values with `linear`, `smooth` and `step` interpolation and teaching parse errors, reusable by other effect data), `fa/scene/particles.h` (`ParticleSim`, the whole simulation with no GPU: emission, motion, collision, trails, sub-emitters; `ParticleStyle`, `particle_emitter_problems`, `flipbook_frame`, `particle_noise`, and the limits `kParticleHardCap`, `kParticleTrailPoints`, `kParticleSubDepth`, `kParticleSubCount`, `kParticleSubGroups`, `kParticleSubPerStep`). It uses only `+ - * /`, `sqrt` and `fa::det` trigonometry and its own `Rng`, so the same seed gives the same particles on every platform. `engine/render/src/particles.cpp` keeps one `ParticleSim` per emitter and draws it through the 2D quad batcher; the old emitter state and RNG draw order are unchanged when no new field is set, and the existing golden images pass untouched. New golden `2d_particles_m64`. `Renderer::reset_particles()` runs when a scene is loaded (editor Play and Stop included), so burst and seed give the same effect on every Play. Collision friction on a resting or sliding particle is per second (the same at 30 and 120 fps), a plane normal need not be a unit vector, a sub-emitter collides against the tilemap and lives in its parent's space, a prefab or entity link that cannot be had yet is retried every second, and the palette of `assets.json` is read once (`assets::manifest_version`, `assets::style_palette`).
- **For game authors and AIs:** effect documents. A `*.vfx.json` (`factoria.vfx/1`, schema `schemas/vfx.schema.json`) bundles up to 16 parts on one timeline: emitters (a patch over `ParticleEmitter`), a light flash that fades out, one-shot sounds, and commands from a fixed list (`feel.shake`, `feel.hitStop`, `feel.flash`, `feel.knockback`, `feel.squash`, `feel.spawn`, `feel.sound`, `audio.bus`, `audio.snapshot`, `audio.music`: any other name, such as `audio.bake` or `feel.settings`, is an error at its JSON pointer) that are called once at their time. `vfx.play` (a command, `vfx.play()` in scripts, MCP tool `vfx_play`) plays one at a position or on an entity with `scale`, `speed`, `rotation` and `loop`, and the effect removes itself when it is over; `vfx.stop`, `vfx.list` and `vfx.check` end, list and check effects. A new `Vfx` component places an effect in a scene like a prefab. A file that is wrong is an error naming the file, the JSON pointer and the fix, with "did you mean"; `factoria validate` checks them and that every sound clip is in the project. The timeline follows the fixed step and `time.scale` and uses no clock or random numbers, so the same effects at the same steps do the same on every run; at most 64 effects play at once (more are dropped with one log line); an effect's emitters are removed a fixed game time after they stop (the longest their particles live, sub-emitters and trails included), so a headless run keeps the same entities as a windowed one and a looping effect does not pile up. A changed file is read by the next play, effects already playing finish the version they started with. The engine ships no effects (docs/PARTICLES.md, "Effect documents", has a worked one that a test runs).
- **For engine developers:** `fa/scene/vfx.h` (`VfxDoc`, `parse_vfx`, `load_vfx` cached by path, modification time and size, `update_vfx`, `vfx_play`, `vfx_stop` and the limits `kVfxMax*`), the `Vfx` component, and `engine/runtime/src/vfx_commands.cpp` (the four commands, the sound and command hooks of `VfxHost` wired to the mixer and the command registry). A `command` part is allowed only for the names of `vfx_allowed_commands()`; `VfxHost::load` lets the caller supply the documents (the editor's preview plays an unsaved one). The runtime state of a `Vfx` is not saved, and entities made by `vfx.play` are marked `scriptSpawned`, so `scene.save` leaves them out.
- **For game authors and AIs:** M64.3 is the editor's Particles panel (View > Particles, or a double click on a `*.vfx.json` in the Project panel): an effect document played by the engine's own timeline and particle simulation, with a time scrubber (a moment always shows the same particles: the preview is seeded and rebuilt from the start, a bounded number of steps per frame so a drag never freezes the editor), a parts list with add, move and remove, an inspector built from the reflected fields of `ParticleEmitter` and `Light2D`, and a colour-gradient editor and a curve editor (click to add a key, drag to move it). Every kept edit is the new `vfx.edit` command (`set`, `remove`, `add`, `move` by JSON pointer; an edit that would make the file invalid is refused and the file is untouched) and one editor Undo step; `vfx.create` writes a starter effect. `*.vfx.json` files are now asset type `vfx` (`assets.list`, the Project panel's filter and badge). The preview does not draw ribbon trails or textures, shows additive blending as normal, and only marks sounds and commands on the timeline.
- **For engine developers:** `VfxHost::load` lets the caller of `update_vfx` supply the documents (the preview plays an unsaved one); `tools/editor/src/particle_model.*` (document, edits, undo steps), `particle_preview.*` (a scratch `World` with a `Vfx` entity and a `ParticleSim` per emitter, no renderer), `particle_curve.*` (key edits) and `particle_panel.cpp`; `tools/common/src/assets_vfx.cpp`; editor autotest section P3.
- **For game authors and AIs:** M64.4 reviews an effect before it ships. `vfx.budget` plays an effect document headless and reports its peak of particles alive, its overdraw (particle area over view area), its emitters and a timeline, with findings against a `phone` or `desktop` preset, each with a `vfx.edit` fix (a 3D emitter's overdraw is not measured, and the result says so). `vfx.filmstrip` plays the effect in the running game and returns a contact sheet of its frames, labelled with their time (it steps the game; in a 3D game give `position`). `vfx.review` shows that strip, the document and the budget to the vision model of the `fast` role and returns a verdict, a checklist (readability, timing, palette, overdraw) and concrete `vfx.edit` fixes. The gem-roller example plays its gem sparkle from an effect document made with them. Recipe in docs/PARTICLES.md, "Reviewing an effect".
- **For engine developers:** `fa/scene/vfx_budget.h` (`vfx_measure`, `VfxBudget`, `VfxBudgetLimits`, `vfx_budget_limits`); `tools/ai/src/vfx_review.cpp` and `review_util.h` (helpers shared with `assets.review`).
- **For game authors and AIs:** new command `tilemap.generate` (MCP `tilemap_generate`, M63) makes a level from an example by Wave Function Collapse, in FactorIA's own code. `sample` is a Tilemap entity or ASCII rows with a legend (the `scene.import_ascii` format). The `overlapping` model (default) fills the output with `n` x `n` windows (2..5) that all exist in the sample, or in its rotations and mirrors with `symmetry` 2/4/8 (`periodic` wraps the output); the `tiled` model takes which tiles may touch from the autotile rules (`Tilemap.terrains`) and ignores `n` and `symmetry`. The result is written into a Tilemap (`into`) or returned as `rows` + `legend`, with `stats`. Same arguments, same level on every platform (integer weights and entropy, the engine RNG); only `stats.ms` (the time it took) and the byte counts `stats.memoryBytes` and `stats.peakBytes` differ between runs and builds. A dead end restarts with the next derived seed up to `maxAttempts`, and the final error names the cell, the attempts and what to try. `maxWork` (units of work counted the same on every machine, so whether a level fits never depends on the speed of the computer) stops a level that cannot be solved with an error that says how to shrink it; `maxSeconds` (CPU seconds of the process, every thread counted; wall clock on the web build) is only a safety net on top. The solver's memory estimate is a proven upper bound of what it holds (a stack-free removal queue), computed before anything is allocated, and a size or a fixed rect that does not fit fails at once. (docs/AI_GUIDE.md, section 9.8)
- **For game authors and AIs:** `tilemap.generate` takes `constraints` and `reachability` (M63.2) so a generated level is a playable one. `constraints`: `fixed` cells or rects (entrance, exit), a `border`, `forbidden` tiles, `required` tiles and `counts` with `min` / `max` per tile; tiles are glyphs of an ASCII sample, tile numbers or terrain names, and a contradiction (a required tile that is forbidden, a fixed cell outside the level, minimums that do not fit...) is reported before generating, with the JSON pointer of the entry. `reachability`: the `from` cell must reach every `to` cell and every cell holding a `toTiles` tile, and with `allConnected` all walkable cells form one area, using the walking rules of `nav.find_tile_path` (`solidTiles`, `costs`, `diagonals`). A grid that breaks a rule is refused and the next derived seed is tried (50 attempts by default); a missing minimum is also repaired by pinning cells at positions drawn from the seed. The result reports `constraints` (counts found) and `reachability` (walkable and cut-off cells, a few rects of the areas that were cut off, path lengths). Contradictions the generator can find up front are reported before it runs, each with the JSON pointer of the rule: a `required` tile against a `max: 0`, minimums and maximums of tiles that share symbols (also against the fixed cells), a fixed or border tile that the sample can only show in other places or only next to a forbidden tile; a failure found while generating names the fixed cell or border entry near it. A `solidTiles` tile with a `costs` entry is walkable, as `nav.find_tile_path` reads it, and path costs are rounded to 3 decimals. Deterministic: every retry derives from `seed`, never the clock. (docs/AI_GUIDE.md, section 9.8)
- **For game authors and AIs:** scripts generate a level while the game runs (M63.3): `tilemap.generate({sample, size, seed, ...})` takes the options of the command plus `place` and returns a handle (`progress`, `done`, `error`, `hint`, `result`, `attempts`, `work`, `promise`, `cancel()`). The seed comes from `rng.create`, so a stored run seed rebuilds the level. Arguments are checked at once with teaching errors; the generator then works a little every frame (500000 units in tests and headless runs, about 4 ms with a window), and the level, `rows` and `stats.work` are the same as the command's whatever the frame rate. `place` builds the Tilemap and turns the sample's markers (glyphs with a `prefab`: spawn points, coins, enemies) into entities the way `scene.import_ascii` places them; `into` writes tiles only. A generation belongs to the scene that started it: a scene load rejects it, places nothing and frees its memory. At most 8 run at once and their memory adds up under the 256 MB limit. New commands `tilemap.generate_start`, `tilemap.generate_step` and `tilemap.generate_cancel` are the stepped form it is built on. (docs/AI_GUIDE.md section 9.8, docs/SCRIPTING.md)
- **Editor:** View > Level generator (M63.4) previews `tilemap.generate` in a window: pick a sample (the selected Tilemap or a level file), a size, `n`, `symmetry` and a seed, press Previous / Next / Random seed and see the level as a plan of coloured cells (a dot where a coin or an enemy would stand), with the attempts it took and a history of the seeds you tried. It runs the command in small steps (`tilemap.generate_start` / `_step`), so the editor keeps drawing, and the window never changes the scene on its own. **Keep in the scene** builds the shown level with `scene.import_ascii` as one undo step (objects included, replacing an earlier keep); **Save level file** writes the rows and legend as an ASCII level file that `scene.ascii_edit` edits. (docs/EDITOR.md, "Level generator")
- **For game authors and AIs:** `tilemap.generate` polish (M63 review). `constraints.repair` (default true) makes the minimum repair optional: with `false` a grid that misses a `counts` or `required` minimum is a failed attempt and the next seed tries again; a `counts` maximum is never repaired and is checked on the finished grid only. A misspelled argument of `tilemap.generate`, `tilemap.generate_start` or the script call is refused with "did you mean" and the list of valid keys (it used to be ignored), `reachability.costs` must be finite numbers that are not negative, the finished-grid checks (constraints and reachability) run in pieces so a step never stalls on a big grid, `maxSeconds` (default 1800, at most 86400) is a safety net on CPU seconds and `maxWork` is the cap a result depends on, the memory error says how much other jobs hold and how to free it, and `tilemap.generate_step` on a job that is gone (a scene load ended it) answers `not_found` (it answered `invalid_argument` before: a caller that tested for that code must test for `not_found`). A cost of +infinity in an engine-built `NavTileGrid` is passable at an infinite price instead of blocked (scripts and the commands still turn `Infinity` into a blocked cell), and the solver, the reachability check and the A* heuristic no longer have a piece whose size grows with the grid except the rebuild of the entropy heap, the re-tiling of a terrain level and one path search (docs/AI_GUIDE.md section 9.8). The jobs a script started are dropped with its context; jobs started by the console, MCP or the editor are not. The reachability check walks the same rules as `nav.find_tile_path` (4-way or 8-way without cutting corners, costs from the same table, ties broken in integers so a path is the same on every compiler). Scripts: the per-frame budget is shared equally by all running generations (more jobs make each slower, never a frame longer), `place` is checked by the call and not after the whole generation, and the jobs are dropped when the script context is reloaded or closed.
- **Editor:** the Level generator window (M63 review) builds the glyph table of a preview once instead of per frame, refreshes the sample only when the selection changes or a command ran (no `get_entity` every half second), shows a grey note instead of a red "unknown job" when a scene load ends a generation, refuses keys the window owns (`sample`, `size`, `seed`, `model`, `n`, `symmetry`, `periodic`) in **More options**, reads the result defensively, and explains in a tooltip why **Use the selected Tilemap**, **Keep in the scene** or **Save level file** is greyed out.
- **For game authors and AIs:** docs/AI_GUIDE.md section 9.8 says when to generate a level and when to write its ASCII by hand (a designed level or a few levels: by hand; many levels or a new one each run: generate, with a drawn sample, `constraints` and `reachability`, and seeds you looked at), and how to shape the sample: leave one-of-a-kind markers out of it and place them on cells of the result, and draw open areas when `reachability.allConnected` is asked. The tile-levels skill says the same. New example `examples/ember-descent`: a four-floor roguelike whose floors are generated at run time from one drawn sample, with the player and the stairs placed on a trap-free route by `scripts/floor_plan.js`; the run seed is one whole dungeon (R replays it). Its `ENGINE_FEEDBACK.json` records the gaps it found.
- **Engine developers:** `wfc::GenerateOptions` gained `forbidden` and `counts` (`wfc::CountRule`; a missed minimum pins cells on the next attempt), `GenStats` gained `work`, `pinned`, `heapRebuilds`, `heapPeak` and `peakBytes`, and the entropy heap is rebuilt when stale entries make it grow past 4 entries per cell. `wfc::kMaxTotalWeight` and the compat-table limit apply to the tiled model as well. `GenerateOptions::maxWork` is the deterministic work cap (`GenFailure::workLimit`), `accept` reports the work it did, `estimate_generator_memory` is 64-bit and saturating and `check_generator_memory` runs it before anything is allocated, `CellRule::label` and `CountRule::name` carry the JSON pointers into the generator's errors.
- **Engine developers:** the solver is `fa/scene/wfc.h` (`wfc::build_overlapping_model`, `wfc::build_terrain_model`, `wfc::Generator` with `step(budget)` and hooks for fixed cells and tile-count checks); `retile_terrain_grid` in `fa/scene/autotile.h` re-tiles a plain grid.
- **For game authors and AIs:** the efficiency feedback loop is documented (M65.4). docs/ENGINE_FEEDBACK.md, "Efficiency feedback", says when to file, shows three reports that pass the gate and three that it refuses ("rewrite the scene format to save 2k tokens", "use a cheaper model", "a guide for X" when `docs.search` finds it) with the gate's own words; docs/AI_GUIDE.md section 3 has the rule, the AGENTS.md template and every example's AGENTS.md and CLAUDE.md one line that points at it (the rest is read on demand), and docs/AI_COSTS.md links it. The refusal for a fix that does not reach its threshold no longer says "a engineChange". The `feedback.report` example is now a boss fight guide (the tilemap one was itself refused, because docs/AI_GUIDE.md has that section).
- **For game authors and AIs:** review fixes of M65.3. The fix cost the ranking shows is the one the docs state (doc 0.5, guide 2, example 4, command option 4, new command 16 hours; a test pins the sentence to the code), so a "command: worth it" means what the docs say. The hours and dollars of a verdict text round down (a saving short of its bar never reads as the bar), and the ready `rejectReason` is given only for `doc now` and `below threshold` groups, never for a command that is worth it or one that must wait for more reports. Every write of `ENGINE_FEEDBACK.json` (a report, `factoria feedback add`, the Feedback panel's Add feedback, an efficiency entry, the note of a fix check) now takes the file lock, and a report does not need `~/.factoria` to be writable: it falls back to a lock in the project's own `.factoria` folder (docs/ENGINE_FEEDBACK.md, "Sharing with the engine developer"). An efficiency entry with an unknown fix type or `this-game` is never shareable. A retrospective that is stopped while the model works returns code `cancelled` and files nothing. The feedback server accepts an `afterFix` only if it starts with a digit, like the schema and the engine say. Tests of the feedback commands use a scratch user folder instead of the real `~/.factoria`, and the byte limits of a transcript read are injectable so tests no longer write 65 MB files. The feedback server has a new D1 migration (`migrations/0003_efficiency.sql`) and a Worker change: apply them with `tools/feedback-server/deploy.sh` after the merge.
- **For game authors and AIs:** second review of M65.3: every engine function that rewrites a project's `ENGINE_FEEDBACK.json` takes the file lock for its whole read-modify-write (the engine developer's inbox files of `feedback pull` and the quarantine are written by one person's commands and are not locked), so two programs never lose each other's entry: `update_feedback_file` (`feedback.update`, the Status box, the fix check, the share verdicts), `archive_closed_feedback_file` (also the archive the editor runs when it opens a project), `set_feedback_share_file`, `delete_feedback_file` (the lock now covers the write, not only the outbox step), the sharing queue, the `shared` state, `factoria feedback init` and the Create ENGINE_FEEDBACK.json button (`create_feedback_file`). The lock is the user's `~/.factoria` lock and then the project's own `.factoria` lock, always both in that order, so a program that can write the user folder and one that cannot (a sandbox) exclude each other; the project's folder name is read as UTF-8. The editor waits 0.3 s at most for a lock held by another program and tells the person to try again. A retrospective takes the lock once for all its fix-check notes, stops writing them at the first lock failure (the result says so) and at Stop; the automatic one says "Retrospective stopped: nothing was filed.". The version of a fix must start with a digit in the engine too, and `EfficiencyLoadBudget` takes its sizes explicitly.
- **For engine developers:** `ShareLock(env, folder)`, `create_feedback_file`, `RetrospectiveResult::fixCheckProblem`, and a test where an add races status changes, share edits and archives.
- **For game authors and AIs:** third review of M65.3: the editor's UI thread never waits more than 0.3 s for a feedback lock, whatever it runs in a frame (the verdict rejection of the share tick, commands from the AI or MCP). The user's and the project's lock share one wait (0.3 s in the editor, 12 s elsewhere, in all), a home that cannot be written plus a project lock that is only busy gives the busy message, a feedback file whose folder does not exist makes no folder or `.factoria`, the share verdicts write the `declined` state and the status under one lock, and the `sent` state falls back to the user's lock when the project's folder cannot hold one. The automatic retrospective also says when the fix checks were not written because the lock stayed busy.
- **For engine developers:** two doctest cases keep the docs true: the good reports in the section pass `check_efficiency_report` against a transcript of the length they name, and the refusals quoted there are the gate's `code`, `message` and `hint` (apart from a line number in a docs path).
- **For game authors and AIs:** review fixes of the efficiency feedback and the retrospective (M65.1/M65.2). Stop now reaches the model call of a retrospective (the request is dropped, a CLI agent is killed). Transcripts are read line by line, a file over 64 MB (was 256 MB) is not read and one pass reads 256 MB in all; what is left out comes back in the result's `skipped` with the reason. The order of candidates and spans no longer depends on how a machine rounds a sum (whole-number weights, ties by id), a run's own transcripts are told apart from a run begun in the same second, numbers in transcripts and reports are clamped before they are counted, session names with accented letters are UTF-8 on Windows, a `feedback.report` for a gap takes the same file lock as the efficiency one, and `add_feedback_entry` refuses `kind: "efficiency"` (only `file_efficiency_feedback` writes one, after the gate). The Feedback panel's buttons wrap in a narrow window. (docs/AI_PROVIDERS.md, "Retrospective")
- **For engine developers:** `TextModelOptions::cancel`, `EfficiencyLoadBudget` (`load_efficiency_session` takes it), `read_efficiency_session(std::istream&, id)`, `RetrospectiveResult::skipped`.
- **For game authors and AIs:** efficiency entries are shared and checked after the fix (M65.3). An efficiency entry is shared like a gap (same modes, same lock, same outbox; `feedback share --preview` shows it) and sends its waste text cleaned like a gap's, plus a block of numbers and fixed words: the fix type, where it applies, what was measured and what the fix would save, how many stretches of runs add up, and `afterFix`. The evidence, the session ids, the AI's other words and the game's names never leave; a `this-game` entry is not shared. The numbers are cumulative: an entry that gets another span is sent again (up to 20 times) and the server keeps the installation's latest numbers instead of adding. When the engine developer fixes an efficiency entry, it records the version (`fixedIn`), the day and what one occurrence cost before (`fixBaseline`); the next `ai.retrospective` of a game on that version compares the SAME pattern with it and answers `fixChecks` (`waiting`, `gone`, `worked`, `partial`, `no_change`), records `fixCheck` on the entry, and files a pattern the fix did not remove again with `afterFix`, so a fix that saved nothing is visible. `schemas/engine-feedback.schema.json` describes the new fields and requires the efficiency ones when `kind` is `efficiency`. (docs/ENGINE_FEEDBACK.md, "Sharing an efficiency entry" and "Did the fix work?")
- **For engine developers:** `feedback pull` and `feedback collect` rank efficiency entries apart from the gaps by the total saving across installations (an installation counts once, an anonymous one half), next to the fix cost in hours, each group with a verdict (`doc now`, `command: worth it`, `command: not yet`, `engine change: below threshold (N of the $1000 / 20 hours it needs)`) and a ready reason per entry for `feedback reject`; the order is deterministic (hours, dollars, tokens, title) with rounded numbers, `--format json` has the `efficiency` array and `pull --json` the same under `efficiency`. The feedback server stores `kind`, `fix_type` and the `efficiency` block (migration `0003_efficiency.sql`, applied by `deploy.sh`; an efficiency report merges only with the same fix type and its numbers replace the stored ones). New in `fa/tooling/efficiency.h`: `efficiency_share_block`, `efficiency_clean_block`, `efficiency_fix_cost_hours`, `EfficiencyOrigin`, `EfficiencyVoice`, `EfficiencyGroup` and `rank_efficiency`; `record_fix_check` in `fa/tooling/feedback.h`; `check_efficiency_fixes` and `FixCheck` in `fa/ai/retrospective.h`. (docs/ENGINE_FEEDBACK.md, "Efficiency entries"; docs/design/FEEDBACK_SHARING.md, "Efficiency entries")
- **For game authors and AIs:** the retrospective (M65.2). `ai.retrospective {sessions?, since?, candidatesOnly?}` (CLI `factoria ai retrospective`) looks back at the project's recorded AI runs and files the efficiency entries for you. A mechanical pass with no model reads the transcripts and measures the usual waste (the same command failing with the same code, the same doc or file read again and again, tool results over 40 KB, five or more screenshots in a row, calls that waited a minute or more, long edit-run-check loops, workarounds ENGINE_FEEDBACK already records; the same transcripts always give the same numbers); then one short call of the fast role picks at most three candidates and writes them as entries, which go through the same gate as `feedback.report` (thresholds, cheapest fix, dedupe). What the gate refuses comes back in `dropped` with the reason; a lesson true only of this game becomes a project-fact proposal (`ai.savers`), written to AGENTS.md only on accept. Nothing is sent anywhere. The Feedback panel has a **Retrospective** button (it runs in the background and says what it filed) and a line that adds up what the open efficiency entries' fixes would save per game. With `savers.retrospective` on in `ai.json` (off by default; Extensions > Token savers has the switch) it also runs once after a run of 150 model calls or $3 (`retrospectiveSteps`, `retrospectiveCostUsd`), never inside another retrospective, and its cost is added to the run. (docs/AI_PROVIDERS.md, "Retrospective"; autotest section R2)
- **For engine developers:** `fa/ai/retrospective.h` (`find_retro_candidates`, `run_retrospective`, `retrospective_due`) and `propose_fact` in `fa/ai/savers.h`; `TextModelOptions::onUsage` reports what a text-model call used; the transcripts' `tool_results` lines carry `bytes`, the full size of the result the model read clipped.
- **For game authors and AIs:** efficiency feedback (M65.1). `feedback.report` (CLI `factoria feedback add --kind efficiency`) takes a second kind of entry, `kind: "efficiency"`: the engine lacked nothing, but the work took many more steps, minutes or tokens than a doc, a guide, an example or a command option could have made it. The report names the steps where the waste happened (`evidence: [{session, fromStep, toStep}]`, from `ai.session_timeline` and the transcripts in `.factoria/ai/sessions`), the `waste`, the `fixType` (`doc`, `guide`, `example`, `commandOption`, `newCommand`, `engineChange`, cheapest first), `expectedSaving {share, why}` and `appliesTo`; the engine measures the span itself (`measured`: steps, tool calls, minutes, tokens, cost; a CLI agent's tokens are estimated from bytes and the entry says so) and stores `saving` = measured x share. The gate refuses, with the JSON pointer of the field and what to do instead: no evidence or a span that is not in the session, a saving under the threshold of its fix type (one table in docs/ENGINE_FEEDBACK.md, "Efficiency feedback"; an engine change is only a candidate for triage), a command or engine change without `whyNotCheaper`, text loaded on every step that costs more than it saves (`everyStepTokens`), a "missing guide" for a doc that `docs.search` finds (unless `searched` lists words that do not find it: then the fix is that doc's title and keywords), a lesson true only for this game (a project fact) and a model, effort or limit (the user's settings). Efficiency entries merge by fix and add their measured numbers, and the same evidence reported twice is counted once. `feedback.list` and `factoria feedback list` take `kind` / `--kind`. (docs/ENGINE_FEEDBACK.md, "Efficiency feedback")
- **For engine developers:** `fa/tooling/efficiency.h` reads the transcripts of the built-in agent and of CLI agents (`read_efficiency_session`), measures a span (`measure_span`), holds the one table of thresholds (`efficiency_thresholds`, `efficiency_threshold_table`: a test compares the docs with it) and the gate (`check_efficiency_report`); `file_efficiency_feedback` runs it and writes the entry under the cross-process lock of the share files. `schemas/engine-feedback.schema.json` gains `kind` and the efficiency fields, all described.
- **For game authors and AIs:** commands for the AI settings and a CLI and MCP that resolve the project (M61.3). `ai.settings.get {scope: "resolved" | "project" | "user"}` shows each setting with where it comes from (`project`, `you`, `default`), the project's raw file with `pendingTrust` / `invalidError`, or your `ai.json`; `ai.settings.set {scope, pointer, value}` changes one value (null removes it) with the same checks as the project file (a pointer that is not a setting and a key that defines a provider, server or extension are refused, with "Did you mean"). A project file written by the command is **never accepted** by it: it applies only after the user accepts it in the editor, and the result says `needsAcceptance: true` (setting a value never writes `ai-trust.json`; removing a value from an accepted file keeps it accepted and updates its record, emptying the file forgets it). Scope `user` is the user's own call: MCP clients, the built-in agent and the CLI agents (Claude Code and Codex are started with `FACTORIA_CALLER=agent`, which a `factoria call` they run honours; an unknown value counts as `agent`) get `user_only` (ask the user to change it in the editor's AI settings window, Your defaults), `factoria call` run by the user may (an agent that can edit files could still edit `~/.factoria/ai.json` by hand: the refusal is not a sandbox); its result lists `changed: [{pointer, from, to}]`, and the editor reloads its windows when a command changed `ai.json` or the project's file. `factoria ai doctor`, `ai providers`, `ai config`, `ai run` and `ai review` find the project from the current folder or any parent (or `--project`), and `ai doctor` lists the values its settings file sets. A role the project turned off is refused by `ai_run`, `agent_delegate` and `factoria ai run` with a message that names the project's setting and how to change it. (docs/AI_PROVIDERS.md, "Per project")
- **For engine developers:** `fa/ai/project_settings.h` gains `set_user_setting` (one value of `ai.json`, checked like a project file, atomic and private) and `role_off_error` (the message and hint of a refused role, project-aware); `AiCommandOptions::aiConfigPath` points the AI commands at another `ai.json` (tests).
- **For engine developers:** `fa/core/command.h` gains `CommandCaller` (`User`, `Agent`, `Mcp`), `CommandCallerScope` and `command_caller()`: the MCP server wraps every `tools/call` and the agent session every tool call in a scope, the editor's main-thread queue hands the caller over, and a handler that must not act on an AI's say-so (`ai.settings.set` scope `user`) asks it. `CommandCallerFloor` makes `command_caller()` at least that caller on every thread of the process; `factoria` installs one when `FACTORIA_CALLER` (`kCallerEnvVar`) is set, except for `factoria editor`. `AiCommandOptions` gains `onUserConfigChanged` and `onProjectConfigChanged` (the editor reloads its AI windows and drops its caches). `ai::write_private_file` names its temporary file after the process and a counter and follows a symlinked file.
- **For game authors and AIs:** AI settings per project (M61.1). A project can change roles, limits, asset routes and sites, token savers and which of your tool servers and extensions are on, for itself, in `<project>/.factoria/ai/settings.json` (`schemas/ai-project-settings.schema.json`). Values resolve key by key and role by role: engine defaults, then your `~/.factoria/ai.json`, then the project's file. The file can only NAME the providers, tool servers and extensions your `ai.json` defines: a command, `url`, `baseUrl`, `headers`, `env`, `apiKey`, `argv`, `path` and the like are an error that names the JSON pointer and says they belong in `ai.json`; an unknown provider, server, role or extension is an error with "Did you mean". A file you did not save on this computer applies only after you accept it once (kept by file hash in `ai-trust.json`, ended by any edit; no command grants it); until then the project behaves as without it (even when the file is invalid: it has no effect, not even failing) and `factoria ai doctor` lists what the file would change or what is wrong with it. A project without the file behaves exactly as before. `factoria ai run`, `ai review`, the `ai.*` commands (asset commands, `skills.*`) and the editor's chats, reviews and image routes use the resolved config; `ai doctor`, `ai providers` and `ai config` take `--project`. (docs/AI_PROVIDERS.md, "Per project")
- **Editor:** the AI settings window and the Roles window edit the open project's AI settings (M61.2). The title says "This project: <name>" (or "Your defaults" with no project open, where the window edits `ai.json` as before) and every row of the Roles and Assets tabs says whether its value is set by this project, comes from your defaults or is built in. **Reset** goes per row and per tab (**Reset tab to my defaults**), **Save as my defaults** writes the values to your `ai.json` and Save writes only what differs into `<project>/.factoria/ai/settings.json`; the next message and the next asset use it at once. A project file you have not accepted shows what it would change with **Accept**, **Ignore** and **Delete the file** (it asks first and forgets the acceptance; Save after Ignore asks before it replaces the file and keeps it as `.factoria/ai/settings.replaced.json`); an invalid one shows its error and no Accept. Switching project reloads roles and asset settings. Tool servers, extensions and token savers stay your own. (docs/AI_PROVIDERS.md, "This project's settings in the window"; autotest section Q2)
- **For engine developers:** `fa/ai/project_settings.h`: `resolve_ai_config` (the resolved `AiConfig` plus the source of every value, `default`/`you`/`project`, and what an unaccepted file would change), `load_resolved_config`, `settings_view`, `validate_project_settings`, `resolve_ai_config_over` (the same on the caller's in-memory config, for the editor), the writer `save_project_settings` (keeps only what differs from the inherited value, removes an empty file; records the acceptance of what it writes only with `recordTrust`, which no command may pass), `project_overrides_from`, `reset_project_setting` and `accept_project_settings`. The trust lives in `ai-trust.json` as its own `aiSettings` record (`trust_project_ai_settings`, `project_ai_settings_trusted` in `fa/ai/extensions.h`). `ai.plugin_install` still starts from the user's file, so a project's switches are never written into `ai.json`.
- **Editor:** polish of the per-project AI settings (M61.2, p23). Unsaved edits of the AI settings window survive a reload: when `ai.json` or the project's file changes under it (an AI's `ai.settings.set`, an MCP client, another program) or you press Accept, the rows you changed (roles, asset routes, site lists, typed keys and programs) stay as typed and the other rows show the new values, with a notice. The orange "waiting for approval" box has a maximum height and scrolls, so the tabs stay reachable at 1024x642. Save over an ignored file makes its `settings.replaced.json` copy before it writes anything (ai.json included) with the engine's own file functions. A failure of the second file of Save as my defaults, or of the second step of Reset tab to my defaults, says what was already written. The Save as my defaults tooltips say it writes every value you see. A resolution that was in flight when the project's settings were invalidated no longer stores its answer.
- **For game authors and AIs:** `ai.settings.set` with `value` null for a setting the file did not hold returns `removed: false` and a hint "Nothing changed ..." (M61.3); `ai.run` says in its description that the project's AI settings apply.
- **Feedback sharing:** last review round of the lock (M61.4, M65.3). A lock file that exists but reads empty (another program is writing it) is read again before it is taken for someone else's; the file moved aside by a takeover is checked for staleness again before it is deleted, so a fresh lock is put back; the lock's messages on Windows add the system's error text; `FeedbackFileLock` reads the project's folder the way the feedback file is read and written (a non-ASCII folder works); a failed relock after a 5xx or 429 keeps the attempt count and the next attempt in memory; the editor's once-a-second tick keeps the folder checks for 30 s (`ShareKeyCache`); the send failure text under "always" says the message still goes out with the next pass; the autotest waits up to 2 s for a lock instead of 0.3 s. FEEDBACK_SHARING.md no longer promises that races are impossible.
- **For engine developers:** `ShareKeyCache` and `ShareKeyCacheScope` (`fa/tooling/feedback_share.h`), `ai_roles_keep_edits`, `ai_routes_keep_edits`, `ai_sources_keep_edits` (`tools/editor/src/ai_project_edit.h`), `Editor::ai_settings_reload_keeping_edits`, `ui_lock_wait_sec` / `set_ui_lock_wait_sec`. The editor's AI settings tests no longer touch the real `~/.factoria`.
- **Feedback sharing per project:** the mode in `feedback-sharing.json` is now your default, and a project can have its own (`never` for a game under NDA, `always` for one you want to share, `ask`, or follow the default). `factoria feedback sharing <mode> --project <dir>` sets it (`default` or `--clear` removes it); `factoria feedback sharing` shows your default and the project's effective mode with its source. The choice is kept in your own settings file under `projects`, keyed by the project folder's path, never inside the project, so a copied project does not inherit the choice and follows your default; moving the folder drops it back to the default (the key is UTF-8, case-insensitive on Windows and on volumes that ignore case, and two keys for one folder resolve to the most restrictive mode with a warning). `--project <path>` finds the project from any folder inside it and says which it used; `--clear` with a mode is a usage error. Each outbox item stores its project's key when it is queued: a default of `always` does not send what a project set to `ask` or `never` holds, a default of `never` does not drop what a project set to `always` holds, and items written by an older version wait until you decide. Changing a project's mode moves its items (ask: back to waiting; never: dropped, entries `skipped`), the sending re-reads the modes before each batch, and `feedback share --yes` only confirms the items of the project you are in. Queueing, sending, the outbox, `feedback.share_preview`, `feedback.share_status` (new `default`, `project`, `outbox.blocked`) and the answer of `feedback.report` use the project's mode, and a `never` project's queued items are not sent. Editor: Feedback Settings has **Default** and **This project: <name>** (Follow default / Always / Ask / Never). (docs/ENGINE_FEEDBACK.md, "One project can choose differently")
- **Feedback sharing, safer per project:** the settings and the outbox are changed under a lock file (`feedback-share.lock`, taken over after 10 s when its program died, waited for at most 12 s) so the editor, the terminal and the MCP server cannot undo each other; the network request of a flush stays outside it and a flush applies only its own results. Each queued item records `confirmedBy` (`always` or `user`) and an item queued by `always` is sent only while its project is still on `always`, otherwise it goes back to waiting (a settings file edited by hand can no longer send what a project asked about). Choosing `always` also answers yes for what waited under the default; removing a project's own choice, and queueing again, never release what waits (the CLI and the editor say so). A stored project key is found through another spelling of the folder (case, NFC/NFD, symlink); a folder that cannot be resolved reads as `ask`, not as the default. `factoria feedback share` in a project without ENGINE_FEEDBACK.json, or outside a project, says so and sends nothing; with sharing off it only says so. After choosing `never` the editor and the CLI note that an upload already in progress finishes. `feedback.share_status` paths and the outbox `file` are UTF-8. The lock is safer: its file holds an owner token and is deleted only by its owner, a takeover of a dead holder's lock (not refreshed for 10 s, or dated in the future) is one waiter at a time, a long change keeps it fresh, and a Windows "access denied" on creating it is waited out as busy. The editor never waits more than 0.3 s for it (it tells you, and the tick retries); skipping, dropping, confirming and discarding entries (`feedback.delete`, `feedback discard`) return an error and change nothing when it is busy, and a skipped entry is marked only after its item left the outbox. A request already sent is never sent twice by one program when the lock stays busy afterwards, an outbox item whose project folder is gone reads as `ask`, a project's mode reaches its items under any spelling of the folder, and Reset id runs under the lock. (docs/design/FEEDBACK_SHARING.md)
- **For game authors and AIs (polish of M62 and M64):** effect documents and feel: `vfx.play` takes `scale` (and `Vfx.scale` is documented as the whole effect's size), `vfx.list` counts placed autoplay `Vfx` entities as the effects they are, `vfx.filmstrip` and `vfx.budget` say what is wrong with a 3D effect that has no position or a missing part, and a part keeps its identity in the budget when a duration-0 effect detaches its children (`VfxChild.origin`). `project.validate` follows nested prefab instances when it looks for a prefab that never ends itself, and accepts a `.qoa` twin of a feel sound. A sprite clip's frame events are handled in the frame whose frame is shown (the Animator runs once early in the frame), the editor's edit mode fires none, a feel `spawn` that fails removes what it had already created, and a queue that is full says so: `feel_spawn` returns an error and a full sound queue warns once. A feel sound that cannot play is not tried again in the scene.
- **For game authors and AIs (polish of M62.3):** `assets.animate_svg` frees the frames of each layer when its sheet is built, refuses a bake whose layers would need over 1 GB of memory before drawing anything, encodes every sheet before it writes the first (a failed write takes back the sheets this call made and names the others), warns when a layered module never reads `layer`, and deletes the sheets of an earlier bake of the same `path` with other layers (only those its recipe made, with their entries). The Animation panel adds game feel actions to a new 3D event (the feel box of the new-event row; a nameless event runs only the actions), and the event popup of the 2D panel keeps its own error line.
- **For engine developers (polish):** `Renderer::advance_animators(world, dt)` (the sprite animators move before the UI and scripts; the render pass moves those it did not), `resolve_audio_path` (`fa/audio/analysis.h`, the path or its `.qoa` twin), `VfxChild::origin`, `FeelState::failedSounds`, `SpriteAnimator::advancedPass` (runtime only). Undo and Redo in the Particles panel are refused, with the Reload prompt, when the file was changed outside the editor.
- **For game authors and AIs (polish, ember-descent FB-0001 and FB-0003):** `tilemap.generate` honours `constraints.counts` with a `max`: a tile that reaches its maximum is banned from the open cells (with propagation) and an attempt whose decided cells already pass a maximum ends early, so a level with at most two torches is made with at most two instead of failing the check. New `constraints.place` ([{tile, count, where: "farthest" | "nearest" | "random", from, on}]) puts marker tiles after the solve by walking distance over the walkable cells (the stairs at the farthest point from the player), and a glyph that only the sample's legend names can be placed this way; the result lists `constraints.placed` ({tile, where, count, at, distances, from}). A wrong tile, `where` or `from` is an error with a "did you mean". `job.progress` of `tilemap.generate_start` follows the solver inside an attempt and never goes down when an attempt restarts (the first attempt covers 0 to 0.8, each later one a quarter of what is left, 1 only when done). Ember Descent places its player and stairs with `constraints.place` and drops `scripts/floor_plan.js`.
- **For game authors:** Ember Descent places its entrance and stairs with `constraints.place` instead of its own script, and a floor that will not grow within its attempts is dug again from a seed drawn from it (up to 3 times) instead of ending the run.
- **For engine developers (polish):** `wfc::Generator` takes a `GridFinish` step that runs chunked on the finished grid before the counts and the check (the placement of markers), and `progress()` is monotonic across attempts.
- **For game authors and AIs (polish, gem-roller FB-0015):** `vfx.filmstrip` and `vfx.review` default `position` in a 3D game to the point 5 m in front of the main 3D camera on its view axis (the middle of the view is the camera itself there, so the effect used to play inside it and show nothing); the result says so in `position`, `positionDefault` and `positionNote`. `vfx.budget` measures the overdraw of a 3D emitter by projecting its quads through the project's main camera (perspective or orthographic) with the effect 5 m in front of it, and returns `camera` ({used, projection, distance, fov | height}); with no camera in the scene it says so instead of reporting a number that was never measured. `fa/scene/vfx_budget.h` gained `VfxBudgetCamera`, `VfxBudgetOptions::camera` and `cameraDistance`, and `VfxBudget::camera3d`.
- **For game authors and AIs (polish, sky-hopper FB-0028):** `assets.animate_svg` takes `prefab` (with `layers`): a path, or an object {path, name, tags, size, layers, pixelArt, overwrite}. It writes the parent entity with one child per layer (Back below, Front above, Light additive), each a Sprite on that layer's sheet and a SpriteAnimator on the shared clip, so a layered effect is one call. An existing prefab is never replaced unless `prefab.overwrite` is true (the call fails before baking, with a hint). Sky Hopper's `coin_sparkle` prefab is exactly what the command writes.
- **For game authors and AIs (polish, sky-hopper FB-0029):** `assets.animate_svg` warns when the sheet's width or height is not a multiple of 4 and `factoria.json` lists android or ios (GPU compression needs it), and names the `padding` (and the frame size) that gives a multiple of 4: 96 px frames with padding 1 make 294 x 294, padding 2 makes 300 x 300.

## 0.16.1

FactorIA 0.16.1 makes engine feedback trustworthy: feedback that claims a gap the engine does not have is caught, rejected with a reason the person can read, and can be deleted. A weak model filed "No one-way platforms" although `Collider2D.oneWay` exists, because it copied the example in the `feedback.report` docs.

### Changes

- **For game authors and AIs:** `feedback.report` (MCP, CLI `feedback add`, the editor's Add feedback window) first checks whether the engine already has what the report says is missing, against the reflected components and fields, the commands and the scripting API. A report whose own words tie the claim to an existing name ("No one-way platforms") is refused with what exists, its doc string, where it is documented and "if it does not work as documented, file a bug and say what you tried". A bug report and a request for an extra option on an existing component are accepted. New command `feedback.check` runs the check on its own (and over the open entries); `factoria validate` warns about open entries that fail it. The example in the docs and templates is now an invented gap, "No fluid simulation", marked as an example. (docs/ENGINE_FEEDBACK.md, "The check before filing")
- New entry status `rejected` with `statusReason` (plain text, up to 500 characters) and `statusBy` (`engine`, `user`, `developer`). The engine rejects open entries that fail the check when the editor opens the project (a reopened one is never rejected again); a person picks `rejected` in the editor, which asks for the reason. A rejected entry is archived like a closed one. New command `feedback.delete` (CLI `factoria feedback discard`) removes a closed entry from the file or the archive; ids are never reused (`nextId`). (docs/ENGINE_FEEDBACK.md, "Rejected entries")
- **Editor:** the Engine Feedback panel has a **closed** checkbox that lists the archive, shows the reason of a closed entry (a `*` marker and a tooltip) and opens an entry in its own window on a double click (movable, resizable, every field, wrapped and scrollable, with the status, Copy and Delete actions; several windows at once). Delete asks first. (docs/EDITOR.md, "Rejected entries")
- **Engine developers:** the feedback server keeps a verdict and a reason per report (migration `0002_verdicts.sql`; `deploy.sh` applies it) with `POST /v1/admin/reject` and `/v1/admin/unreject`, and `POST /v1/verdicts` answers an installation only about its own reports. The editor asks every 30 minutes (and `factoria feedback share --verdicts` / `feedback.verdicts` at once); a rejected report closes the entry with the developers' reason (`shared.status: "declined"`). An old server answers 404 and nothing changes; an old engine never asks. New CLI, all non-interactive: `feedback reject` (shareIds with `--reason`, `--file` batch, `--suggested`, `--quarantined`), `feedback unreject`, `feedback keep`; `feedback pull` marks reports that fail the check with a ready reason. The triage loop is in docs/ENGINE_FEEDBACK.md and CLAUDE.md. (tools/feedback-server/README.md)
- **Engine developers:** agent work on this repository adds a reviewer role (`.claude/agents/reviewer.md`, sonnet at high effort) that reads each worker's diff with fresh context before it is merged, for what the orchestrator's machine does not exercise; workers get high effort for L packages and for packages that touch core headers, platform, render, timing or file code, or the editor autotest (CLAUDE.md, "Models for agent work").

## 0.16.0

FactorIA 0.16.0 (M51-M60) puts the art, audio and 3D tools inside the engine, made for an AI that cannot see or hear: everything is a JSON document the engine bakes, the same bytes on every machine, with no external program needed. M51 gives the AI eyes and ears on what it makes (`assets.check_art`, contact sheets, previews in a running scene, spectrograms and a mix check). M52-M54 are the picture tools: layered image documents with one CPU compositor, pixel art on indexed layers with palettes, animation frames and tiles, and vector illustration. M55 is a sound-design synthesizer (`*.sfx.json` patches rendered to WAV), and M56 makes music from data: songs, a library of synthesized instruments and kits, a mixer with a mastering limiter and adaptive playback. M57-M58 model in 3D by recipe (primitives, modifiers, SDF shapes, booleans), unwrap UVs, texture and bake, decimate, make LODs and collision hulls, and clean up imported meshes. M59 rigs, skins and animates them (templates, automatic weights, 3D clips, generators, IK, retargeting) and gives the Animation panel a 3D mode. M60 proves it: Kindlewatch, a complete 3D game whose every picture, model, sound and song was made with these commands.

### Changes

- **For engine developers:** `fa/core/crash.h` reads the stack of a running thread: `watch_thread_stack`, `watched_thread_stack` (Windows x64: the thread suspended and unwound; Linux and macOS: asked with SIGUSR2) and `current_thread_stack`, and `report_runtime_checks_without_dialogs` makes a failed MSVC Debug check print its message and stack and end the process with code 3 instead of a modal dialog (and on Windows an unhandled access violation or stack overflow print its name, address and stack instead of a silent exit). The editor autotest uses both: its watchdog prints the UI thread's stack before it ends a frozen run (exit 86), and a Debug assertion no longer leaves a dialog on the desktop until the watchdog fires. Fixed for other platforms on the way: V-HACD hulls are the same with every C++ standard library (its header is patched at configure time: an ordered hull map and tie-breaks in its merge queue), the doc tests read Markdown checked out with CRLF, a music test no longer reads a destroyed temporary on MSVC, and the Music panel tabs no longer keep references into the song an edit just replaced (MSVC Debug ended the editor there).
- **For game authors:** a sixth reference game, `examples/kindlewatch` (M60), made only with the engine's own commands (M51-M59): a 3D night-watch game (hold a campfire against three nights of wolves) whose every picture, model, rigged and animated character, sound and song has an engine recipe in `assets.json` and no provider call or imported file behind it. A test (`tests/assets.test.js`) fails if an asset has no engine recipe, is marked as AI or imported, or has a baked output older than its document. It has a title, a gameplay loop with an alpha boss, win and lose, a HUD, a layered `MusicPlayer` steered by a director script, keyboard, gamepad and touch controls, 21 tests including a bot that wins the whole game, an input replay and a perf budget. Its `ENGINE_FEEDBACK.json` records the gaps these tools left (21 entries, the first of them the memory the music player keeps). Fixed on the way: `schemas/assets.schema.json` rejected the provenance that `model.game_ready` and `model.bake` write (`kind` `"prefab"` and the `extras` list), so a project made only with the documented model commands failed `factoria validate`.
- **For game authors:** the editor's Animation panel edits 3D bone clips (M59.4). Switch it to **3D bone clips** (or double-click a 3D `*.anim.json`): the rigged model is posed in a software-rendered viewport (headless-capable), you pick a bone in the list or the view and turn it with a rotation gizmo (arrows for the root) or drag an IK handle (two-bone with a pole, look-at), and the result is keyed in the dopesheet as ONE undo step per drag. The dopesheet moves, deletes and eases keys, edits clip events, and **Mirror pose**, **Generate a clip**, **Retarget to another rig**, a multi-angle **Filmstrip** and the skin **Weights** sheet are buttons for the commands behind them. New commands: `anim3d.move_keys`, `anim3d.remove_keys`, `anim3d.set_interp`, `anim3d.set_clip`, `anim3d.add_event` / `set_event` / `remove_event`, `anim3d.mirror_pose`, `ik3d.key` and `anim3d.restore` (the `undo` every writing `anim3d.*` command returns); `anim3d.preview` takes `yaws` for several angles. Gem Roller gets a scout: a humanoid made of primitives, rigged with automatic weights and animated with generated walk and idle clips, all with the engine (docs/ANIMATION.md, docs/EDITOR.md).
- **For engine developers:** `tools/editor/src/anim3d_model.{h,cpp}` (the panel's logic with no window: keys, edits as commands, gizmo and IK maths), `anim3d_ui.h`, `anim3d_panel.cpp` (the panel); editor autotest section O3.
- **For game authors:** clips, IK and retargeting for rigged 3D models (M59.3). The `*.anim.json` of a skinned `.rig.glb` can now drive its bones (`format` `factoria.anim3d/1`, `schemas/anim3d.schema.json`): per-bone rotation, translation and scale tracks with the keys, easings and events of the 2D clips, plus `contacts` (when a foot is on the ground) and `groundSpeed`. An `Animator` with a glTF model plays them from `clips` next to the glTF's own animations (cross-fades, states, events), the same on every platform. The new `IK3D` component adds three solvers after the animation: `twoBone` (arm or leg with a pole), `lookAt` (limits and turn speed) and `foot` (ground rays, the pelvis lowering to fit, the foot tilted to the normal). `anim3d.generate` writes walk, run, trot, gallop, idle, swing and hit clips from the rig's proportions with planted feet (`anim3d.generators` lists the parameters), `anim3d.retarget` carries a clip to another rig by the (role, index, side) of its bones and keeps the feet planted, `anim3d.preview` draws a filmstrip of the clip on the model with the software renderer, `anim3d.create`, `anim3d.set_keys`, `anim3d.remove_track` and `anim3d.info` edit and read a clip, and `ik3d.check` and `ik3d.solve` try a solver offline. `project.validate` checks the clips and the solvers against the model's bones. The joints of a baked rig now carry `axis` and `length` in their extras. See docs/ANIMATION.md ("3D bone clips", "3D IK", "Generators", "Retargeting") and docs/RIGGING.md.
- **For engine developers:** `fa/scene/anim3d.h` (`Anim3DClip`, `parse_anim3d`, `load_anim3d`, `bind_anim3d`, `sample_anim3d`, `anim3d_to_anim_clip`), `anim3d_gen.h` (`generate_anim3d`), `anim3d_retarget.h` (`retarget_anim3d`), `ik3d.h` (`solve_two_bone`, `solve_look_at`, `update_ik3d`, `ik3d_check_solvers`, `ik3d_solve_once`) and `rig3d.h` (`Rig3D`); `Pose` moved to `skeleton.h`, `AnimatorRuntime` gained `extraClips` and `pose`, and `engine.cpp` runs `update_ik3d` after `update_ik2d` with a ground ray through `physics.raycast3d`.
- **For game authors:** skeletons for 3D models (M59.1). A rig document `*.rig.json` fits a template (`humanoid`, `quadruped`, `bird`, `tail`, `chain` or `generic`, with options such as the spine, neck and tail bone counts or the segments of a chain) to a model document by the names of its parts and by landmarks measured on the mesh, and `rig.bake` saves the model as a skinned `.glb`: one glTF skin whose joints are the bones, with inverse bind matrices that make it draw in its rest pose. All templates share one canonical bone naming (`root`, `spine_1`, `arm_upper_l`, `thigh_r`, `tail_2`...: role, index, side) that retargeting between them will use. `rig.templates` lists the templates and their bones, `rig.create {path, model, template}` writes, fits and bakes, `rig.fit {path, parts?, landmarks?, options?, strict?}` changes what the fit is told and shows where every joint came from (a part, the geometry or an estimate from proportions; `strict` makes an estimate an error), `rig.info` checks a document and lists every issue with its fix, and `rig.bake` bakes the stale ones (`assets.regenerate`, `project.validate` and `factoria export` know them). Its vertices are bound to the bones by automatic skin weights (M59.2, next entry). See docs/RIGGING.md.
- **For engine developers:** `fa/scene/rig_doc.h` (`RigDoc`, `parse_rig_doc`, `rig_templates`, `rig_doc_schema`, `kRigMaxBones`), `fa/scene/rig_fit.h` (`fit_rig`, `RigFit`, `RigBoneFit`, `RigSource`, `rig_template_bones`, `rig_rigid_binding`), `fa/scene/rig_glb.h` (`rig_to_glb`) and `fa/tooling/rig_bake.h` (`rig_evaluate`, `bake_rig_document`, `rig_bake_status`, `bake_rig_documents_if_needed`).
- **For game authors:** skin weights for rigged 3D models (M59.2). The `.glb` of a rig document now carries up to four normalised bone weights per vertex, computed from the document each time so a re-bake gives the same bytes. The default is bone heat diffusion on the surface of the model (smooth, local weights; the mesh is welded for the solve so primitives with seams, hard edges and SDF creatures work), with a voxel binding for meshes the solve cannot handle and a rigid binding per part for robot-style models (a `generic` rig is rigid per part by default). A new `skin` section of `*.rig.json` holds the method per part, the settings (`maxInfluences`, `smooth`, `maxHops`, `locality`) and a list of edits, so weights are part of the recipe. `skin3d.auto` chooses the method, `skin3d.set`, `add`, `smooth`, `normalize`, `limit` and `mirror` (`_l` to `_r`) edit the weights of a part or of a face selection chosen by meaning (the queries of `model.select`), `skin3d.clear` removes edits and `skin3d.info` shows the settings and the quality of the weights (unweighted vertices, most influences, blends across far bones, idle bones, warnings, also in the answers of `rig.create`, `rig.bake` and every edit). `skin3d.preview` draws the weights with the software renderer of `model.preview`: a heat map of one bone or one colour per bone, and with `pose` a second row with the model bent at a bone by linear blend skinning, to see how the skin deforms. See "Skin weights" in docs/RIGGING.md.
- **For engine developers:** `fa/scene/rig_skin.h` (`compute_rig_skin`, `RigWeights`, `RigSkinReport`, `rig_skin_pose`, `rig_bone_hops`), `fa/scene/rig_skin_doc.h` (`RigSkinSettings`, `RigSkinEdit`, `rig_skin_schema`); `RigDoc::skin` replaces `binding`; `rig_to_glb` takes optional `RigWeights` (none = the old rigid binding); `rig_evaluate` takes `withSkin`; `RigBakeResult::skin` is the quality report.
- **For game authors:** texturing 3D models. A model document takes a `texturing` section (`model.texture` edits it) that bakes the model's colour into the UV atlas on the CPU: materials with a tiling `texture` are projected triplanar (`mapping: "triplanar"`, `textureScale` in metres, `textureOffset`, `sharpness`, `tint`), vertex colours are painted in, ambient occlusion is multiplied in (`ao`), wear is painted from baked masks (`wear`: worn edges, dirt in cavities, dust on top, from curvature, occlusion and thickness maps with noise) and decals are projected on parts or selections (`model.decal`). The layers are written as pictures and composed in an image document `<model>.texture.image.json` (M52) with a blank `paint` layer: open it, paint on it, and a re-bake renews only the layers named `model: ...` and keeps yours, with a warning when the UV layout changed under painted layers. Its picture is the base colour texture of the baked `.glb` and of every LOD, and the model is stale when the image document, a decal image or a material texture changes. A `vertexColors` section (`model.palette`) colours a low-poly model with no texture: the style palette or your colours, a colour or a gradient per part, flat per-triangle colours and a seeded variation. `model.bake_maps` measures the occlusion, curvature and thickness maps and returns them as a picture; `texturing.maps.write` keeps them as PNGs. All of it is deterministic and needs no other program. See "Texturing" in docs/MODELING.md.
- **For engine developers:** `fa/scene/model_texture.h` (`parse_model_texturing`, `parse_model_vertex_colors`, `model_apply_vertex_colors`, `bake_model_textures`, `bake_model_maps`, `compute_model_map`, `ModelMaterialTexturing`), `ModelDoc::texturing` / `vertexColors`, and in `tools/common/src/model_texture_bake.h` the layered-document writer. `ModelBakeResult` gained `texture` and `warnings`; a recipe may carry `context.stylePalette`.
- **For game authors:** `model.import_clean {source}` turns a generated or downloaded mesh (`.glb`, `.gltf`, `.obj`) into a game-ready model document in one call: it welds vertices, removes floating pieces, fixes the winding, scales to a `height`, a `reference` model or `"human"` (1.8 m), moves the origin to the ground centre, optionally remeshes through the SDF path (`remesh`), decimates to the platform budget, unwraps with `model_uv` and keeps materials and textures. The result is `<name>_clean.model.json` with a new `mesh` node (a model operation that reads a project `.glb`/`.gltf`, so modifiers, selections, `uv` and `gameReady` apply to it) baked like any model. The report says what went: pieces removed, triangles before and after, the scale factor, non-manifold edges fixed, with warnings that name the fix. See "Cleaning an imported mesh" in docs/MODELING.md.
- **For engine developers:** `fa/scene/model_import_clean.h` (`model_import_clean`, `model_remesh_mesh`, `model_clean_report_json`), `fa/scene/gltf_mesh.h` (`read_gltf_mesh`) and a `Volume` shape in `ModelSdf`.
- **For game authors:** model edits on selections chosen by meaning, not by index. `extrude_faces`, `inset_faces`, `loop_cut`, `bevel_edges`, `delete_faces` and `assign_faces` in `*.model.json` take a query: faces by `normal` direction, `part`, `box` / `sphere` / `halfspace` (node or model space), `top` / `bottom`, combined with `and` / `or` / `not` / `grow` / `shrink`; edges by `border` of a face selection, `sharp` over an angle, `between_parts` and `loop` round an axis at a height or ratio. Parts are kept and the new faces take `newPart` or the part they grew from; the query is re-evaluated on every build, so it keeps choosing the same faces when a segment count or size changes upstream. `model.select {path, node, faces | edges}` tries a query and answers the count, area or length, bounds and parts, with a warning that says what to change when nothing matched; `model.info` lists the queries and what each edit node selected. See "Selections and edits" in docs/MODELING.md.
- **For engine developers:** `fa/scene/model_select.h` (`model_queries`, `check_model_selection`, `model_select_report`, `model_apply_edit`), `ModelEditContext`, `ModelEvalOptions::probe`, `ModelBuild::edits` and `ModelBevelParams::edgeFilter`.
- **For game authors:** game-ready 3D models. A model document takes a `gameReady` object (`model.game_ready` edits it): `origin` (keep, center, bottom, bottom_center), `merge` (submeshes by material, welded vertices), up to four `lods` (by `ratio`, `triangles` or `error`, made with meshoptimizer with each part's border locked) and a `collider` (box, sphere, capsule, convex hull, or a V-HACD convex decomposition of a concave model). A bake writes `<name>.lodN.glb`, the collider hull `.glb` files and a `<name>.prefab.json` wiring them to a `MeshRenderer` and `Collider3D`, and reports the triangles of every LOD against the desktop, mobile and web budgets. The settings also apply to `sdf` results. `MeshRenderer.lods` (`[{mesh, distance}]`) makes the renderer draw a cheaper mesh farther away.
- **For engine developers:** `fa/scene/model_game_ready.h` (`make_game_ready`, `model_make_lod`, `model_fit_collider`, `model_merge_by_material`, `model_origin_offset`, budgets, `parse_game_ready`), `fa/scene/lod.h` (`lod_mesh`), `fa/scene/model_decimate.h` (`model_simplify`; `model_decimate` now wraps it, so the SDF mesher and the LODs share one meshoptimizer-based simplifier), and `model_game_ready_files` in `fa/tooling/model_bake.h`. meshoptimizer and V-HACD are vendored in `external/`.
- **For game authors:** eyes for 3D models. `model.preview {path | document, views?, yaw?, pitch?, cell?, mode?, figure?, ground?, part?, out?}` draws a turntable sheet of 4 to 8 views (shaded, wireframe or both) beside a 1.8 m reference figure on a grid, with the triangle count, size and parts in the header, and returns the PNG; `model.check {path | document, expectedHeight?, tolerance?, platforms?, ignore?, samples?}` measures the mesh for a wrong scale or origin, inside-out pieces, inconsistent winding, flipped normals, open and non-manifold edges, degenerate triangles and triangles or submeshes over the platform budgets (the table `model.game_ready` uses), each finding with where, what and how to fix, as JSON. Both build in memory with a software renderer, so they need no GPU and no window (docs/MODELING.md, "Looking at a model").
- **For game authors:** the editor's Model panel (View > Model, or a double click on a `*.model.json`): the operation tree with an enabled box per node, Add and Remove, a live viewport of the evaluated mesh (orbit, zoom, shaded or wire, the 1.8 m figure, the picked node's part in orange), the picked node's parameters as sliders, checkboxes and combos from the catalog, a Check button, and Save, which bakes. Every edit is a `model.edit` call and one undo step, a drag is one step, and the file is read again when it changes on disk. Gem Roller's gem is now a lathe model document baked to its `.glb`.
- **For engine developers:** `fa/scene/model_check.h` (`check_model_mesh`, `model_check_kinds`, `kModelReferenceHeight`) and `fa/tooling/model_view.h` (`render_model_view`, the software rasterizer shared by `model.preview` and the editor viewport). The editor's `ModelerModel` (`tools/editor/src/modeler_model.h`) holds the panel's logic without ImGui, with its own tests, and autotest section N3 (in the shortest shard) drives the panel.
- **For game authors:** the editor's Music panel (View > Music, or a double click on a `*.song.json`): a piano roll (draw, move, resize and delete notes with the mouse, velocity lane, snap, scale highlight, insert a chord, arpeggio and bass line from the progression), a drum grid for kit tracks, the arrangement (sections with repeats, order and play, what each track plays in each section, layers by intensity) and a mixer (volume, pan, mute, solo, sends and effects of each track, buses, the master's limiter and loudness, Measure loudness). Every edit runs the command an AI would call and is one step of Undo; Play, Play section, Loop and the intensity slider use the game's own player; Save + bake runs `music.render`. docs/EDITOR.md, "Music panel"; docs/MUSIC.md, "The Music panel".
- **For game authors:** `music.notes {path, track, pattern}` lists a pattern's notes as a piano roll sees them, and `music.edit set_pattern` accepts that list in `notes` (a pattern written from a list is normalized to plain note text with starts and ends rounded to 40 ticks; docs/MUSIC.md, "Notes as a list").
- **For game authors:** adaptive music in Neon Swarm: `assets/music/score.song.json` with three layers, played by a `MusicPlayer`, intensity following the danger, a section change per wave and stingers for the wave horn and a hit; tests in its `neon.test.js`.
- **For game authors:** a `*.song.json` that changes on disk hot-reloads in a running game (the players that play it crossfade to the new render at the next beat), `game.setDevice` in a script now reaches `MusicPlayer.mode: "auto"` (a running player re-resolves it), and a live render honours the master's `loudness: "style"` like the baked one (docs/MUSIC.md, "Live and stems").
- **For engine developers:** `fa/audio/song.h` has `song_roll_notes` and `song_write_note_text`; `Audio::reload_song`; `Engine::device_overridden`. The editor's `MusicModel` (`tools/editor/src/music_model.h`) holds the panel's logic without ImGui, with its own tests, and autotest section M3 drives the panel.
- **For game authors:** pixel-art tools in the editor's Image panel. A pixel grid (from 800% zoom, stronger lines every 8 pixels or at the tile size), a **Tiled** 3 x 3 preview (a tile document opens with it on) and, for a tileset document, a terrain preview painted with the engine's autotile rules; a palette bar with a primary colour (left button) and a secondary colour (right button, X swaps) and buttons to add, edit, reorder and remove colours; a frame timeline to add, duplicate, delete, reorder and time frames, a Play preview and an onion skin with a configurable number of frames each side and opacity. New commands `image.palette.move {path, from, to}` and `image.palette.remove {path, index, replaceWith?}` reorder or remove a palette colour while the pixels follow it (or take another colour). Every edit is one undo step. (docs/EDITOR.md, docs/IMAGES.md)
- **For game authors:** pictures from an image provider inside image documents. `image.inpaint {path, selection, prompt, layer?, frame?, seed?, ...}` sends the picture and the selection (as the mask) to a provider that can inpaint and adds the answer as a `provider` layer whose mask is the selection, feather included; `image.generate_layer {path, prompt, selection?, size?, placement?, transparent?, ...}` adds a generated picture the same way. Both record the provenance (provider, model, prompt, seed, references, license), take `dryRun` (what would be sent and what it may cost), reduce the result to the document's palette when it has one, and never regenerate a layer by themselves. Without a provider, or with one that cannot inpaint, they fail with `no_provider` and an error that says how to configure one and the offline commands. `image.layer.add_provider` adds a layer from a PNG you already have. `asset-command` providers can inpaint with the new `{input}` and `{mask}` placeholders, the `openai` provider uses `/images/edits`, and `fake` paints a placeholder only inside the mask. The Image panel gains Inpaint selection... and Generate layer... (a prompt, a Cancel button, one undo step; off with an explanation when no provider can do it). The gem-roller example now keeps its two textures as image documents baked to the PNGs it already used. (docs/IMAGES.md, docs/AI_PROVIDERS.md)
- **For game authors:** `music.render {path, out?, format?, sampleRate?, seed?, loop?, stems?, overwrite?}` renders a song for a game: the whole song as a WAV or OGG, its loop points (the `loop` sections with their repeats, the outro tail folded onto the loop start; written to the WAV `smpl` chunk and to `import.loopStart`/`loopEnd`) and one stem file per layer, track or bus, `name.stem.<layer>.wav`, that add up to the mix (a few LSB when the buses and master are linear). A song declares `layers` (`music.edit` `set_layers`). The mix and its stems share one recipe whose inputs are the song, its `.sfx.json` and `.sf2` files and the style's music loudness, so a change to any of them makes them stale and `assets.regenerate` renders the group; running it again updates in place. The stems' data for the in-game player is in each entry's `import.music`. (docs/MUSIC.md)
- **For game authors:** adaptive music at runtime. A `MusicPlayer` component plays a song document in a game: its layers (stems) fade in and out with `intensity` (0..1), `goToSection` and crossfades to another song wait for the next beat, bar or section end (`quantize`) and land on that exact audio frame, a stinger (an audio clip, or a section of the song) can dip the music while it plays, and beats, bars and sections reach scripts as `music.beat`, `music.bar`, `music.section`, `music.loop`, `music.ended`, `music.stinger`, `music.crossfade` and `music.ready` events. `mode` is `live` (the song is rendered from the document when the player starts; no extra files), `stems` (the files `music.render` wrote) or `auto` (stems on low-end phones, tablets and the web). A script drives it with `entity.music` (`play`, `stop`, `setIntensity`, `goToSection`, `playStinger`, `crossfadeTo`, `on`, and `bar`, `beat`, `section`, `status`); tools use `audio.music_state` and `audio.music`. The musical clock is the mixer's frame counter, so a headless run puts every beat on the same frame. A live render does not apply the style guide's music loudness (give the song's master a `loudness` number, or use stems). `music.render` docs: a layer's `intensity` is 0..1, not 0..10. (docs/MUSIC.md, "Playing a song in a game"; docs/SCRIPTING.md, "entity.music")
- **For engine developers:** `fa/audio/music_player.h` (the song's timeline as frame positions, quantization, layer gains, the live and stem sources, `MusicStatus`) and `music_transport.h` (the playheads inside the mixer: fixed-size, allocates nothing while it mixes, usable offline); `Audio::music_play`, `music_stop`, `music_set_intensity`, `music_go_to_section`, `music_play_stinger`, `music_crossfade_to`, `music_status`, `music_players`, `mixed_frames`; `PlayParams::delayFrames` starts a voice a number of output frames after the call (a stinger on its beat). A live render runs on a worker thread on a sound device and at once on the null device.
- **For game authors:** MIDI. `music.import_midi` (and `assets.import` of a `.mid`) turns a Standard MIDI File into a song document, with tracks, drums as grids, sections from markers and optional `quantize`; `music.export_midi` writes a song as a format-1 `.mid`, and importing it back gives the same notes. No other program is needed. (docs/MUSIC.md)
- **For engine developers:** `fa/audio/midi.h` (`parse_midi`, `write_midi`), `song_midi.h` (`midi_to_song`, `song_to_midi`), and in `song_preview.h` `render_song_asset`/`song_stem_plan`; `SongDoc::layers`. Recipes may carry a `context` object, which `check_recipe` compares (the style's music loudness).
- **For game authors:** layered images. A `*.image.json` document (canvas, layers bottom first: `pixels`, `fill`, `gradient`, `procedural`, `svg`, `text`, `provider`, `group`, `adjustment`; opacity, 18 blend modes, rect/ellipse/polygon/path/picture masks with feather, clipping, offsets) is the source of a PNG baked next to it. `image.bake {path, onlyIfNeeded?}` draws it (deterministic bytes) and returns the picture (`$image`); `image.save {path, document, bake?}` checks, writes and bakes a document. The bake records provenance (AI-made when a provider layer or an AI-made file is used) and a recipe, so `assets.regenerate` remakes it and `factoria validate` warns when it is stale; a document that does not load is a validation error with file, JSON pointer and fix, and `factoria export` bakes the documents whose PNG is missing or stale first. Schema `schemas/image.schema.json`. (docs/IMAGES.md)
- **For engine developers:** the compositor and the document live in `fa/tooling/image_doc.h` (`parse_image_document`, `composite_image_document`, `bake_image_document`, `image_bake_status`, `save_image_document`, `blend_pixel`); the adjustment and effect lists are tables in `image_doc_ops.cpp`. `assets.generate_texture`'s generator is shared through `procedural_texture_image`, and `rasterize_text` (fa/render/fonts.h) now reports the pen origin, advance, ascent and descent of the bitmap it makes.
- **For game authors:** non-destructive adjustments and effects for image documents, usable on any layer and in `adjustment` layers: `levels`, `curves` (monotone cubic), `hsv` (with colorize), `posterize`, `quantize` and `dither` (ordered Bayer 2/4/8, Floyd-Steinberg, Atkinson; to `style.palette` or a list of colours, nearest in OKLab), `gradientMap`, `colorBalance`, `threshold`, and the effects `outline`/`stroke` (exact for pixel art at width 1), `dropShadow`, `outerGlow`, `innerGlow`, `blur` (gaussian, box), `sharpen`, `noise` (seeded) and `shade` (from a normal map or the layer's alpha; light from `style.lightDirection`). Wrong keys and values are errors with the JSON pointer and a suggestion. (docs/IMAGES.md)
- **For game authors:** edit layered images with commands. `image.create`, `image.info` (the layer tree with index paths, bake status, stored selections) and `image.export` (a plain PNG copy, scaled or trimmed); `image.layer.add/set/move/remove` address a layer by name or index path (`"1/0"`) and teach with "did you mean"; `image.select` selects by colour (contiguous or global), alpha, rectangle, ellipse, polygon or a layer's shape, then grows, shrinks, feathers, inverts or combines, and stores the selection by name as a grey PNG in `.factoria/selections/`; `image.edit` fills, recolours, moves, transforms (nearest for pixel art, bilinear otherwise), deletes, copies or cuts the selected pixels of a layer (a non-pixels layer is rasterized, with a warning); `image.paint` stamps deterministic round-brush strokes. Every result returns the picture as `$image` and the changed `region`.
- **For game authors:** a PSD imported with `assets.import` is now a layered image document with one PNG per layer (names, opacity, visibility, blend modes, clipping, groups and layer masks kept) and the PNG baked from it; the "layers were flattened" warning appears only for a file whose layers cannot be read.
- **For game authors:** sound patches, `*.sfx.json` (format `factoria.sfx/1`, `schemas/sfx.schema.json`): layers with time offsets and gains; oscillators sine, square with duty, saw, triangle, white/pink/brown noise and a drawn wavetable, each with FM and ring modulation; pitch sweeps, pitch envelopes, vibrato and arpeggios; ADSR envelopes with a curve; low/high/band-pass filters with resonance and an envelope; distortion, bitcrush, delay and reverb on a layer or the master; a sample rate, length and tail, and a noise seed. A mistake names the file, the JSON pointer, the fix and a "did you mean". (docs/SOUND.md)
- **For game authors:** `sfx.render {path, out?, seed?, freq?, note?, length?, tail?, picture?, overwrite?}` renders a patch to a mono 16-bit WAV (or Ogg Vorbis) next to it and returns the loudness, peak and length, the numbers of `assets.spectrogram` and its picture (`$image`). The sound gets provenance and a recipe whose input is the patch, so `factoria validate` warns when the patch changed after its sound was made and `assets.regenerate` renders it again. `sfx.bake {force?, dryRun?}` renders every patch whose sound is missing or stale. `sfx.info {path | patch | preset}` lists all the problems of a patch, or what it holds and how loud it renders, without writing anything. (docs/SOUND.md)
- **For game authors:** sound macros, variations and families. A patch's `macros` are knobs by meaning, -1 to 1: `attack`, `brightness`, `weight`, `tail`, `pitch`, `grit` (and custom ones bound to patch numbers). `sfx.render` and `sfx.bake` take `macros`, and `sfx.tweak {path, macros: {brightness: 0.2}}` adds to the declared value, writes it back to the patch and renders again, comparing the measurements before and after. `variations: {count, seed, spread}` declares N takes of one sound: `sfx.render {variant: n}` or `{variants: true}` (one picture with a row per variant) and `sfx.bake` write `name_01.wav`, `name_02.wav`..., each with a recipe. `AudioSource.variants` and `audio.play(path, {variants: N})` play one variant per play, picked with the engine's seeded random numbers and never the same twice in a row; `audio.variantPath(path, n, count)` gives a variant's file name. `sfx.family {from, names | preset: "ui", out?}` writes click, hover, confirm, cancel, error, open, close and notify from one base patch, as copies that share its timbre and loudness, with a contact sheet. Measurements gain `centroidHz` and `riseSeconds`. (docs/SOUND.md)
- **For game authors:** the seventeen presets of `assets.synth_sound` are now sound patches that ship in the binary: `sfx.preset {name?, path?, overwrite?}` lists them, returns one to read, or writes it to a `*.sfx.json` to edit. `assets.synth_sound` takes the same arguments and records the same provenance, but its sounds come from the new synthesizer, so the bytes (not the character) of a preset differ from the previous version. (docs/SOUND.md, docs/ASSETS.md)
- **For game authors:** audio documents, `*.audio.json` (format `factoria.audio/1`, `schemas/audio.schema.json`): a non-destructive chain of steps over a WAV/OGG, a sound patch or another audio document. Fifteen steps: `trim`, `fade`, `normalize`, `gain`, `pitch`, `stretch`, `speed`, `eq`, `compressor`, `reverb`, `delay`, `reverse`, `layer`, `loop` (a seamless loop; its points go to the new import settings `loopStart` and `loopEnd`, which the mixer honours) and `granular`. `audio.info`, `audio.render` (measurements, the level after each step, a before/after picture), `audio.bake`, `audio.create` and `audio.edit` work on them; the baked sound has a recipe, goes stale when the document or any file it reads changes, and `factoria export` bakes it. Same bytes on every platform. docs/SOUND.md, "Audio documents".
- **For engine developers:** `fa_audio` has `audio_doc.h` (`parse_audio_doc`, `render_audio_doc`, `audio_wav_bytes`, `audio_encode`, and the DSP `audio_time_stretch`, `audio_resample`, `audio_pitch_shift`, written with the synth's deterministic math); `sfx_run_effects` and `sfx_measure_loudness` expose the synth's effects and the BS.1770 measure. The tooling side is `fa/tooling/audio_doc.h` (`bake_audio_document`, `audio_bake_status`).
- **For game authors:** song documents, `*.song.json` (format `factoria.song/1`, `schemas/song.schema.json`, docs/MUSIC.md): music composed as data. A tempo, meter, key and mode, swing, tracks (an instrument and named patterns each), sections (`intro`, `loop`, `outro`, any name) with repeats, mutes and a per-track arrangement (`"a a b*2 rest"`), and automation lanes (`volume`, `pan`, `filter`, `macro.<name>`). Pitched patterns are compact note text (`C4:4 E4 G4`, durations `:8 :4. :8t`, accents, staccato, ties, velocity, `[C4 E4 G4]` chords, `(Am7@3)` chords by name, `|` checked bar lines, `{...}x2` repeats, `&` voices); drums are a step grid per lane. A mistake is an error with the file, the JSON pointer, the line and column inside the note text, the fix and "did you mean", and `project.validate` reads every song.
- **For game authors:** `music.create {path, key?, mode?, tempo?, meter?, progression?, style?, bassStyle?}` writes a complete starting song (pad, bass, drums, arpeggio; intro, loop, outro), `music.edit {path, ops}` changes it (`set_song`, `add_track`, `set_track`, `set_pattern`, `add_section`, `set_section`, `arrange`, `mute`, `set_automation`, ...) and writes only a valid result, `music.info` summarises it per section and draws a piano roll (`$image`), `music.check {path, render?}` finds notes out of key, outside an instrument range, clashes, mud, silent tracks and (with a render) loudness problems, and `music.preview {path, fromBar?, bars?, solo?, mute?, out?}` renders a deterministic stereo WAV or OGG with the numbers, a spectrogram, provenance and a recipe that `assets.regenerate` and the stale-asset warning understand. It is the offline preview, not the in-game player.
- **For game authors:** music helpers that write note text and can put it in a song: `music.chord` (chords by name, progressions in a key, Roman numerals), `music.scale` (modes and the chords on each degree), `music.arpeggio` (up, down, updown, downup, random), `music.bassline` (root, root_fifth, octave, walking), `music.drums` (fourteen styles, fills) and `music.instrument` (ten built-in instruments, the drum kit lanes, sfx presets; copies the patch behind one into the project). A track plays any of them, an sfx preset or your own `*.sfx.json` per note at the note's pitch.
- **For engine developers:** `fa/audio/song.h` is the shared model for the music milestones: `parse_song`, `expand_song` (the arrangement as one sorted timeline of notes in ticks, 960 per quarter, swing applied) and `SongDoc`; `song_check.h` (the rules), `song_preview.h` (`render_song`), `song_theory.h`, `song_helpers.h` and `song_instruments.h`. The piano-roll and spectrogram drawing share `fa::picture::Canvas` (tools/common/src/picture_canvas.h).
- **For game authors:** a library of music instruments, all synthesized from sound patches with no files: 43 pitched instruments in eight families (`keys`: keys, piano, epiano, clav, organ; `pluck`: pluck, pluck_soft, pluck_bright, guitar, harp; `bass`: bass, bass_sub, bass_pluck, bass_acid, bass_fm, bass_square; `lead`: lead, lead_saw, lead_soft, lead_fm, lead_acid; `pad`: pad, pad_glass, pad_dark, pad_sweep; `bell`: bell, bell_glass, music_box, marimba, vibraphone; `ensemble`: strings, strings_soft, brass, horns, choir, flute, clarinet, oboe; `chiptune`: chiptune, chip_square, chip_pulse, chip_triangle, chip_wave, chip_noise) and three drum kits (`kit`, `kit:electronic`, `kit:chiptune`) of fifteen lanes (the new ones are `hat_pedal`, `tambourine`, `cowbell`; a later hat chokes an open hat). Each says what it is for, its range and its polyphony in `music.instrument`, which also lists the lanes of a kit. A C4 at velocity 100 peaks about -12 dBFS in every instrument, velocity is `(v/100)^1.25` with brighter hard notes, a note keeps its filter brightness across the range (new `keytrack` in a patch's layer filter), and a track's notes share its `voices` (a release counts, the oldest voice is cut with a short fade, a chord never cuts itself). (docs/MUSIC.md "Instruments")
- **For game authors:** the song mixer. A song gets `mixer` (`buses` of shared effects and a `master` with `effects`, a lookahead `limiter` with a ceiling and `loudness`: the style guide's music loudness, a number of LUFS, or off) and every track gets `mute`, `solo`, `voices`, `effects` (eq, filter, compressor, distortion, bitcrush, delay, reverb, written like the steps of an audio document) and `sends` to the buses. A render runs track inserts, fader, constant-power pan, buses and master, normalizes to the target (at most +18 dB, limiter-aware) and never passes the ceiling (-1 dB by default). `music.mix` returns what every track, bus and the master did (peak, LUFS, limiter reduction, normalization gain) without writing a file, `music.preview` returns the same as `mix`, `music.edit` has the op `set_mixer` and the new track fields, and `music.check` judges the loudness of the mastered mix (clipping with the limiter off, a limiter working hard, distance from the target). The audio-document steps `filter`, `distortion` and `bitcrush` are new. Mistakes in the mixer name the JSON pointer and suggest the close name. (docs/MUSIC.md "The mixer", docs/SOUND.md)
- **For game authors:** SoundFont instruments. A track plays a preset of a `.sf2` file the project brings: `"assets/audio/piano.sf2#Grand Piano"`, `"x.sf2#0:25"` (bank:program) or `{"soundfont": "x.sf2", "preset": "Grand Piano"}`; a bank-128 preset or `"drums": true` is a drum kit played by the grid lanes through their General MIDI keys. `music.instrument {name: "assets/audio/piano.sf2"}` lists the presets, and a missing file, a file that is not a SoundFont or a preset that is not there is an error that names the track and the close names. The SoundFont is calibrated like the synthesized instruments and is an input of the preview's recipe; `project.validate` checks that the file is there. (docs/MUSIC.md "SoundFonts")
- **For engine developers:** `fa/audio/soundfont.h` (`Soundfont::load`, `from_memory`, `presets`, `find_preset`, `render`) wraps vendored TinySoundFont (MIT, external/tinysoundfont, in the notices), with its libm calls redirected to `sfx_math` so a render is the same on every platform; `song_instruments.h` has the library (`song_instruments`, `song_instrument_families`, `song_kits`, `song_instrument_patch`); `song.h` has the mixer model (`SongMixer`, `SongBus`, `SongMaster`) and `song_preview.h` the renderer's `SongRenderOptions::targetLufs` and the `tracks`/`master` statistics (`SongTrackStats`, `SongMasterStats`) of `SongRender`. `audio_doc.h` exposes `parse_audio_step` and `audio_apply_effect` so a song runs the same effect steps as an audio document. The tests build a tiny SoundFont in code (engine/audio/tests/tiny_sf2.h).
- **For engine developers:** the synthesizer is in `fa_audio` (fa/audio/sfx.h: `parse_sfx`, `render_sfx`, `stretch_sfx`, `sfx_wav_bytes`), where the commands, the editor and the music player can all reach it. A render is bit-identical on every platform and in Debug and Release: it uses only `+ - * / sqrt` on doubles plus its own sine, `exp2` and `log2` (no libm transcendentals), seeded splitmix64 noise and its own BS.1770 loudness. `audio_mix::spectrogram_picture` exposes the picture of `assets.spectrogram` to other commands.
- **For game authors:** `assets.contact_sheet {paths, backgrounds?, sizes?, greyscale?, columns?, allFrames?, path?, overwrite?}` returns a labelled picture (`$image`) and writes a PNG only when `path` is given. (docs/ASSETS.md)
- **For game authors:** `assets.preview_in_scene {path, scene, at? | entity?, placement?, offset?, size?, resolutions?, steps?, center?}` places a Sprite or MeshRenderer in a copy of the scene and returns screenshots at the resolutions asked (default phone and desktop); the scene file is unchanged and no entity is left. (docs/ASSETS.md)
- **For game authors:** `assets.json` `style` grows rules a picture is measured against: `outline` (`color`, `width`), `lightDirection` (a name such as `upper-left`, or degrees towards the light), `texelsPerUnit`, `pixelArt`, `value` and `saturation` (`min`/`max`), `audio` (`loudnessLufs` per mixer bus and `toleranceLu`, parsed here for the sound check of a later release) and `ignore` (files and folders the rules skip). Only the rules you write are checked. A mistake in `style` names its JSON pointer and the fix, and the schema knows the new keys. (docs/ASSETS.md, "House style")
- **For game authors:** `assets.check_art {path | paths}` returns an annotated picture (the picture, its value, over each background and at each on-screen size) and a verdict (`ok`, `warn`, `fail`) with value, threshold and a fixing hint for each rule: palette fit, contrast over the backgrounds the scenes draw, readability on a phone and a desktop screen, halos and fringes on the alpha edge, the rules of `style`, and, for several pictures, set consistency (pixel density, pixel size, outline, shared palette). It is read-only and deterministic. (docs/ASSETS.md, "Checking art: assets.check_art")
- **For game authors:** `factoria validate` warns when a Sprite texture clearly breaks a style rule you set (the `fail` verdicts of `assets.check_art`), naming the rule, the numbers and the fix. The measurements are cached by file hash in `.factoria/art-cache/`, so a project is measured once. The sky-hopper example adopts `texelsPerUnit`, `saturation` and `ignore`.
- **For engine developers:** one shared parser, `load_style_guide` (fa/tooling/style_guide.h), serves the generation commands, `assets.check_art` and `project.validate`; the measurements and rules are in fa/tooling/art_check.h.
- **For game authors:** `assets.spectrogram {path, width?, height?, out?}` returns a picture of a sound (waveform, log-frequency spectrogram and loudness curve with the integrated value and the loudest momentary one, clipped samples marked in red, the loop seam marked for a looping sound) with the numbers beside it (LUFS, true peak, clipped samples, dominant octave band). `assets.check_mix {paths?, targets?}` measures every sound of the project together and lists findings with `sound`, `rule`, `value`, `threshold`, `verdict` and a `hint` that names the fix: loudness against a target per bus (or the spread inside a bus), music masking the bands where an effect has its energy, clicks at the start or end, loop seams, clipping and true peak above -1 dBTP. (docs/ASSETS.md, "Hear what you made")
- **For game authors:** `assets.review {path | paths, focus?}` is a one-shot vision review the AI building the game can call on its own pictures: it runs `assets.check_art` first, sends the "fast" role's model the numbers, the `style` rules, the `style.references` images, the pictures and the annotated picture, and returns a `verdict` (`good`, `fix`, `redo`), concrete `fixes` (what, where, command) and the check summary. Without a provider, key or vision model it fails with a hint and the loop goes on without it. The loop (make, preview, check, fix, review) is written in docs/AI_GUIDE.md 9.23 and the make-art skill. (docs/ASSETS.md)
- **For engine developers:** `make_vision_model` (fa/ai/text_model.h) is `make_text_model` with PNG/JPEG/WebP/GIF images attached to the user message (Anthropic image blocks, OpenAI-compatible `image_url` data URLs, a CLI agent's stream-json or files).
- **For game authors:** pixel art in image documents. A layer of kind `indexed` stores palette indices as text rows (`"rows": ["..11..", ".1221."]`, `.` transparent, `0-9a-zA-Z...` the index), locked to the document's `palette` (a list of colours, each optionally named, with optional `ramps` from dark to light) or, when it has none, to `style.palette`; a colour outside the palette is an error with the JSON pointer and the nearest palette colour. `image.pixel {path, layer, pixels?, runs?, stamp?, create?}` writes exact pixels and `image.draw {path, layer, shapes}` draws Bresenham lines (with `perfect` for one-pixel-thick bends), rectangles, midpoint ellipses, polygons and 4/8-connected flood fills; a colour is an index, a name or `{"step": -1}` for one shade darker along its ramp. `image.palette {path, palette?, ramps?}` shows or changes the palette and ramps, and `image.layer.convert {path, layer, to: "indexed"|"pixels", dither?}` quantizes a layer to the palette (the `quantize`/`dither` code of the adjustments) or turns it back into a PNG layer. Results return the changed `region` and a preview magnified with hard pixels; `image.paint` and `image.edit` refuse an indexed layer instead of anti-aliasing it. (docs/IMAGES.md, "Pixel art")
- **For game authors:** pixel helpers for indexed layers, palette-exact (no blending, no anti-aliasing). `image.pixel.outline` (outer or inner, 4- or 8-connected; a colour, the darkest of the fill's ramp, or sel-out with a darker shade of the fill and a lighter one on the lit side), `image.pixel.shade` (shadow and highlight bands stepping along the ramps from a `light` or the style's `lightDirection`, with a band width and an optional Bayer-dithered transition), `image.pixel.dither` (Bayer and checker blends of palette colours, constant or as a gradient along a line), `image.pixel.cleanup` (orphans, doubles and jaggies, with a report and `keep` colours), `image.pixel.rotate` (RotSprite: Scale2x three times, nearest rotation, most-common-colour downscale; exact for multiples of 90) and `image.pixel.scale` (nearest, most-common-colour, scale2x/scale3x), and `image.to_pixel_art` (a layer or a PNG downscaled area-aware to a size or `pixelSize`, quantized to the palette with the dithers of `image.layer.convert`, cleaned of orphans, optionally outlined, written into an indexed layer). Each takes `frame` or `frames` (`"all"`, a list or a range) and a stored `selection`, and returns the changed `region` and a hard-pixel preview like `image.pixel`. (docs/IMAGES.md, "Pixel helpers")
- **For engine developers:** the pixel algorithms are in `fa/tooling/pixel_art.h` and know nothing of documents: `pixel_outline`, `pixel_shade`, `pixel_dither_blend`, `pixel_dither_gradient`, `pixel_cleanup`, `pixel_scale2x/3x`, `pixel_resample`, `pixel_rotate`, `pixel_area_downscale`, `pixel_dominant_downscale` (an `IndexGrid` and an optional `PixelMask`), so tile and editor tools can reuse them.
- **For engine developers:** the pixel algorithms and the palette are in `fa/tooling/pixel_art.h` (`pixel_line`, `pixel_perfect`, `pixel_rect`, `pixel_ellipse`, `pixel_polygon`, `pixel_flood`, `PixelPalette`, `IndexGrid`), with no JSON or document knowledge beyond the palette lookup, so later tile tools can reuse them; the layer kind is `ImageLayerKind::Indexed` (`ImageLayer::rows`, `ImageDocument::palette`) and its commands are in `image_indexed.cpp`.
- **For game authors:** vector illustration. The `vector.*` commands edit an SVG instead of making you rewrite it, on a project `.svg` file (`source`), SVG text (`svg`) or an svg layer of a `*.image.json` (`document`, `layer`), and each returns a rasterized preview (`$image`): `vector.boolean {op: union | subtract | intersect | exclude, elements}` (the first shape keeps its id, style and place), `vector.offset {elements, distance, join, miterLimit?, copy?}` (grow or inset with round, miter, bevel or square corners), `vector.stroke_to_path` (width, caps, joins, miter limit and dashes into a filled outline), `vector.simplify` and `vector.smooth` (fewer nodes; corners rounded into Béziers), `vector.align` and `vector.distribute` (selection, canvas or key element; equal gaps or centres; groups move as one piece), `vector.repeat` (grid or around a circle, copies get `<id>-2`...), `vector.style` (the project's `assets.json` outline and palette applied to the SVG) and the read-only `vector.info` (ids, bounds, node counts). Results are written back keeping ids, groups, transforms, styles and the rest of the text byte for byte; element and parent transforms are honoured and curves come back as cubic Béziers fitted within `tolerance`. A call either succeeds or leaves the file untouched; `dryRun` previews and `out` writes another file. (docs/VECTOR.md)
- **For game authors:** vector shape builders. `vector.shape {kind: star | gear | polygon | arrow | bubble | ribbon}` inserts a shape with exact geometry (star points, inner ratio and roundness; gear teeth, depth and hole; polygon with true rounded corners; straight or curved arrow; speech bubble whose tail points at `tailTo`; folded ribbon) with an `id`, style, `parent` group and `transform`; `vector.blob` makes a smooth blob or open curve through (cardinal spline, `tension`) or around (B-spline) a few points; `vector.mirror` reflects a shape across a vertical or horizontal axis and welds the halves into one path (or adds the copy); `vector.text_to_path` turns text, or the `<text>` already in the drawing, into one path with the engine's own fonts and HarfBuzz shaping, so no font is needed; `vector.shade` adds shadow and highlight bands from the light direction (default: the style guide's `lightDirection`), coloured with the style palette's darker and lighter steps or with OKLab shifts of the fill. (docs/VECTOR.md)
- **For game authors:** characters in parts. `vector.to_rig {source, pixelsPerUnit?, layout?, parts?, pivots?, parents?, ...}` turns an SVG whose named groups are the parts of a character into one atlas of trimmed, padded part pictures (or one PNG per part with `layout: "files"`), the joints and a prefab with one entity per part in the hierarchy of the drawing, each with a `Sprite` (region, size, pivot, layer from the SVG order, pixel-art flag from the style) and a `Bone2D` (length to the farthest child joint, limits from `data-min-angle` / `data-max-angle`). Joints come from a `<part>-pivot` shape, `data-pivot`, `pivots`, the overlap with the parent, else the top centre; the hierarchy from nesting, `data-parent`, `parents` and names (`arm_lower_l` under `arm_upper_l`). The rest pose is checked against the SVG (`restPose`, with a side-by-side `$image`), running it again updates the prefab in place (names, an Animator and other additions stay; removed or renamed parts are reported with the clips that name them, `prune: true` removes them), and the pictures carry a recipe so the rig goes stale when the SVG changes. (docs/VECTOR.md, "Characters in parts")
- **For engine developers:** `fa/tooling/vector.h` returns the same shapes as path data (`vector_star_path`, `vector_gear_path`, `vector_bubble_path`, `vector_text_path`...), and `outline_text` (fa/render/fonts.h) gives the glyph outlines of a shaped text.
- **For engine developers:** the vector operations live in `tools/common/src/vector_*.cpp` (a round-tripping SVG tree with selectors and CSS-style inheritance, a Clipper2 clipping/offsetting layer on an integer grid, an SVG-exact stroker, Schneider Bézier fitting). Clipper2 2.0.1 (Boost license) is vendored in `external/clipper2` and listed in the notices.
- **For game authors:** frames and tags in image documents. A `*.image.json` with `frames` (a duration in milliseconds each), `tags` (`name`, `from`, `to`, `direction` forward/reverse/pingpong, `repeat`) and per-layer `cels` (a picture, a `link` to an earlier frame, or `empty`; a frame without a cel holds the previous one) is an animation: the bake is a sprite sheet PNG and the `sheet` entry of assets.json gets one SpriteAnimator clip per tag, so a game plays `SpriteAnimator {"clip": "<tag>"}` with the usual recipe and staleness (a reverse, ping-pong, repeated or unevenly timed tag gets extra cells that spell its order out). `image.frame.add`, `.remove`, `.move`, `.set` (durations), `.cel` and `.sheet` (columns) and `image.tag.set` / `image.tag.remove` change it; `image.pixel`, `image.draw`, `image.edit`, `image.paint` and `image.export` take `frame`, and the editing commands take `onion` for a ghosted preview of the neighbouring frames. `assets.import` of an Aseprite file now makes such a document (layers, blend modes, linked cels, durations, tags with direction and repeat; an indexed file keeps its palette) and bakes the sheet from it; `flat: true` keeps the old one-PNG import. A document without `frames` or `tags` is unchanged, byte for byte. `image.select` takes `frame` too (the stored selection stays one per document). A cel picture that nothing reads any more (a removed frame, a cleared or repainted cel) is deleted in the same save, only inside the document's own `<name>.layers/` and only when no other layer, frame, `link` or image document names it; the result lists them in `removedFiles`. A layer that `image.edit` copy/cut or `create: true` makes while a `frame` is given shows only in that frame. (docs/IMAGES.md, "Frames and tags")
- **For engine developers:** frames and tags are in `fa/tooling/image_doc.h` (`ImageFrame`, `ImageTag`, `ImageCel`, `image_frame_count`, `plan_image_sheet`, `composite_image_sheet`, `ImageRenderOptions::frame` / `onion`; `bake_image_document` writes the sheet and `ImageBakeResult::sheet`); the commands are in `image_frame_commands.cpp` and the ambient frame of the editing commands is `FrameScope` in `image_frames.cpp`; the Aseprite document import is in `assets_aseprite.cpp`.
- **For game authors:** tiles in image documents. `image.tile.set {path, enabled?, width?, height?}` turns on tile mode (`"tile": true` or `{width, height}` for a sheet of tiles): `image.pixel`, `image.draw`, `image.paint`, the pixel helpers outline / shade / dither / cleanup and the `move` of `image.edit` wrap around the edges of a tile, so the edges keep matching while you draw (rotate, scale, `to_pixel_art` and `transform` do not wrap and warn). `image.tile.check {path, tileWidth?, tileHeight?, tolerance?}` compares the pixels that touch when a tile repeats and returns the bad seams (tile, side, runs of pixels) and a 3 x 3 preview with them in red; the tolerance is 0 for pixel art and else follows the picture's own smoothness. (docs/IMAGES.md, "Tiles")
- **For game authors:** autotile sets from a few parts. A `tileset` layer and `image.tileset.build {path, mode, tileWidth, tileHeight, parts, variations?, seed?}` make the 16 (`basic16`) or 47 (`blob47`) tiles of an autotile set from `inside`, `edge`, `corner` (+ `innerCorner`) parts given as a PNG, indexed rows or a flat colour (optional parts replace a derived orientation, a list of variants gives variations picked by the seed), bake the sheet and write the Tilemap rules file (`<document>.terrains.json`), recording both as recipes so `assets.regenerate {"stale":true}` redraws them in place when a part changes. `image.tileset.info` draws the parts and the tile table, `image.tileset.check` compares every pair of tiles that can stand side by side in a map and the joins between quadrants of different parts inside each tile, and `image.tileset.rules` writes the rules alone. (docs/IMAGES.md, "Tiles")
- **For game authors:** `Tilemap.terrains` (autotile rules) and the commands `tilemap.paint_terrain {id, terrain, rect? | cells?, erase?}`, `tilemap.retile`, `tilemap.terrains` (the rules, their slots, how many cells belong to each terrain and every problem) and `tilemap.set_terrains {id, path | terrains, retile?}`: paint a terrain and the edge, corner or inside tile that fits the cells around each cell is chosen for you, in the 16 and 47-tile layouts, with the variation of a look picked by column, row and seed so a painting looks the same every run. Scripts: `entity.tilemap.paintTerrain(terrain, cells)`, `eraseTerrain`, `retile()` and `terrainAt(col, row)`. A rule or terrain that is wrong is an error with its JSON pointer and a did-you-mean. (docs/AI_GUIDE.md section 9.8, docs/SCRIPTING.md)
- **For engine developers:** the autotile rules and the mask tables are in `fa/scene/autotile.h` (`autotile_masks`, `autotile_slot`, `autotile_hash`, `parse_terrains`); the tile mode math, the seam check and the set check are in `fa/tooling/image_tile.h` (`tile_wrap`, `check_tile_opposites`, `check_tile_set`) and the generator in `fa/tooling/image_tileset.h` (`build_tileset`, `tileset_terrain_json`), all pure functions of pixels.
- **For game authors:** the Image panel in the editor (View > Image, or a double click on a `*.image.json` in the Project panel; a floating window the first time). It shows the composite with zoom (fit, 1:1, wheel and pinch, nearest-neighbour above 100%, a pixel grid from 800%), pan and a checkerboard; lists the layers (kind badges, visibility, lock, opacity, blend mode, drag to reorder or into a group, add, duplicate, remove, rename) with an inspector; paints, erases, fills and picks colours (size, hardness, opacity; palette-exact on indexed layers, with a palette bar); selects by rectangle, ellipse, lasso, polygon and magic wand (add, subtract, intersect, grow, shrink, feather, invert; marching ants); moves and transforms with a box and handles; edits adjustments and effects with a live preview; and switches frame with an onion-skin toggle. Every edit is one step of the editor's Undo and runs the same `image.*` command an AI would call, so the two can take turns on a document; **Save** bakes the PNG like `image.save`. Layer lock and group open/closed are kept for the session only. (docs/EDITOR.md, "Image panel")
- **For engine developers:** `fa/tooling/image_paint.h` holds the pixel operations behind `image.paint` and `image.edit` (`paint_image_stroke`, reading and writing the stored selection, the patch functions that cut, erase, draw and transform pixels, and `open_image_edit_buffer`) as functions the editor calls too, and `ImageRenderOptions::pictures` lets `composite_image_document` draw a layer from memory instead of its PNG (a stroke or a slider being dragged). The panel's model, with no window, is `tools/editor/src/image_model.*` and is covered by `tools/editor/tests/image_tests.cpp`; autotest section I2 drives the panel.
- **For game authors:** the Vector panel in the editor (View > Vector, a double click on a `*.svg` in the Project panel, or **Edit in Vector panel** on an svg layer of the Image panel). The canvas is the engine's own SVG rasterizer, with zoom and pan, a snap grid, snapping to nodes, shape corners and centres and to guides, and a selection (click, marquee, Shift) with a box to move, scale and rotate. Tools: Select, Node (drag anchors and handles, insert, delete, corner / smooth / symmetric, break, join, close, reverse), Pen (corners and curves, closing, continuing an open path), Rectangle, Ellipse, Line and Shape (a star, gear, polygon, arrow or bubble that keeps its parameters as fields). Buttons for the booleans, offset, simplify, smooth, mirror, outline, align, distribute, house style, palette snapping and shade. A layer list of the SVG's groups and shapes (hide, lock, rename an id, drag to reorder or regroup) and an inspector with fill and stroke (the exact colour of the project's palette), width, opacity and fill rule. Every gesture runs a `vector.*` command, so the SVG keeps its ids, groups, transforms and untouched text, an edit is one undo step and an AI and a person can take turns on the same file; live drags are `dryRun` previews on the text in memory.
- **For game authors:** the Sound panel in the editor (View > Sound, or a double click on a `*.sfx.json`, `*.audio.json`, `.wav` or `.ogg` in the Project panel). It shows the waveform (zoom, selection, a playhead) and a spectrogram of what the engine's renderer makes, with the measurements; plays, stops and loops it or only the selection; gives every macro of a patch a knob; edits every other field in an inspector built from the schema, with its docs as tooltips; applies presets and makes the UI family; lists the variations and plays two of them as A and B at the same loudness; and edits an audio document's chain of steps (add, remove, reorder, switch off, hear up to a step) with the loop points draggable on the waveform. Edits are `sfx.*` and `audio.*` commands and one step of the editor's Undo each, and **Save + bake** writes the WAV and its recipe. (docs/EDITOR.md, "Sound panel")
- **For game authors:** `sfx.edit {path, op, pointer, value?, index?, to?}` changes one field of a sound patch by JSON pointer (`set`, `remove`, `add` to an array, `move` within one) and writes it only when the result still parses.
- **For game authors:** Neon Swarm's sounds are now patches (`assets/sfx/*.sfx.json`) baked to the WAVs the game plays, and its music is an audio document (`assets/music/loop.audio.json`, a loop step and a loudness step over the original recording in `assets/source/`), each with a recipe.
- **For engine developers:** the Sound panel's model (`tools/editor/src/sound_model.*`, `sound_schema.*`, `sound_player.*`) knows no window and is tested with doctest (`sound_tests.cpp`); the spectrogram, metrics and `render_sound` are in `fa/tooling/audio_view.h`; `Audio::has_device()` and `pcm_queued_frames()` tell the panel what the null device is doing; the editor autotest has a Sound section (K3).
- **For game authors:** eleven commands for editing by hand, the ones the Vector panel runs: `vector.add` (path, rect, ellipse or line), `vector.nodes` (move anchors and handles, insert, delete, convert, break, join, close, reverse, append), `vector.set_path`, `vector.set` (style, `hidden`, `locked`, rename an id with its references), `vector.transform`, `vector.delete`, `vector.duplicate`, `vector.group`, `vector.ungroup`, `vector.reorder` and `vector.assign_ids`. `vector.shape` gets `replace` and `parametric` (the element keeps `data-fa-shape` and `data-fa-args` until a command changes its outline), and every `vector.*` command takes `preview: false` and `bake: false` (docs/VECTOR.md, "Editing by hand").
- **For engine developers:** the model of the Vector panel (`tools/editor/src/vector_model.*`) knows no window and is tested with doctest (`vector_tests.cpp`), the SVG scene and the editing commands are in `tools/common/src/vector_scene.cpp`, `vector_nodes.cpp` and `vector_edit_commands.cpp`, and the editor autotest has a Vector section (J2).
- **Fixed:** the arc command (`A` / `a`) of SVG path data read its end point from the wrong numbers, so every elliptical arc went to the wrong place in `vector.*` operations and in the Vector panel's reading of a path.
- **For game authors:** model documents, `*.model.json` (format `factoria.model/1`, `schemas/model.schema.json`, docs/MODELING.md): a 3D model written as a tree of operations instead of a mesh file. Twelve primitives with documented parameters, defaults and segment controls (`box`, `rounded_box`, `cylinder`, `cone`, `sphere`, `capsule`, `torus`, `grid`, `stairs`, `arch`, `pipe` and `text`, which extrudes the engine's own fonts with the holes of the letters cut out), `group`, and a transform, a `part` name, a `material` and a vertex `color` on any node (inherited by the nodes below, `enabled` switches a node off, `align` stands a primitive on y = 0). The baked `.glb` has one primitive per part and material, with the part name in its `extras.part`; every solid primitive is a closed surface with outward normals and UVs per primitive, and the same document gives the same bytes.
- **For game authors:** `model.create {path, nodes?, materials?, output?, doc?}` writes a document and bakes it, `model.info {}` lists the operations and every field (range, default, doc string), `model.info {path}` checks a document (all its issues at once, each with a JSON pointer, the fix and "did you mean") and measures what it builds (bounds, triangles, closed surface, volume, per-part bounds), `model.edit {path, op: add|set|remove|move|document, target, ...}` changes one node by its stable id and checks the whole document before writing, and `model.bake` writes the `.glb` the way `mesh.save` does, with provenance and a recipe in `assets.json`. A baked model goes stale when its document or a font or texture it reads changes; `assets.regenerate`, `project.validate` and `factoria export` handle it like the image and audio documents.
- **For engine developers:** the model kernel lives in `fa_scene` (`fa/scene/model_kernel.h`: primitives, ear-clipping triangulation, polygon extrusion, mesh statistics; `fa/scene/model_doc.h`: the catalog of operations, `parse_model_doc`, `evaluate_model`, `model_doc_schema`), because its product is the `MeshInput` and `MeshData` that `MeshStore`, `mesh.save` and the runtime already use and it needs nothing above `fa_core`; the `text` glyph outlines come in through a callback (`ModelTextSource`) because fonts are in `fa_render`. The project side is `fa/tooling/model_bake.h` (`bake_model_document`, `model_bake_status`, `bake_model_documents_if_needed`). `MeshSubmesh` has a new last member `part`, written to the `.glb` as the primitive's `extras.part`.
- **For game authors:** modifiers for model documents. A modifier is a node that takes the mesh of its `children`, changes it and passes it up (docs/MODELING.md, "Modifiers"): `boolean` (union, difference, intersection of closed solids, exact for touching and coplanar faces; the error names an operand that is not closed), `mirror`, `array`, `radial_array`, `bevel` (angle threshold, segments, width), `subdivide` (Catmull-Clark with a crease angle), `solidify` (also for open surfaces), `bend`, `twist`, `taper`, `noise` (seeded), `smooth` (Laplacian or Taubin), `weld` and `shade` (flat, smooth or by angle). Three new primitives make surfaces from points: `lathe` (a profile turned about Y), `sweep` (a profile along a path) and `loft` (a skin through sections). Parts, materials, colours and UVs follow the triangles through every modifier; results are byte-identical between runs; a result over 1,000,000 triangles (400,000 across a boolean's operands) is an error that says what to lower. `model.info {}` lists every field with its range and default, the schema `schemas/model.schema.json` knows them, and mistakes name the JSON pointer and suggest the close name. `model.edit` can `add` into a modifier like into a group.
- **For engine developers:** the modifiers are `fa/scene/model_modifiers.h` (`model_mirror`, `model_array`, `model_bevel`, `model_subdivide`, `model_boolean`, `model_lathe`, `model_sweep`, `model_loft`... on `ModelMesh`, which now has `triParts`, the part of each triangle); the shared welded-soup helpers are private (`engine/scene/src/model_mesh_ops.h`). Booleans use vendored Manifold v3.5.4 (Apache-2.0, `external/manifold`, the core library built serial with no TBB, listed in the notices). The catalogue gained the field types `points2`, `points3` and `rings` with `minItems`/`maxItems`, and `ModelOpInfo::kind` "modifier".
- **For game authors:** organic shapes in model documents, with no sculpting. An `sdf` node takes signed-distance shapes as `children` (`sdf_sphere`, `sdf_capsule` (or a round cone), `sdf_ellipsoid`, `sdf_box` with rounded edges, `sdf_cylinder`, `sdf_cone`, `sdf_torus`, and `sdf_group` to treat several as one, optionally mirrored across a plane), joins them in order with `blend` `union`, `subtract` or `intersect` and a `smooth` distance that melts the surfaces into each other, and meshes the result: a creature, a rock, a tree, a mushroom. Each shape keeps its `part`, `material` and `color` (a triangle belongs to the part of the shape that owns the surface there; a vertex colour melts across a smooth blend). `quality` (`draft`, `normal`, `fine`, `ultra`) or `voxelSize` sets the resolution, a request that would cost too much is an error that gives the voxel size that fits, `targetTriangles` and `maxError` decimate (quadric error metric, part boundaries kept), and `noiseAmplitude`, `noiseFrequency`, `noiseOctaves` and `noiseSeed` roughen the surface (rock, bark). The result is closed, manifold, with outward smooth normals taken from the field, and the same bytes on every platform; it is a mesh like any other, so modifiers wrap it, a `boolean` takes it as an operand and `align` stands it on the ground. A shape outside an `sdf`, or a mesh inside one, is an error with the pointer and the way out. (docs/MODELING.md, "Organic shapes: sdf")
- **For engine developers:** `fa/scene/model_sdf.h` (`ModelSdf`, the field tree with exact shape distances, quadratic smooth min/max, owner and colour mixing; `model_sdf_mesh`, `model_sdf_noise`) and `fa/scene/model_decimate.h` (`model_decimate`, a Garland-Heckbert edge-collapse decimator for welded triangle meshes with part and border preservation, the link condition and a flip check; plain vectors, so LOD generation can reuse it). Meshing is marching tetrahedra on the Kuhn subdivision of the grid, which is a closed 2-manifold by construction. No library is vendored. `model_value_noise` is now exported from `model_modifiers.h`.
- **For game authors:** UVs for the models the engine makes. A model document's `uv` section gives the whole model new UVs after every node: `method` `unwrap` (automatic unwrapping with xatlas, vendored) or a `box`, `cylinder`, `sphere` or `planar` projection, chosen per part with `parts`, packed into one texture (`layout` `atlas`) or world-scale and repeating (`tile`), at the style's `texelsPerUnit` (or its own), with `textureSize`, `padding`, `seams` and `rotate`. It also replaces the default box UVs of `sdf` shapes. `model.uv {path, set?, replace?, clear?, bake?, picture?}` edits the section field by field (the whole document is checked, a mistake writes nothing), bakes, and measures the result: texels per metre, stretch, seams, mirrored triangles, how full the texture is, overlap and UVs outside 0..1, with warnings that say what to change, plus a picture of the layout. `model.create` and `model.edit` take `uv`, `model.info` measures it and `project.validate` repeats its warnings. A `.glb` whose density comes from `style.texelsPerUnit` goes stale when the style changes it. (docs/MODELING.md, "UVs")
- **For engine developers:** `fa/scene/model_uv.h` (`model_uv_apply`, `model_uv_measure`, `ModelUvSettings`) works on any `ModelMesh` and the part of each triangle, so the mesh cleanup of imported models can reuse it; `ModelDoc::uv`, `ModelBuild::uv`, `ModelEvalOptions::defaultTexelsPerMeter`; `model_project_eval_options` now takes the project directory. xatlas is vendored in `external/xatlas` (MIT; single threaded, its libm calls replaced by `fa::det` so the unwrap is the same on every platform).
- **Fixed:** `Vec2`, `Vec3` and `Vec4` index their components through pointers to members: `v[i]` read `(&x)[i]`, past `x`, which an Apple Clang Release build optimized into writing `y` and `z` of a rounded box to `x`.
- **Fixed:** `assets.review` and the other vision checks no longer take a program called `ant` on the PATH for the Anthropic CLI: an Anthropic provider without a key counts as usable only when `ant` gives a token (the GitHub runners have Apache Ant).
- **Fixed:** the Music panel's intensity buttons start a new line when the transport does not leave room for them, instead of running off a narrow panel.
- **Fixed:** the Image, Sound, Music and Modeler panels open the first time as floating windows that fit the screen: on a display smaller than about 1100 x 780 their right-hand inspector (layers, adjustments, instruments) used to be off screen.
- **For engine developers:** an editor autotest step on a widget that is drawn but scrolled out of its window scrolls it into view and runs again on the next frame, so the sections pass in a small window (CI's macOS window is 1024 x 642; `FA_EDITOR_AUTOTEST_SIZE=1024x642` reproduces it).
- **For engine developers:** `scripts/ci-docker.sh` gives each checkout and git worktree its own build-tree volumes (`factoria-ci-linux-<hash>`, `factoria-ci-windows-<hash>`); one tree shared by two worktrees linked objects of the other branch. `scripts/ci-local.sh macos` configures `build/macos-release` as CI does (tests on, native architecture), so a release package built in the same checkout no longer leaves it running stale test binaries.

## 0.15.0

FactorIA 0.15.0 (M50) is about pushes that pass CI the first time. Each failed CI round (a Windows file rule, a timing
budget on a slow runner, an MSVC-only error) cost a day, so the checks CI makes now run before the push:
`scripts/ci-preflight.sh` scans the diff for the patterns that failed before, runs the whole test suite, repeats the
tests the change touches under load, runs the Linux job in a Docker container on the Mac and the native Windows check
on a Windows PC of the same network, and prints what passed, failed or could not run. macOS and Linux test runs follow
the Windows file rules, so the bugs that only Windows CI found show up on any machine; on the way it found that file
times read as "missing" on Linux.

### Changes

- `scripts/ci-preflight.sh`, the one command before a push: a risk scan of the branch's added lines against the patterns that
  failed CI before, `scripts/test-all.sh`, a stress pass (the editor autotests and example tests the diff touches, repeated under
  CPU load), the other platforms of `scripts/ci-local.sh` and the Docker/remote Windows scripts when present, and a PASS/FAIL/SKIP
  summary (docs/BUILDING.md, "Before a push").
- **For engine developers:** the "Windows file rules" mode of `fa::fs` makes macOS and Linux test runs find the file bugs
  that only the Windows CI job found. With `FA_FS_WINDOWS_RULES=1` a file open through the new `fs::ReadStream` (or
  `fs::read_bytes` / `read_text`) cannot be replaced, renamed or deleted (`fs::write_bytes`, the new `fs::replace_file` and
  `fs::remove_file`, `fs::remove_tree` fail with a sharing violation after the retries Windows needs), and
  `fs::modified_time` / the new `fs::host_modified_time` round a file's time down to 15.625 ms. `ctest` turns it on for
  every test on macOS and Linux (`FA_FS_WINDOWS_RULES=0 ctest` for one run without; `-DFA_TEST_WINDOWS_FILE_RULES=OFF`
  for a build). Change detectors of the editor, the checkpoint store, the MCP module watcher and self-update read times
  through `fs::`; the readers of files that other threads write (stores, settings, chats, the project file, progress
  files) read through `fs::ReadStream`; their replaces and deletes go through `fs::replace_file` / `remove_file`.
  (docs/BUILDING.md, "Running tests"; docs/ARCHITECTURE.md, "Files")
- `scripts/setup-docker-macos.sh` installs Colima and Docker on a Mac and starts a VM with Rosetta; `scripts/ci-docker.sh`
  runs the Linux and Windows (MinGW-w64 + Wine) jobs of `ci-local.sh` in an Ubuntu 24.04 `linux/amd64` container
  (`tools/ci/docker/Dockerfile`), and `ci-local.sh` uses it on a Mac instead of skipping those jobs and `sniper`.
- **For engine developers:** the Mac can run the native Windows check (MSVC build, full ctest, example games) on a Windows
  PC on the same network over SSH before a push: `scripts/setup-windows-remote.sh` (Mac) and
  `scripts/setup-windows-remote.ps1` (the PC, administrator PowerShell, idempotent) set it up once, then
  `scripts/ci-remote-windows.sh [--no-examples] [--wsl]` pushes HEAD to `refs/heads/preflight/<branch>` of a repository it owns on the PC
  (`%USERPROFILE%\FactorIA-remote`, no clone needed; a folder that is a git repository of its own is refused),
  builds it in a worktree there and brings the logs back to `build/ci-logs/windows-remote/`. A PC that is off is not a failure: after a 5 s check the script asks in a terminal whether you are switching it on (or waits with `--wait`, `--wait-timeout`) and otherwise exits 77, as it does when not set up or when the connection drops mid-run; it never switches the PC on or off. The tests that need a window (ctest label `window`) run in the desktop session of the user logged in on the PC through a one-shot scheduled task; with nobody logged in they are reported as skipped and the exit status is 77.
  (docs/BUILDING.md, "Checking Windows from the Mac")
- Tests with a speed budget scale it with `fa::test_speed_budget_scale()` (4 on an MSVC Debug build, 1 elsewhere); the `mcp` test no longer reads a freed temporary in a range-for, which the MSVC debug heap exposed. `/bigobj` is on for MSVC builds.
- CI saves each job's ccache right after the build instead of at the end of the job, which `actions/cache` only does
  when every step passed: a run whose tests failed left the next run of the branch a stale cache (Windows rebuilt
  cold with 11% hits, 35-45 min).

### Fixes

- `fs::modified_time` counts nanoseconds from 1970 with every standard library (new `fs::file_time_ns`): with GCC's
  libstdc++, whose file clock starts in 2174, a file written today had a negative time that read as a missing file.

## 0.14.1

FactorIA 0.14.1 makes the test runs of game authors and engine developers stop failing on a busy machine. Script time limits (a `factoria test` test, `script.eval`, callbacks, tools and module loads) now count the CPU time the script spends, with a wall-clock cap eight times larger for a script blocked forever, so a build running next to the tests no longer fails a test that passes alone. The example games' tests run on optimized builds only, and `scripts/test-all.sh` is the one command that runs everything before a push.

### Changes

- **For engine developers:** `FA_ENGINE_VERSION` is a generated header (`fa/core/engine_version.h`) instead of a compile definition on every `fa_*` target, so a version bump recompiles about 35 files instead of the whole engine and ccache keeps hitting on CI. Include the header where the macro is used; `fa::engine_version()` (fa/core/build_info.h) gives the string to headers. (docs/BUILDING.md)
- **For game authors:** the time limits of scripts count CPU time instead of wall-clock time: the 60 s of one test in `factoria test`, the 5 s of `script.eval`, the 2 s of a callback, the 10 s of a tool or a module load. A busy machine (a build running next to the tests) no longer fails a test that passes alone. A script blocked without using CPU is still stopped by a hard cap of 8 times the limit on the wall clock. The "script took too long" message now says which one ran out (`> 60 s of CPU time` or `> 480 s on the clock`) and the test message says to split the test. (docs/SCRIPTING.md)
- The example games' tests, validations and perf budgets carry the ctest label `example` and run on optimized builds: `FA_EXAMPLE_TESTS=AUTO` (default) registers `example_*_test` and `example_*_perf` as `DISABLED` in a Debug build. `scripts/test-all.sh` (Windows: `scripts\agent-build.ps1 <dir> -Test -Examples`) is the one command before a push: the Debug suite plus a Release build running `ctest -L example`. (docs/BUILDING.md, "Running tests")
- CI runs the tests in parallel on Linux and macOS (`ctest --parallel` with the runner's vCPUs); Windows, whose software
  D3D11 already fills its vCPUs, keeps one test at a time. The perf budgets are
  `RUN_SERIAL` so they still run alone. (docs/BUILDING.md, "Continuous integration")
- `perf.check` measures a time over its limit up to twice more (it was once) and keeps the best time of each metric: a
  shared CI machine can run a few times slower for some seconds. A game that got heavier is slow every time and still
  fails. (docs/PERFORMANCE.md)

### Fixes

- The editor's Project panel walked the project folder twice after the editor wrote a file (a prefab saved, an asset
  made): once for the write and again a second later, when the recipe watcher saw the same write. It walks it once.
- On Windows a file write could be lost when another thread had the file open for reading: replacing an open file is
  refused there, and the editor polls the feedback file every frame while the share thread writes it, so an entry sent
  to the feedback server could stay unmarked and be offered again. `fs::write_bytes` tries the replace again for up to
  about a second while the file is held open.
- The Engine Feedback panel and the share tick could miss an entry an AI agent wrote: they read the file again only
  when its time changed, and on Windows a file's time moves in steps of about 15 ms, so a write right after a read kept
  the time that read saw. After every change they read the file once more on the next poll.

### Tests

- `test_watchdog`: a busy loop stops by CPU time, a native that waits is not charged, and a script blocked past the wall-clock cap is stopped.

## 0.14.0

FactorIA 0.14.0 (M49) lets you send engine feedback with one button and fixes the gap Roguestory reported about its 3D storybook (FB-0038). The Engine Feedback panel has **Add feedback** and **Send feedback**; nobody writes a share text any more: the Send window lists every entry that would go, all checked, with the exact text that leaves the computer, made from the entry when it has none and checked by an AI when one is set up. `game.click` now names the widget it reached through a page shown on a mesh (`Camera.renderTarget`), and `game.click {id}` clicks widgets that only such a page shows.

### Changes

- **Engine Feedback panel:** two buttons, **Add feedback** and **Send feedback**; the per-entry share editor, the "Sharing..." button and the "Archive closed" button were removed. File > Feedback Settings keeps Always / Ask me each time / Never, GitHub sign-in and the outbox.
- **Send feedback window:** lists the open entries that were not sent and were not refused (all checked), with the exact text of each; **Send** stores the text, queues the checked entries and sends them at once, showing the outcome per row; unchecked entries are marked `skipped` and offered again unchecked; **Cancel** changes nothing. With no mode chosen it shows the consent dialog first; with Never the button is disabled. In Ask mode the old review list is this window. An entry sent before is listed again only when its occurrences went up (at most 3 sends).
- **Add feedback window:** category, severity, title, what is missing, workaround and an optional suggestion, with **Add** and **Cancel**; it has no share boxes.
- **AI check by itself:** when an AI provider is configured, each text of the Send window that was not reviewed is checked in the background with `ai.review_feedback`: a pass may replace the text with the engine-terms rewrite, a fail unchecks the row and shows why; with no provider nothing is shown. `ai.review_feedback` takes an optional `share` (a candidate text to check; nothing is written then).
- Entries that are not open are moved to `ENGINE_FEEDBACK.archive.json` by the editor as soon as it sees them.
- The entries table of the panel is as tall as its rows need (up to two thirds of the panel) instead of at most 180 px.
- `share_skip` (tools/common feedback sharing client) marks entries `skipped` and takes them out of the outbox.
- Docs: AIs should include `share` in every `feedback.report` (docs/AI_GUIDE.md, the project AGENTS.md template); docs/EDITOR.md and docs/ENGINE_FEEDBACK.md describe the new flow.

### Fixes

- `game.click` follows render-target pages. `widget` is now the widget the pointer reached when the button went down, through the same path the mouse takes: a widget on a page shown on a mesh (`Camera.renderTarget` + `MeshRenderer.texture "target:<name>"`) is named, also when the click removes or changes it in that frame (it used to read `null` when the press already turned the page). The result adds `via: {mesh, target}` (the MeshRenderer entity and the render-target camera) when the click went through a page; `render.pick` reports the same `widget` and `via`. `game.click {id}` (and `game.click(id)` in a test) of an Interactable that only a page shows is aimed backwards (widget in the target camera's view, matching point of the mesh, its place on the screen) and clicks where the pointer really reaches that widget; when it cannot, the error says why (no mesh shows the target, mesh inactive / off screen / covered, widget outside the camera's view, a target shown inside another target) instead of "click the mesh with game.click {position}". New `surface_points_at_uv` (fa/scene/mesh_surface.h) and `UiSystem::click_aim` / `interactable_quad`.

## 0.13.0

FactorIA 0.13.0 (M48) makes every command reject arguments it does not know. Until now a key a command's schema did not declare was dropped without a word, so a typo (`{"entiy": ...}`) or an argument from a newer engine (`game.input {"frames": 2}` before 0.12.0) looked like it worked while doing nothing. Now it is an `invalid_arguments` error that names the key, says where it is and suggests the right one; `describe` and MCP's `tools/list` show the closed schemas, so a model client sees exactly what is accepted.

### New

- Command arguments are closed by default. `CommandRegistry::add` sets `additionalProperties: false` on every object schema that declares `properties` (root, nested objects, array items, `anyOf`/`oneOf`/`$defs`), so `describe`, `tools/list` and `api.commands` show what is enforced (`fa::close_object_schemas`). An unknown key fails with `invalid_arguments`: the message names the key and its JSON pointer (`/frame: unknown property 'frame'`), and the hint gives a "did you mean" plus the accepted keys. `additionalProperties: true` or a schema is the explicit opt-out; no engine command needs it. The MCP transport key `_meta` is never counted as an argument. (docs/ARCHITECTURE.md, "Commands")
- `game.input` declares the properties of `mouse` (`position`, `left`, `right`, `middle`), so `mouse.lef` is an error too.
- Tests: a registry-wide test (`command_schema_test`) fails when a command's schema is left open without being listed as open on purpose.

### Changes

- **For game authors:** tools in `tools/*.js` are closed by default too. A key that the tool's `input` does not declare is now an error instead of being ignored, and a tool without `input` (or with `properties: {}`) takes no arguments. Declare every key `run` reads; use `additionalProperties: true` (or a schema) on an object whose keys are open-ended. Calls and tests that pass extra keys need fixing. (docs/EXTENDING.md, "Closed by default")

## 0.12.0

FactorIA 0.12.0 (M47) fixes the two gaps the user's own game, Roguestory, reported while building its 3D storybook. A camera can now choose what it draws by entity tags (`Camera.showTags` / `Camera.hideTags`), so the pages a render target shows no longer have to live thousands of units away from the desk, and a press sent with `game.input` while the game is paused in the editor is no longer lost before the next step.

### New

- `Camera.showTags` / `Camera.hideTags` (culling mask by entity tags): a camera draws an entity when it, or an ancestor, has one of `showTags` (empty = any) and neither it nor an ancestor has one of `hideTags`. It applies to everything drawn in world space on screen and render-target cameras, to shadows, and to the pointer (Interactable hit tests, the mesh that shows a render target, `render.pick`, `game.click`, editor picking); screen-space UI and lights are not filtered. `factoria validate` warns about tags no entity or prefab carries (with a suggestion) and errors on a tag in both lists. (docs/RENDERING.md, "Choosing what a camera draws")
- `game.input` takes `frames` (like `game.step`): it steps that many frames right after applying the input, also while paused, and returns the frame reached.

### Fixes

- `game.input` presses (actions, keys, mouse buttons, gamepad buttons, touches, `back`) injected while the game is paused in the editor were lost before `game.step` could simulate a frame, so `input.pressed(...)` never fired; the pressed/released edge now waits for the next simulated frame.
- An Interactable that stops being a hit target (inactive, or hidden from its camera) no longer keeps its hovered/pressed/focused flags.
- On OpenGL, a `Camera.renderTarget` drawn before any `Camera.colorFilter` had been used left its texture blank and broke the colour filter for the rest of the run: the flip copy asked for the filter's pipeline before its shader existed and the failed pipeline stayed cached. The pipeline now makes its shader itself, and a pipeline asked for without a ready shader is reported and never cached.

## 0.11.1

FactorIA 0.11.1 sets the rules for the feedback server and for every FactorIA space. The server's page now says what reports it accepts (only about the engine, no personal data, nothing illegal or abusive, no abuse of the server), that reports breaking the rules are deleted and their sender may be refused, that sending a report lets the developer use the idea freely, and that the server comes with no warranty and may stop at any time. A code of conduct covers the repository and the feedback server.

### Changes

- The feedback server's page (`GET /`) adds "Rules for reports" and "No warranty" (docs/design/FEEDBACK_SHARING.md, `GET /`), and points to File > Feedback Settings in the editor to stop sending.
- `CODE_OF_CONDUCT.md` (new): what is expected and what is not accepted in issues, pull requests, discussions and the feedback server, including what an AI posts for you; how it is enforced and how to report. The README links it.

## 0.11.0

FactorIA 0.11.0 (M45) spends fewer tokens and takes the AI tools you already use. The built-in agent gets the core commands in full and a one-line catalog for the rest (a step sends about 62 KB instead of 324 KB), the topic guides became skills read only when needed (system prompts 16% to 46% shorter), and three savers learn from your runs: a loop guard, tool groups to load up front and project facts, each applied only when you accept. Plugins, skills and hooks load into the AI runs from your `ai.json` or a trusted project, with Claude Code's hook events running for every provider and two of FactorIA's own around every engine command; a downloaded project's Claude Code settings no longer apply before you trust it. **Add TokenEconomizer** installs Microsoft's Claude Code plugin in one click; six paid runs measuring it are in docs/AI_COSTS.md.

### Changes

- The built-in AI agent (API providers) no longer sends the definitions of all 186 commands on every step (about 320 KB, around 85k tokens, before any conversation). It gets the core commands in full (files, docs, scene editing, running and looking at the game, validating and testing, scripts, `feedback_report`, `assets_list`, `assets_import`), the commands of its role's tool groups in full, and a catalog in the system prompt: one line per other command. Two loop tools reach those: `tool_describe` returns the full definition of commands and `tool_call` runs one under its own name (the chat and the events show the command). A wrong call to a catalog command comes back with its input schema. The tool list is fixed for the whole run, so the prompt cache keeps working. On the scripted task of `tools/cli/tests/tool_catalog_test.cpp` (real command registry, no model) a step sends 62 KB instead of 324 KB; the numbers and the reasons are in docs/AI_COSTS.md and docs/AI_PROVIDERS.md ("Tool groups and the catalog"). A registry whose left-out definitions add up to under 6000 bytes is still offered in full. Read-only roles (`artCritic`, `reviewer`) see only the read-only commands in the catalog and cannot reach any other one through `tool_describe` / `tool_call`.
- `roles.<role>.toolGroups` in `ai.json` (new): command categories (`assets`, `anim`, `ui`...), command names or `"all"` that a role always gets in full. Default: the artist loads `assets`, the audio role `assets` and `audio`; `["all"]` brings back every command in full.
- Claude Code 2.1.312 already defers the tools of MCP servers behind its own tool search; FactorIA sets nothing for it (docs/MCP.md, "Tool definitions and Claude Code").
- `scene.import_ascii`'s warning about a legend glyph no row uses now says to remove it or to move a legend shared by several maps into a `legendFrom` file (4 of 6 benchmark runs asked for a shared legend without finding it).
- The Claude Code run's start line suggests checking `factoria` on PATH only when FactorIA's own MCP server failed to connect, not for your other MCP servers.

### New

- Extensions for the CLI agents: an `extensions` section in your `ai.json` and a project file `.factoria/extensions.json` (no keys in it) load plugins (a folder, a `.zip`, or a Claude Code `name@marketplace` you installed), skill folders and hooks (Claude Code's `hooks` shape) into the AI runs, each entry with `roles` and `enabled`. Claude Code gets one `--plugin-dir` per plugin, the skills as a plugin FactorIA writes for the run, and the hooks in a private `--settings` file, both deleted when the run ends; `inheritUserPlugins: false` starts it with `--setting-sources project,local` (it drops all your user-level Claude Code settings, permissions and env included). Codex gets the skills (and no plugins or hooks, which the run says), see the Skills entry below; a generic CLI takes them through the new `{plugin_dirs}` and `{settings}` placeholders; the API providers (anthropic, openai-compatible) take the skills (see Skills) and run the hooks in their own loop (see Hooks for every provider), with no plugins, and `ai.extensions` and the run say so. Mistakes are reported with the JSON pointer, a fix and "did you mean". Guide: docs/AI_PROVIDERS.md, "Extensions".
- A project's plugins and hooks run only after you trust the project once (AI settings > Extensions > Trust this project, no command can grant it); the trust is kept per project path and file hash in `ai-trust.json` next to `ai.json` and ends when the file changes. The project's skills (text only) load without it.
- Claude Code in `-p` mode skips its own workspace-trust dialog, so a downloaded game's `.claude/settings.json` or `settings.local.json` used to take effect in AI runs without asking: it runs programs (hooks, `enabledPlugins`, `extraKnownMarketplaces`, `statusLine`, `apiKeyHelper`...) and widens what the AI may do (any `env`, such as a base URL or `BASH_ENV`; `permissions.allow` rules; a `defaultMode` other than `default`; `additionalDirectories`). The same project trust now covers them (hash of both files): until you trust the project, Claude Code starts without the `project` and `local` setting sources (`--setting-sources user`, or an empty list with `inheritUserPlugins: false`), so the rest of those files is not applied either. The run output, `ai.extensions` (`claudeSettings`, `projectSettingsSkipped`) and `factoria ai doctor` say what was skipped and how to trust the project; a setting FactorIA does not know counts too (listed as `unknown setting KEY`, the name only), so only keys known to be harmless load without the trust; the deny-rule report still reads the files.
- Deny rules on FactorIA's own tools (`mcp__factoria`, `mcp__factoria__*`, `mcp__factoria__<tool>`) in the project's `.claude/settings.json` or `settings.local.json` are reported in the run output, in `factoria ai doctor` and in `ai.extensions`, with the file, the rule and how to restore the tool.
- The command `ai.extensions {role?}` (read-only) shows the entries, what stops each from loading and what every role's provider receives; `factoria ai doctor` has an Extensions section and a `--project DIR` flag.
- The editor's AI settings window has an **Extensions** tab next to External tools: add a plugin or skill folder (for you or only for the project), paste hooks JSON, switch roles on and off per entry, Trust this project, and Save.
- Skills for every provider (M45.3): the Agent Skills format (a folder with a `SKILL.md` whose frontmatter has `name` and `description`, and files beside it), so a skill written for Claude Code or Codex works unchanged. Sources, the project's winning over yours and yours over the engine's: the project's `skills/`, `~/.factoria/skills`, and FactorIA's own, baked into the binary: the topic guides that were in the always-sent prompt and in the project's `AGENTS.md` (`custom-shaders`, `glow-and-effects`, `tile-levels`, `physics-3d`, `web-requests`, `menus-and-finishing`, `publishing-and-exporting`, `inspect-the-picture`, `make-art`, `make-audio`, `review-ready`). The built-in agent gets one line per skill in the system prompt and reads one with `skills_read`; Claude Code gets them as a plugin FactorIA writes for the run and Codex in the project's `.agents/skills` for the run (removed when it ends, git-ignored); generic CLIs get the prompt lines and `skills_read`. System prompts are 16% to 46% shorter (fast, reviewer and critics unchanged) (orchestrator 5 553 -> 4 647 bytes, artist 5 122 -> 3 048, audio 4 921 -> 2 669) and the `AGENTS.md` of a new project is 12 KB instead of 17.7 KB. New commands `skills.list {role?}`, `skills.read {name, file?}` and `skills.new {name, description?, scope?}`; a skill entry may name an engine skill as `"path": "engine:<name>"` to set its roles or switch it off; `factoria validate` checks the project's skills (frontmatter, a name that differs from the folder, "did you mean"); the AI settings' Extensions tab has a Skills table with On and one box per role. Guide: docs/SKILLS.md. (M45.3)
- `ai.tool_plan {role?, catalog?}`: which commands a role gets as tools in full and which only as catalog lines, with estimated sizes.
- Where the context goes: each model call of the built-in agent records the estimated split of its request (system prompt, command catalog, tool definitions, conversation) in the session log; `ai.session_timeline` returns it as `context` (per step and totals), and the Context bar of the editor's AI panel shows it in its tooltip.
- Hooks for every provider: the events of Claude Code's hooks (`SessionStart`, `UserPromptSubmit`, `PreToolUse`, `PostToolUse`, `PostToolUseFailure`, `Stop`, `SessionEnd`) now run in FactorIA's own loop for the API providers (anthropic, openai-compatible), with the same JSON on stdin and the same decisions on stdout (`additionalContext`, block a tool call with a reason, change its arguments, stop the run, keep the model going from `Stop`), so one hook script serves Claude Code and the built-in agent. Two events are FactorIA's own: `beforeCommand` and `afterCommand` fire around every command of the engine for every caller (an MCP client, the CLI, the editor, a script, the AI) and a `beforeCommand` hook can refuse a command (`blocked_by_hook`) or change its arguments. A hook is a program (your own `ai.json`, or a project you trust) or a JavaScript module of the project's `hooks/` folder (`{"type": "js", "module": "hooks/guard.js"}`) that runs in a sandbox with no files, network or programs and needs no trust; Claude Code gets the same hooks in its `--settings` file, a JS module through the new `factoria hooks run`. Each handler has a `timeout`; every run is a `hook` line of the session log and the run timeline, a failing hook is reported in the chat and in the command's result and never silent. New commands `ai.hooks` (the hooks and the recent runs) and `ai.hooks_test` (run the hooks of one event with a sample input); the editor's AI settings > Extensions tab has a Hooks section with each handler, where it runs and the recent runs with the failures in red. Docs: docs/HOOKS.md. (M45.4)
- The engine's own token savers for the built-in agent (M45.5), each with a switch in AI settings > Extensions > Token savers and in the `savers` section of `ai.json`: a loop guard (the same command failing with the same error code three times in a turn gets one short redirect without a model call; an optional `loopGuardJudge` role writes it and its tokens count in the run's cost and limits), learned tool groups (per project, the groups runs keep loading are proposed for loading up front and applied only on accept) and project facts (a failure fixed in several runs proposes one line for AGENTS.md, written only on accept). Commands `ai.savers`, `ai.saver_group` and `ai.saver_fact`; editor autotest section S2.
- One-click **Add TokenEconomizer** (M45.6) in AI settings > Extensions, and the command behind it, `ai.plugin_install {marketplace, plugin, roles?, name?, note?, requiresPython?, preset?, dryRun?}`: it runs the Claude Code CLI's own `claude plugin marketplace add` and `claude plugin install --scope user` (skipping a step the CLI's lists already show as done; an install for one folder does not count), then adds a `name@marketplace` plugin entry to your `ai.json` `extensions` with the other keys kept; `dryRun` reports the commands and which are needed; `preset: "tokeneconomizer"` is Microsoft's TokenEconomizer (marketplace `microsoft/TokenEconomizer`, plugin `tokeneconomizer@tokeneconomizer`, Python 3.10+ checked first). The button confirms what will be installed before running anything, installs off the UI thread with its steps shown, reads **Installed** when the plugin is installed and listed, and offers only the entry when it is installed without one. Only the user starts it: the built-in agent and every MCP server (`factoria mcp`, the editor's endpoint) refuse to list or run it. Docs: docs/AI_PROVIDERS.md, "Installing a plugin".

## 0.10.0

FactorIA 0.10.0 (M46) lets the feedback of games made by other people reach the engine developer: an entry of `ENGINE_FEEDBACK.json` may carry a generic copy of the gap in engine terms only, a sanitizer strips anything about the game, nothing leaves the computer until the person chooses Always, Ask me each time or Never (no command can choose for them), the user's own AI can check a report before it goes, and the reports reach the developer's own free Cloudflare Worker, which stores no identity and enforces rate limits and bans. The developer pulls them with `factoria feedback pull` (AI triage with quarantine), ranks them in `feedback collect` and ships a list of fixed gaps that closes matching entries on every user's machine.

### New

- Feedback server (M46.1, `tools/feedback-server`): a Cloudflare Worker with D1 (free plan, plain JavaScript, no build step) that receives the generic engine-gap reports of M46: validation and field limits, per-installation merge of similar titles, rate limits per installation, network and server with `429`/`Retry-After`, bans with purge, the optional GitHub sign-in credential, the admin API with a stable pull cursor, and a plain privacy page. Installation, reporter and network keys are keyed hashes: the server never stores the installation id, an IP, a GitHub login or id, or a token. `deploy.sh` / `deploy.ps1` deploy it in one command and write `feedback-admin.json` next to `ai.json`; `node --test` tests run in ctest (`feedback_server`) when Node.js 20+ is found. Design: docs/design/FEEDBACK_SHARING.md.
- Sharing feedback with the engine developer (M46.2, client): an entry of `ENGINE_FEEDBACK.json` may carry `share`, a generic copy of the gap in engine terms only, and `reviewed`; `feedback.report` and `factoria feedback add` take both. A deterministic sanitizer removes paths, file names, URLs, e-mail addresses, quoted text, the project's own names and control characters; nothing is sent until the user runs `factoria feedback sharing always|ask|never` (no engine command can change it). New commands `feedback.share_preview`, `feedback.share_status`, `feedback.share` and `feedback.check_fixed`; an outbox with retries (1 min, 10 min, 1 h, then daily); optional `factoria feedback signin github` (device flow). Each release's list of fixed gaps (`feedback/fixed.json`) closes matching open entries when the editor opens a project. The server address and GitHub client id are the CMake cache variables `FA_FEEDBACK_URL` and `FA_FEEDBACK_GITHUB_CLIENT_ID` (empty: sharing says it is unavailable). Guide: docs/ENGINE_FEEDBACK.md, "Sharing with the engine developer".
- Sharing feedback in the editor and the AI review before sending (M46.3): the first time a project with feedback entries is open (or an entry with `share` is written) while the mode is unset, a consent dialog says in plain words what is sent and what never is, previews the next report exactly as it would leave the computer and offers Always, Ask me each time and Never (only a person can answer it; no command, MCP tool or script sets the mode). File > Feedback Settings has the mode, the installation id with Reset id, the GitHub sign-in (code, address, a button that opens it, login, Sign out), the outbox (waiting, next retry, last error) and Send now. In ask mode a notification opens a review list that shows each share text as it will be sent, with Send and Don't send per entry and for all. The Engine Feedback panel has a share column (not shared, waiting, sent, rejected with its reason, skipped), the share text in editable boxes with their limits (saving sanitizes and checks again), Suggest (project names removed), Review with AI, and the same boxes in the Add entry form. New command `ai.review_feedback {id}`: the `fast` role checks that the gap is real, about the engine and not possible yet, marks the entry `reviewed` and rewrites `share` in engine terms if needed; it sends nothing. Editor autotest section E2. Guide: docs/EDITOR.md, "Sharing feedback"; docs/ENGINE_FEEDBACK.md.
- Engine developer side of feedback sharing (M46.4): `factoria feedback pull` downloads the reports users shared into an inbox (one `ENGINE_FEEDBACK.json` per installation, merged by `shareId`, `--full` to refresh occurrences), a cheap AI role (`fast`) judges them valid, doubtful or junk with junk going to `feedback quarantine`, `feedback ban|unban|bans|delete|stats` manage the server, and `feedback fixed add|list` maintain `feedback/fixed.json`. `feedback collect` now scores `severity weight x trust x min(occurrences, 3)` per project (anonymous installations count half) and reports installations and verified installations. Guide: docs/EXTENDING.md, section F.1.

## 0.9.0

FactorIA 0.9.0 (M44) brings what a 3D book needs, found by the user's game Roguestory: scripts build and deform meshes in code (`mesh.create`, `mesh.update`, `mesh.save` to a `.glb`) with vertex colors, a camera can draw live into a texture that a model shows (`Camera.renderTarget`, `"target:<name>"`) and the pointer reaches the buttons on it through the mesh, `render.captureTexture` photographs any part of the world off-screen at a scale you choose, world Text can be sized in meters and lit, a project tool always runs the code on disk, and AI session logs carry times that `ai.session_timeline` turns into a timeline.

### New

- Render targets: a `Camera` with `renderTarget: "book"` and `renderTargetSize: [w, h]` (1..4096) draws live into the texture `"target:book"` every frame instead of the screen, 2D or 3D. The id goes wherever a texture path does: `MeshRenderer.texture`, `normalMap` and texture `materialParams`, `Sprite.texture`, `Panel.texture`, `Button.icon`. A target is drawn before the cameras that sample it, so a screen on a model is never a frame behind. A camera that sees the surface showing its own target gets the missing-texture checker there and one error that says how to fix it; two targets that show each other work, each one frame late. A target camera is never drawn to the screen, `camera.main`, in `camera.all` or the audio listener. `RenderStats` has `renderTargets`. `factoria validate` accepts `target:<name>` in texture fields (and reports an empty or invalid name). Guide: docs/RENDERING.md.
- The pointer through a mesh: a mouse or finger over a `MeshRenderer` that shows a render target reaches the `Interactable` entities its camera sees, by the hit triangle's UV: hover, click, toggles and slider drags work on a flat quad, a curved model (cylinder, sphere, bent screen) and glTF models, and a slider drag goes on after the pointer leaves the mesh. A book with turning pages and working buttons needs no overlay. Limits (docs/RENDERING.md): the nearest page mesh wins and other 3D things in front do not block the pointer; a Sprite, Panel or Button that shows a target forwards no input; in a test aim with a screen position, not the id of a page entity.
- `render.captureTexture({ entity | rect, space: "world", scale })` draws a part of the world off-screen at `scale` pixels per world unit and returns a `Texture`: a hidden, covered or off-camera subject works, no frame has to be drawn first (it works in `onStart` and in tests), and the picture may be up to 4096 x 4096 (the whole-frame form keeps its 2048). The background is transparent and the colour is straight alpha. A request over 4096 is an error that names the largest scale that fits.
- Procedural meshes: `mesh.create({ positions, normals?, uvs?, tangents?, colors?, indices, submeshes? })` returns a `Mesh` whose `id` (`"mesh:N"`) goes in `MeshRenderer.mesh` (and `Collider3D.mesh`), so a script builds terrain, a deformed body or a generated tree without writing a glTF file. Missing normals and tangents are computed; `submeshes` give runs of the index list their own material. `mesh.update` replaces what is given and keeps the rest, reusing the GPU buffers while the data fits; `mesh.destroy` frees the mesh; `mesh.save(m, path)` writes a `.glb` (one primitive per submesh, materials, `COLOR_0`) that loads back as a normal asset; `mesh.exists` and `mesh.list` ask what is alive. The same operations are the commands `mesh.create`, `mesh.update`, `mesh.destroy`, `mesh.save`, `mesh.list` and `mesh.info`.
- Bounds, frustum culling, shadows, the editor's picking, outline and selection and `Collider3D` convex and mesh shapes use the real geometry; the inspector shows a procedural mesh's vertex and triangle counts. A `Collider3D` on a mesh rebuilds its shape on every update. Meshes are released when a scene loads; an id that is destroyed, from an older scene or unknown gives an error that says so, and an entity that still names it draws the placeholder box. Limits: 256 meshes, 1 048 576 vertices and 6 291 456 indices each.
- `factoria validate` rejects a `mesh:N` id in a scene or prefab (the mesh would not exist when the file loads).
- Vertex colors are drawn: `colors` of `mesh.create`/`mesh.update` (rgb or rgba per vertex) multiply the submesh material's base color like glTF `COLOR_0`, in every 3D path (lit, `unlit`, instanced batches, skinned, the shadow pass of `clip` materials, custom materials), and glTF models that carry `COLOR_0` are drawn with it too (before it was ignored). Custom material snippets read it as `i.vertex_color` and, in `vertex()`, `v.color`. A mesh without colors looks exactly as before. Each mesh vertex is 4 bytes larger (52 instead of 48) to carry the color as four normalized bytes.

### Changes

- `render.textureFromPNG` accepts pictures up to 4096 x 4096 (it was 2048), the size run-time textures could already have.
- `project.export` takes `player` like the CLI's `--player`: the desktop or web player to bundle, so an AI can export for another OS with a player built there.

### Text and sprites

- `Text.fontSize` (and `minFontSize`) go down to 0.001, so a world Text in a 3D scene can be sized in meters (a 7 cm title is `fontSize: 0.07`). The glyphs are still rasterized for the size they have on screen, so tiny world text stays sharp. docs/TEXT.md has a new section, "Text in a 3D scene", on how Text behaves under a perspective camera.
- New `Text.lit` (default false): a world Text is shaded by the scene's 3D lights and `SceneSettings.ambientLight` like a lit material (once per Text, at its origin; no shadows).
- New `Sprite.vertexColors`: a flat `[r, g, b, a, ...]` per grid vertex of a deformable sprite, multiplied with `color`. A scene or prefab whose length is not `(meshColumns + 1) * (meshRows + 1) * 4` fails to load with an error that names the length it needs; a script that writes a wrong length gets one warning and the colours are ignored.

### Fixes

- An entity destroyed during a frame (and its children) is no longer drawn in that frame: the renderer used to draw it until the end of the frame, so a group destroyed and rebuilt in one frame was drawn twice for one frame, and a `render.captureTexture` taken the next frame showed both. docs/SCRIPTING.md says which frame a capture shows.
- A project tool (`project_<name>`, from `tools/*.js`) now runs the code on disk: when its file, or a module it imports, was edited since it was loaded, the tool is re-imported before the call, as `script.eval {module}` does. This holds in the editor's MCP session, `factoria mcp` and `factoria call`. An object result also carries `toolVersion` (`file`, `hash` of the file as it ran, `loadedAt`), so a stale tool is visible.
- On Linux, the MCP server now tells the AI to restart the client (or `/mcp`) after it added the missing `"timeout"` to the project's `.mcp.json`: Linux stamps files with a clock a tick behind, so the write looked older than the server's start.
- An `.anim.js` module that runs out of memory with many small allocations now says "ran out of memory" and names the line, instead of "threw null": the runtime keeps room to build the error.

### AI

- Every event of `.factoria/ai/sessions/*.jsonl` carries `t` (UTC time with milliseconds). `tool_end` carries `ms` (how long the tool ran), a `thinking` event carries `ms` (the time since the event before it, so the duration is kept when the text is hidden), and the built-in agent's `assistant` lines carry `ms` (the model call) and its `tool_results` entries the tool name and `ms`.
- New read-only command `ai.session_timeline {session?, minGapSeconds?}` (newest session by default): the gaps longer than N seconds with what was going on (a tool, thinking, waiting for the model, waiting for the user) and totals per kind and per tool. A log from an older engine has no times and the command says so.

## 0.8.2

FactorIA 0.8.2 restarts the editor into the FactorIA icon you pinned in the Dock, instead of opening it as a second FactorIA icon next to it.

### Fixes

- Restarting the editor on macOS (the update notice's Restart) no longer leaves two FactorIA icons in the Dock: the editor used to start the new one with `open -n` while it was still quitting, and macOS gives a second instance of an app its own icon. A helper now waits until the old editor has quit and then opens `~/Applications/FactorIA.app` the way the Dock does (with `open -n` only if the old editor is still running after 30 seconds).

## 0.8.1

FactorIA 0.8.1 keeps one FactorIA icon in the Dock when an editor that is still open restarts after a newer FactorIA was installed over it.

### Fixes

- Restarting the editor (the update notice's Restart) after a newer FactorIA was installed over it on macOS no longer opens the new editor as a second Dock icon: the restart goes through `~/Applications/FactorIA.app` whenever that app opens this `factoria` and passes the project on, whichever version wrote it (an out-of-date one used to be skipped, so the editor started the bare program).

## 0.8.0

FactorIA 0.8.0 (M43) lets the AI use external tool servers (MCP) that you configure in the editor's AI settings, such as Scenario for generating game art: Claude Code, Codex, the generic CLI agent and the API providers all get them, and the AI calls them only when they help.

### New

- External tool servers: a top-level `mcpServers` object in your user `ai.json` (web services by address, with headers or a key from an environment variable, or programs on your computer) that the AI may use when it sees fit. Claude Code gets them through a generated `--mcp-config` (and `mcp__<name>` in `--allowedTools`), Codex through `-c mcp_servers...` (keys stay out of the argument list), the generic CLI agent through the `{mcp_config}` placeholder, and the API providers through a built-in MCP client (Streamable HTTP and stdio) whose tools appear to the model as `<server>__<tool>`. OAuth is not implemented: use a key. `docs/AI_PROVIDERS.md`, "External tools (MCP servers)".
- The AI prompt has an "External tools" section naming the servers that are connected for the run.
- Command `ai.tool_servers` (a server's state, or a connection test), and `factoria ai doctor` lists each server with what is wrong with it.
- AI settings > External tools tab: add or edit a server with a form, Test it, paste a Claude Code `.mcp.json`, Remove; Save keeps the other keys of `ai.json`. Editor autotest section D2.
- `fa::ChildProcess` in the core module (a program with piped stdin and stdout, for stdio MCP servers), with tests; the Windows version is not yet built or run.

## 0.7.5

FactorIA 0.7.5 stops the editor's AI watchdog from cancelling healthy agents on macOS and says why any run was cancelled.

### Fixes

- macOS: the editor's AI watchdog no longer stops a healthy agent with "process is gone". `process_tree` read the count `proc_listallpids` returns as bytes and kept only the newest ~50 of ~550 processes, so after a few minutes of an agent starting processes the orchestrator's own pid fell off the list. The list is sized from the count now. Before it stops a run for a missing process, the watchdog and Check activity also ask the OS directly (new `fa::process_alive`: `kill(pid, 0)`, or `OpenProcess` + `GetExitCodeProcess` on Windows) and never stop a run that produced an event in the last 10 seconds.
- A run that ends cancelled says why: the session transcript's end event has a `cause` (`user_stop`, `stuck_stop`, `watchdog_process_gone`, `activity_check_process_gone`, `project_closed`, `editor_closing`, `editor_restart`, `run_ended`) and an error such as "cancelled: the editor's watchdog thought the agent process was gone"; the chat's error line and the `ai_run` result of a cancelled sub-agent carry the same text.

## 0.7.4

FactorIA 0.7.4 makes the editor restart through the pinned launcher also from the start screen, so the Dock keeps one FactorIA icon.

### Fixes

- Restarting the editor from the update notice with no project open also goes through the pinned launcher, so the Dock or taskbar keeps one FactorIA icon (it used to start a bare `factoria editor` that showed a second one).

## 0.7.3

FactorIA 0.7.3 fixes a false error of `factoria validate` on glTF texture paths and makes the real ones say how to fix them.

### Fixes

- `factoria validate`: the error for a glTF/glb texture or buffer uri that points nowhere resolves the uri against the model's folder and names the real path (it used to name the model's own folder, which exists, and flagged uris such as
  `../../../assets/textures/x.png` that go up to the project root and back in, which load fine), says plainly when the uri climbs out of the project folder, and suggests the corrected uri when the file exists in the project.

## 0.7.2

FactorIA 0.7.2 keeps one FactorIA icon in the Dock or taskbar when the editor restarts after an update.

### Fixes

- Restarting the editor after FactorIA was updated (Restart, or the in-editor updater) no longer adds a second FactorIA
  icon next to the pinned one. On macOS the editor reopens through `~/Applications/FactorIA.app` (`open -n`) when that
  launcher is the one of this factoria, and the launcher now passes its arguments on, so the project is reopened; older
  launchers are rewritten at the next start. On Windows the restart runs `FactorIA-Editor.exe` when it is next to
  `factoria.exe`. On Linux the `.desktop` entry gets `StartupWMClass=FactorIA`, so the window groups with it.

## 0.7.1

FactorIA 0.7.1 fixes the editor's recent projects: the list survives updates, reinstalls and starting the editor
straight on a project.

### Fixes

- The editor no longer forgets its recent projects. Starting straight on a project (`factoria editor <dir>`, the
  restart after an update) used to overwrite `~/.factoria/editor_recent.json` with that one project, and File > Recent
  Projects was empty. The list is now read when the editor starts, merged with the file on every save, compared by
  normalised path, and entries whose folder is missing are hidden but kept (and are dropped first when the list is full).

## 0.7.0

FactorIA 0.7.0 animates characters built in parts: a keyframed clip (`*.anim.json`) moves the parts of an entity and the
Animator plays it by name, with cross-fades, layers, masks, events and the state machine; `Bone2D`, `SpriteSkin` and
`IK2D` bend a sprite with its bones and make a chain reach for a target; AIs make and check clips with `anim.*`,
`bones.create` and `skin.*` commands, and `factoria validate` checks every clip; the editor has an Animation panel
(dopesheet, curves, record mode, onion skin) and bone tools (draw a chain, bind, paint weights, drag IK targets); and
`assets.bake_sheet` bakes an Animator clip by name into a sprite sheet. Sky Hopper's hero is built in parts with bones,
clips and IK feet, and its crawler is baked from parts into a sheet.

Keyframed 2D clips

- `*.anim.json` (format `factoria.anim/1`, `schemas/anim.schema.json`) is a clip of keyframed tracks: each track drives
  one field (or one channel such as `rotation.z`, `color.a`) of the entity that plays it or of a child found by names
  (`"body/arm_l"`). Keys interpolate `linear`, `step`, `bezier` (in/out tangents, smooth when missing) or with any
  easing of `tween()`; numbers, vectors, colours and angles interpolate, bools, ints, enums, assets and rects step.
  Clip events (`{t, name, data}`) fire once per loop.
- The Animator plays these clips when it has no glTF `model`: `clips: {"walk": "anim/hero_walk.anim.json"}`. `play`,
  `speed`, `loop`, `time`, clip events, `anim.finished` and the state machine work as with glTF clips. A cross-fade lerps
  the fields, angles take the short way round and fields that only step switch at half the fade. A field the current
  clip does not drive goes back to where it rested.
- `layers` play more clips at once: `{name, clip | states, weight, mode: override | additive, mask: [paths], speed, loop}`.
  `entity.animator.setLayerWeight(layer, w)` and `playLayer(layer, clip, fade)` drive them from scripts, and
  `entity.animator.sample(clip, t)` poses the parts without playing.
- The driven fields are a runtime pose: `scene.save`, prefabs and the editor's Play/Stop write the rest value, not the
  pose. The Animator runs in the fixed step; `IK2D` runs right after it, before drawing.
- Clip files are cached by path and modification time and reloaded when they change. Errors name the file and the JSON
  pointer, and teach: a path gets "did you mean" over the names under the entity; a field that cannot be animated lists the
  ones that can; keys out of order or past `duration`, a value of the wrong type and two tracks on one channel are caught.

2D bones, skinned sprites and IK

- `Bone2D` (`length`, `minAngle`, `maxAngle`) turns any entity of the hierarchy into a bone: it runs `length` along the
  entity's +X axis and is posed through its Transform, so clips, tweens and scripts move it like any other entity.
- `SpriteSkin` (`bones`, `weights`, `bindPose`, `outline`, `outlineDetail`) bends the 2D mesh of the Sprite on the same entity
  (`meshColumns` x `meshRows`, or with `outline: true` a grid cut to the opaque pixels of the texture) with up to 4 bones per
  vertex from a bind pose recorded when the scene loads. `weights: "auto"` weights each vertex by its distance to the bones;
  an array gives your own. The vertices are deformed on the CPU into the existing 2D vertex stream: no new shader, and skinned
  sprites batch like mesh sprites. `entity.bounds()`, picking and the selection outline use the deformed mesh.
- `IK2D` (`target`, `chainLength`, `bend`, `weight`, `solver`: `twoBone` or `ccd`) turns the bones of a chain so the tip of its
  bone reaches the target, within the bones' angle limits. It runs every fixed step after the animators and before drawing, and is
  deterministic.
- `debug.bones(root?, color?)` draws the bones of an entity and its descendants (all bones without `root`); the editor's
  Selection overlay draws the bones of the selected entity. docs/ANIMATION.md, section "Bones and IK".
- A new fixture, `tools/cli/tests/fixtures/skinned-sprites` (50 skinned sprites, 10 with IK, one draw call), has a perf budget.

Commands for AIs: make clips and check them

- `anim.create_clip`, `anim.set_keys`, `anim.remove_keys`, `anim.move_keys`, `anim.set_interp`, `anim.add_track`,
  `anim.remove_track`, `anim.add_event`, `anim.move_event`, `anim.set_event`, `anim.remove_event` and `anim.set_clip` make and
  edit `*.anim.json` clips. Each checks the whole file with the loader's rules before writing, and returns `undo`, a call of
  `anim.restore` that puts the previous document back (or deletes a new file).
- `anim.list` describes an Animator's clips, `anim.pose` poses an entity at a time of a clip, `anim.filmstrip` draws a labelled
  grid of poses (with `onionSkin`) and `anim.check` reports `no_change`, `loop_jump`, `unknown_part`, `leaves_view` and
  `ik_out_of_reach` findings that say how to fix them.
- `bones.create`, `skin.bind`, `skin.auto_weights` and `skin.set_weights` (set, add, smooth) make a bone chain, skin a Sprite to it
  and paint its weights.
- `factoria validate` checks every `*.anim.json` and the clips each Animator names: a missing file, schema errors and tracks that
  resolve to no part of that entity.
- docs/AI_GUIDE.md, section 9.25.2: a character in parts, step by step; the artist role's prompt points to it.

Editor: the timeline and the bone tools

- View > Animation edits the 2D clips of the selected entity's Animator: a clip list with New clip, a dopesheet and a curve view
  (bezier tangent handles), a time ruler with scrubbing that poses the entity without touching the scene file, play / loop /
  speed, event markers, snapping to an fps the panel offers, and key editing (select, box, drag, scale, copy / paste at the
  playhead, delete, linear / step / bezier / easing from a context menu). Every edit is an `anim.*` command and one Undo step.
- Record mode (REC): moving, rotating or scaling a part with the gizmo, or changing an animatable Inspector field, writes a key at
  the playhead (`anim.set_keys`) instead of the rest value; the viewport gets a red frame. The onion skin draws faded poses before
  and after the playhead.
- View > Bone tools: draw a bone chain by clicking points in the viewport (`bones.create`), bind a sprite to bones (`skin.bind`),
  see the weights of one bone as coloured dots and paint them with a brush (add / set / smooth, `skin.set_weights`, one stroke =
  one Undo step), and drag the targets of IK2D chains. Editor autotest sections B2 and C2; docs/EDITOR.md.

Baking clips, and a character built in parts

- `assets.bake_sheet` clips take `clip`: `{"name":"walk","clip":"walk"}` plays that clip of the entity's Animator (a
  `*.anim.json` clip or a glTF animation) from time 0, with no cross-fade and the state machine off, and bakes it. `frames`
  defaults to the clip's duration times `fps` and `loop` to the clip's own. An unknown clip lists the clips with "did you
  mean", an entity with no Animator says what to add, and `clip` with `call` or `event` is rejected. The recipe in the
  provenance regenerates the sheet. docs/ASSETS.md, "Bake by clip name".
- Sky Hopper's hero is built in parts (child Sprites with pivots at the joints, Bone2D legs with IK2D feet placed by a raycast,
  a skinned scarf, idle/walk/jump `.anim.json` clips and an Animator state machine) and its crawler is baked from a rig into
  `assets/crawler_sheet.png`; docs/ANIMATION.md, "Example: a character built in parts (Sky Hopper)". Its perf budget grows from
  17 to 36 entities (the hero's 19 parts; 6 draw calls as before, the parts share one atlas).

## 0.6.0

FactorIA 0.6.0 draws animations with code and bakes them into sprite sheets: a JavaScript module or an animated SVG
becomes a sheet in one call (`assets.animate_svg`), an entity the engine draws is baked frame by frame
(`assets.bake_sheet`), every asset a tool made records its recipe so `assets.regenerate` makes it again when its source
changes, and `SpriteAnimator` plays a sheet's clips by name.

Animations drawn with code

- `assets.animate_svg` (MCP `assets_animate_svg`) bakes an animation you write as code into a sprite sheet PNG and its
  `sheet` entry of assets.json in one call. `source` is a project JavaScript module (`art/coin_spin.anim.js`) whose default
  export `frame({t, frame, frames, fps, progress, params, rng})` returns the SVG of each frame; it runs in a sandboxed
  QuickJS context (the language only: no engine bindings, no DOM, no timers, no files; imports of project files with a
  relative path), with a seeded `Math.random`, a fixed `Date`, a time limit per frame (`timeLimitMs`) and a memory limit.
  A mistake names the module, line, column and frame. `svg` (or a `.svg` source) is one SVG with SMIL animation
  (`<animate>`, `<set>`, `<animateTransform>`, `<animateMotion>` with `values`, `keyTimes`, `keySplines`, `begin` sync-bases,
  `repeatCount`, `fill="freeze"`...) sampled at every frame; what is not sampled is a warning that names the element.
- Every frame goes through the same rasterizer as `assets.rasterize_svg` (same `style`, `styleStrength` and `seed`), is
  snapped to an optional `palette`, and is laid out in `frameWidth` x `frameHeight` cells with a `padding` gutter and a
  `pivot` recorded in the sheet entry. `clips` makes several named clips from one module, one after another, each with its
  own `fps`, `loop` and `pivot`. The result returns the sheet as an image, its layout and warnings (frames that draw
  nothing, shapes on the edge of the cell, a loop whose last frame jumps from the first).
- The provenance of the sheet is `generated` (`ai` true unless you pass `ai: false`, `author` and `license`) with a
  `recipe`: the command, its arguments, and the module (and what it imported) with its SHA-256, so the sheet can be made
  again byte for byte.
- `assets.bake_sheet` bakes an entity the engine draws into a sprite sheet: a prefab, or an entity of a scene with its
  children, plays alone in a private world at the fixed step (Shape2D with gradients and strokes, sprites,
  SpriteAnimator, Tint, tweens, particles and scripts all run) and a frame is captured every 1/`fps` seconds. The cell is
  the box of everything drawn in any frame, so a growing burst is never cut, and the entity's origin is the same pixel
  in every frame (the sheet's `pivot`, which you can choose). `clips` bakes named clips, each started by a behaviour
  method (`call`) or a game event (`event`); `warmup`, `seed`, `scale`, `frameWidth` / `frameHeight` (fit the animation to a
  fixed cell), `background` and `padding` are options. The pixels are straight alpha with no dark fringes. It records the
  `sheet` entry, a `generated` provenance (`ai` taken from the prefab or scene) and the recipe, so `assets.regenerate` can
  make it again. It needs a GPU; when the process already uses its graphics device (the editor, MCP) it bakes in a child
  `factoria call`. Bake effects to save draw calls on mobile (docs/ASSETS.md, docs/AI_GUIDE.md).

Sprite sheets played by name, and checked

- `SpriteAnimator.clip` plays a named clip of the sheet of the sprite's texture (grid, `padding`, `fps`, `loop` and range come
  from the `sheet` entry; a numeric field you set still overrides). `mode` is `forward`, `reverse` or `pingpong`. A clip that
  does not loop sends the game event `clipEnded` `{id, clip}`. Scripts: `entity.spriteAnimator.play(name)`, `.clips`,
  `.clipInfo(name)` and `.on("clipEnded", fn)`. A wrong clip name is an error that lists the clips with "did you mean", also
  in `project.validate`.
- `padding` of a sheet is skipped by the animator, and the sheet's (or clip's) `pivot` is used when the Sprite has no pivot of
  its own (counted from the top-left in the sheet, flipped to the Sprite's bottom-left; `sheetPivot: false` opts out). The
  sheet entry reaches the game at run time and in exports.
- `assets.preview_sheet` (MCP `assets_preview_sheet`) draws a sheet as a labelled grid (frame numbers, cell edges, pivot,
  optional onion skin) and checks it: empty frames, ink on the edge of a cell, a jumping drawing, a loop that pops.
- Editor: the Project panel plays the clips of a selected sheet and the Inspector of a `SpriteAnimator` lists them (one click
  sets `clip`). Neon Swarm's kill effect is a sheet made with `assets.animate_svg` from `art/shockwave.anim.js`.

Assets

- The offline makers (`assets.rasterize_svg`, `assets.draw_icon`, `assets.draw_capsules`, `assets.generate_texture`,
  `assets.synth_sound`, `assets.generate_loop`, `assets.pack_atlas`, `assets.slice_sheet`) record a recipe in the asset's
  provenance: the command, the arguments that make the same bytes again (explicit seeds, project-relative paths) and the
  files it read with their hashes.
- New `assets.regenerate {path | all | stale, dryRun}` runs the recipe again and says what changed (pixels or bytes, size,
  sheet layout). `stale` makes again only the assets whose sources were edited. Provider-made assets have no recipe.
- `factoria validate` warns about a stale asset and about a recipe whose input no longer exists, with the exact
  `assets.regenerate` command in the hint.

Editor

- The Project panel marks stale made assets with a "stale" badge (red "no src" when a source is gone), has a Regenerate
  button (the selected asset, else every stale one) and a Regenerate item in the right-click menu. When a source of a made
  asset is saved a banner offers Regenerate or Not now.

## 0.5.0

FactorIA 0.5.0 makes the editor a proper Mac app: its menus are in the Mac's own menu bar.

Editor

- On macOS the editor's menus are in the Mac's own menu bar, like any Mac app: the FactorIA menu (About with the version,
  Settings... Cmd+, , Hide, Quit Cmd+Q), File, Edit, View, AI, Export (Export Game... Cmd+E), Window and Help. Shortcuts are
  Cmd+S, Cmd+Z and Cmd+Shift+Z, and go to a focused text box instead of the scene. Windows and Linux keep the bar inside the
  window. `FA_EDITOR_NATIVE_MENU=0` brings the in-window bar back on a Mac.

## 0.4.0

FactorIA 0.4.0 is about making a game with the AI inside the editor: several chats at once, roles you can turn on and
off with their own provider and model, reviews that run only when you ask, an agent that always says what it is doing,
art without an image provider and settings for it all in one AI menu. Agents see the game better (screenshots of a
region with zoom, filmstrips of an animation, a luminance profile to find seams) without filling the disk, and the 2D
renderer gains gradient stops, inherited tints and skewed or deformed sprites. The editor keeps your layout and old
engine feedback no longer piles up.

Editor version

- The right end of the menu bar shows the engine version (`FactorIA 0.4.0`); hover it for the build fingerprint.

Generated art (assets.rasterize_svg, assets.generate_texture)

- `assets.rasterize_svg` draws `clip-path` (a `<clipPath>` on a group or a shape, user-space units, transforms honoured),
  `mask` (luminance) and `<pattern>` fills (`patternUnits`, `patternContentUnits`, `patternTransform`: line hatching).
  Unsupported pieces (clipPath in bounding-box units, a pattern viewBox or stroke, a reference to a missing id) are named
  in `warnings`; filters, text, images and `<use>` are still not drawn.
- `assets.generate_texture`: the `fabric` weave is averaged per pixel when its threads are narrower than about 5 px, and
  its slubs and tones vary per crossing, so fine scales (0.2 to 0.3) no longer show a plaid of large light and dark
  blocks. Because of that, `fabric` textures regenerate slightly different at every scale (same seed, new pixels). New
  preset `linen` (also for bookcloth): a finer, even, low-contrast weave.
- **Changed default:** the darkened edge (`vignette`, 0.5 on `parchment`) is now a narrow, irregular worn border about
  3.5 percent of the short side wide instead of a wide uniform frame. New option `vignetteWidth` (a fraction of the
  short side) sets it; `0.17` gives the old width. Projects that regenerate their textures get a different edge;
  pictures already written do not change.

Screenshots for agents

- `game.screenshot` without `path` is now temporary: the result is marked `$image.temporary: true`, the MCP server and the
  AI assistant (editor, `factoria ai run`) attach the image and delete the file, and the engine removes old engine-named
  shots (`frame_*.png` in `.factoria/screenshots/`, older than 3 days or beyond the newest 200) when a project opens. A
  `path` keeps the file. Editor toolbar shots, F9 marks, `factoria run --screenshot*` and `factoria shot` are unchanged.
- `game.screenshot {region:[x,y,w,h], zoom}` shows part of the view magnified: a native re-render (sharp) up to 4x,
  nearest-neighbour above, to inspect seams, joins and gradient ends.
- `game.screenshot {frames, everyFrames, columns, region, zoom}` steps the game and returns one labelled contact sheet
  (a filmstrip) to judge an animation in one picture.
- New read-only commands `render.inspect` (brightness profile along a line with the hard steps in it) and `render.pick`
  (which entities and layers draw a pixel, topmost first; the same box geometry as the editor's click selection).
- The AI guide and the generated AGENTS.md tell agents to look closely before they trust a whole-view picture.

Assets

- `assets.generate_texture` `planks`: new options `plankCount`, `plankLength`, `gapWidth` and `gapDarkness`. Boards can run
  from side to side with no butt joint (`plankLength: 0`), and the defaults are now longer boards (one staggered joint
  per row) with a fine, softer seam, so a desk top seen from above no longer reads as a brick wall.
- `assets.rasterize_svg` has a `style` (`watercolor`, `ink`, `inkwash`, `paper`) with `styleStrength` and `seed`: a seeded,
  deterministic painterly post-process (wobbling edges, pooled pigment, granulation, a pen line, paper tooth) for
  storybook art without filters or hundreds of extra shapes in the SVG.

2D rendering

- `Shape2D.gradientStops` and `gradientEase`: a rectangle or circle gradient (linear or radial) can have up to 8 colour
  stops, `[[0, "#ff0000"], [0.5, [0, 1, 0, 0.5]], [1, "#0000ff"]]`, and an easing of its position (`linear`, `smoothstep`,
  `quadIn` ... `circInOut`, the names of the script tween easings), for sky bands, glows that fade softly and shadows without
  a visible edge. `color` / `color2` / `gradientAngle` work as before (no stops and `linear` = the old two-colour blend).
  The stops are baked into one row of a shared 256 x 256 ramp texture (up to 256 different gradients at once, the least
  recently used row is reused), so shapes with stops still batch together, the vertex stays 48 bytes and a gradient costs the
  same as the two-colour one. A malformed stop is skipped with one warning per scene.
- New `Tint` component: a colour and opacity multiplied into the entity and everything below it in the hierarchy, to fade or
  colour a group at once (a day/night wash, a hit flash, a menu fading in). It covers `Sprite`, `Shape2D` (gradient stops
  too), `Text` (rich-text colours and pictures too), `Tilemap`, `ParticleEmitter` and the screen-space UI widgets drawn by the
  renderer; not 3D meshes, lights, debug draw or the camera. Nested tints multiply. A scene with no `Tint` does no extra
  work: the parent walk happens only when at least one exists.
- `Sprite.skew` (degrees `[x, y]`, about the pivot, clamped to +-80) slants a sprite: an italic, a sign in the wind, a page in
  perspective. A sprite is deformable with `meshColumns` x `meshRows` (a grid of cells, at most 128 per side and 4096 cells)
  and `vertexOffsets` (a flat `[dx, dy, ...]` array, top row first, +y up; assign the whole array from a script each frame):
  a bent page, a flag or cloth is ONE entity and still one draw call. A deformable sprite ignores `slice`; `entity.bounds()`
  and editor picking follow the skew and the moved vertices.

AI panel

- A top-level **AI** menu (File, Edit, View, AI, Help) holds **AI Settings...** (moved out of the File menu; the panel's
  button is gone) and **Roles...**, which opens the same window on its **Roles** tab. The Roles window is now that
  tab (same table and Save, plus **Revert**); the current roles are in the tooltip of **AI > Roles...**. The panel's
  Roles... and AI settings... buttons are gone.
- What is global sits above the chat tabs of the AI Assistant: the "No AI provider is configured" box, the config
  error, the review row and the provider's plan windows (Session, Week). Context, tokens and cost stay under the tabs,
  with the chat.
- The cost reads **API cost est.** and says it is what the same tokens would cost on the pay-per-token API; with a
  Claude Code / Codex sign-in the line adds "(not billed on a subscription)": nothing is charged on top of the plan.
- **Export Game** is an item of the menu bar (the toolbar's Export button is gone; File > Export Game... stays).
- The Engine Feedback panel keeps its size with a long entry: only the entries table and the text of the selected entry
  scroll, no second scrollbar and no growing area.
- **AI Settings...** is a new window with two sections. **Asset
  generation** chooses which provider makes each kind of asset (image, sound, music, voice, 3D model), its model and voice,
  and an API key (stored in your `ai.json`, which is written readable only by you; an environment variable is still
  preferred), with a status per row. Before, the only way was to write the `assets` section of `ai.json` by hand.
  **Asset sources** lists the websites the AI should look at for images, models, audio and fonts, and **Use only these
  sites** keeps it from searching anywhere else: Claude Code is held to it (WebFetch of other sites denied, WebSearch off),
  other providers are told it. The new `assetSources` section of `ai.json` holds the lists.
- The "no provider" error of the asset commands now names the AI settings window as well as `ai.json`.
- The roles read with capitals and spaces (Orchestrator, Worker, Fast, Artist, Audio, Art critic, Reviewer) wherever the
  editor shows them, and the Roles window groups them in three sections: Orchestration and code, Art and audio, Critics
  and reviewers.
- Each role has an **Enabled** checkbox (`roles.<role>.enabled` in `ai.json`, default on). A role that is off is not used:
  the orchestrator does that work itself and its prompt says so; the Art critic and the Reviewer still run from the
  review buttons, on the orchestrator's model. The orchestrator cannot be turned off.
- The roles line is gone (hover **AI > Roles...** to see the current roles); the review buttons and the
  **Reviewers** count and focus moved up next to it, so the transcript gets two more lines.
- **Art critique** and **Game review** ask first: a dialog shows what runs, how many reviewers, the role's model and the
  focus, and **Start** runs it. Before, a click started the reviewers (and their token cost) at once.
- The live cost estimate of a Claude Code run prices its 1-hour cache writes at twice the input price, as the CLI's final
  total does; before, the estimate stayed well under the real cost while the agent worked and jumped when it finished.

Editor

- FactorIA has its own icon: a factory with an AI brain. It shows in the editor's title bar and taskbar (Windows, Linux),
  in the macOS Dock while the editor runs, on `factoria.exe` and `FactorIA-Editor.exe` in Explorer and the Start menu,
  and on the Linux AppImage.
- The program is called FactorIA wherever the system names it: the macOS Dock and Cmd+Tab (before: `factoria`, the
  executable's name), the Windows taskbar and Task Manager (the exes now carry a version resource), and Linux docks
  (the editor window's `WM_CLASS`, matched by the AppImage's `.desktop` entry).
- The toolbar's **Select / Move / Rotate / Scale** buttons show only while an entity is selected (Q W E R still switch the
  mode at any time).

Animation and scripting

- `await tween(...).finished` is safe after the entity is gone: a tween whose target entity or owning behaviour was
  destroyed, or whose scene was reloaded or unloaded, is dropped and `finished` never settles (before, it resolved
  `false` and the code after the `await` threw "entity ... was destroyed" as an unhandled rejection). `cancel()` still
  resolves `false`. New `this.tween(...)` and `this.wait(seconds)` on Behaviour (dropped with the entity).
- `tween.pauseAll()`, `tween.resumeAll()`, `tween.paused`, `tween.timeScale` and `Tween.seek(seconds)` to freeze, slow or
  scrub tweens; tweens already stand still under `game.pause` and move only with `game.step` (now documented and tested).

Tooling

- `checkpoint.read {id, path, out?}` returns one file as it was at a checkpoint (text inline, binary as base64, or any
  file written to `out`), and `checkpoint.restore` takes `paths: [...]` to restore only those files (unknown paths fail
  with a "did you mean" before anything changes).
- `storage.list` and `storage.clear {key | all}` (MCP `storage_list`, `storage_clear`) show and delete the game's save
  keys, in memory and in `.factoria/save/storage/`, so a stale save (a menu that shows "Continue") no longer needs a
  shell `rm`. SCRIPTING.md says what `project.test` does with storage: an empty in-memory one per test file, never the save folder.
- A tool file written while `factoria mcp` runs is listed and callable by the very next request (the folders were only
  looked at every 200 ms, and a request right after the write missed the new tool), and `script.eval {module, call}`
  re-imports a module edited on disk instead of running the code from before the edit.
- `project.test` resets the mouse to (0, 0) with no wheel before every test, as it already released keys, buttons and
  touches: where an earlier `game.click` or test left the pointer no longer decides what the first tests find hovered.

Fixed

- A `Shape2D` gradient whose `color` is fully transparent is drawn when `color2` is not: the ai-guide vignette recipe
  (`color: [0,0,0,0]`, `color2: [0,0,0,0.8]`) drew nothing. A shape is skipped only when every colour it uses has alpha 0.
- `world.spawn` of an entity whose Entity fields (`Interactable.knob` / `fill`) name children spawned afterwards no longer fails:
  the field is left empty with a warning and filled when the entity with that id appears (an id that never does is reported again
  after about 10 seconds of frames).
- `focusOnHover` also acts when a widget appears (or `focusOnHover` is switched on) under a resting pointer, not only when the
  pointer moves onto it, so focus and hover no longer disagree after a page turn. New `InteractableVisual.when: "highlighted"`
  (hovered OR focused).
- `scene.save` no longer writes the entities a script created at runtime (`world.spawn`, `world.spawnPrefab`, and their children)
  into the scene file: the script spawns them again on load, so they appeared twice (seen in Roguestory). The result lists what was
  left out under `skippedSpawned` with a hint, and `includeSpawned: true` bakes them in on purpose. The editor's Play/Stop snapshot
  and undo still include them. The duplicate-id warning on load now says a scene saved by an older engine may hold such entities.
- `factoria validate` no longer reports a built-in font set in a scene or prefab (`"font": "builtin:display"`, or one face
  such as `builtin:serif#bold`) as a missing project file; a misspelt one is named with a "did you mean" (seen in Roguestory).

Several AI chats at the same time

- The editor's AI panel can run up to 3 chats at once (`limits.maxConcurrentRuns` in `ai.json`, 1 to 8; before, one chat ran
  and Run was disabled in the others). Each chat has its own progress line, stuck warning, usage and **Stop**; stopping one
  leaves the others going. Play waits while any of them works, and says which chats.
- A review (**Art critique**, **Game review**) is one more run: it counts toward that limit and does not stop the other chats.
- When two chats that run at the same time change the same file (or the open scene), both transcripts get a warning that names the
  other chat and the file.
- Each run keeps its own Revert point. Reverting a run that other chats' runs overlapped puts back only the files that run
  changed and lists the files both changed: **Revert, keep their changes** leaves them, **Revert including those files** takes
  them back. The commands of several runs share the editor's main thread safely: Stop of one run no longer drops the others'
  queued commands, and two long commands (`game.step`, `project.test`) no longer overwrite each other's reply.

The AI panel's usage is live

- Tokens and cost in the editor's AI panel grow while the agent works, instead of jumping when it finishes: every model call of
  Claude Code (and each Codex turn) adds its usage, the cost is estimated with the engine's price table until the CLI's own
  total arrives. A delegated worker's spending shows live too and is no longer lost from the chat's totals or overwritten by the
  orchestrator's. The plan windows still update once per message (Claude Code reports them once); the tooltip says "As of HH:MM".
- `limits.maxCostUsd` and `limits.maxTotalTokens` apply to a Claude Code / Codex run as it goes: it is stopped when it crosses them.

Old engine feedback no longer piles up

- Closed entries of `ENGINE_FEEDBACK.json` (fixed-in-engine, wont-fix, duplicate) move to `ENGINE_FEEDBACK.archive.json` next to
  it when the editor opens the project and with the new command `feedback.archive` (CLI `factoria feedback archive`, MCP
  `feedback_archive`). Ids stay unique across both files, and a report that matches an archived fixed-in-engine entry reopens it
  with the note "reported again with engine X: regression?". `feedback list --archive` (`includeArchive`) shows the archive,
  `feedback collect` still counts it, the Engine Feedback panel has "Show archive" and "Archive closed", and exports leave the
  archive out.

The editor keeps your layout

- Which panels are open is saved with the layout (`~/.factoria/editor_layout2.ini`): a panel closed with its X, or one opened from
  the View menu, is the same the next time the editor opens or another project opens; before, only where the panels sit was kept
  and every closed panel came back. View > Reset layout also reopens the default panels. The editor autotest has a section (U)
  that floats, moves, widens and closes panels and checks they survive a reopen and a visit to the welcome screen.

More roles, and reviews that only run when you ask

- Four new AI roles in `ai.json`: `artist` (makes all the art), `audio` (sound, music, buses, mixing), and two read-only ones,
  `artCritic` and `reviewer`, which look at and play the game and give an opinion with a score from 0 to 10 and sub-scores. A
  role you do not list follows the provider you already use (a file with only `claude-code` roles keeps all seven on Claude
  Code, never an API key), and old files keep working. The Roles window, `factoria ai run --role`, `ai.run` and
  `agent_delegate` know the new names; the orchestrator delegates art to the artist and sound to the audio role.
- Reviews run only when you ask: the **Art critique** and **Game review** buttons of the AI Assistant (with a count of 1 to 5
  reviewers, each with a different point of view, and a focus), `factoria ai review art|game` and `ai.review`. The
  orchestrator cannot start them. Every review is saved in `.factoria/ai/reviews/` with its score, sub-scores and the game and
  engine version (`factoria ai reviews`, `ai.reviews`), the **AI reviews** window lists them, and **Send to orchestrator**
  posts a report into an orchestrator chat as your message so it can plan the fixes. Nothing is sent unless you press it.
- Read-only is enforced: the built-in loop offers a reviewer only tools that look and play, Claude Code runs with
  `--disallowedTools` for the editing tools and every FactorIA tool that changes something, and Codex with its read-only sandbox
  and `factoria mcp --read-only` (new: serves only the commands that look and play).
- A game is easier to review with a `REVIEW.md` (controls, goal, finished versus placeholder, how to reach every scene fast).
  The reviewers read it first, the AGENTS.md template and the AI guide ask for it, and `factoria export` leaves it out of the
  build.
- A Claude Code orchestrator no longer uses Claude Code's own `Agent` and `Task` sub-agents (they ran an unconfigured model
  outside FactorIA's roles, costs and live view, as seen in Roguestory): FactorIA starts it with them switched off and the
  prompt says to delegate with `ai_run`.

The AI agent is never silent

- When the editor's AI (Claude Code) hands a task to the worker, the worker's steps now stream into the chat as it works, and the
  panel shows how long the run has lasted and when the agent last did something. Before, a long delegation was a silent wait
  and Claude Code gave up on it after 5 minutes, so the worker's report never reached the chat.
- The MCP server reports progress (`notifications/progress`, with a heartbeat) on long calls over stdio and over the editor's
  HTTP endpoint, and the `.mcp.json` that `factoria new` writes carries a four-hour `timeout` for one tool call (add
  `"timeout": 14400000` to the server in an older project; `tool_timeout_sec = 14400` for Codex).
- After `limits.stuckAfterSeconds` (default 180, `ai.json`) without a sign of life, the panel warns that the agent may be stuck
  and offers **Stop** and **Check activity**, which looks at the agent's process, CPU, tool in flight, child processes and the
  project's recent file changes and says whether it is still working. A CLI process that disappears stops the run with a message.
- If the orchestrator's turn ends while the worker still runs, the panel says so, keeps showing its progress and, when the worker
  finishes, puts its report in the chat and continues the orchestrator's conversation by itself, once.
- `factoria ai run` prints the sub-agent's steps in the terminal (`  | worker > ...`), and `{"event":"progress"}` lines with `--json`.
- A FactorIA copied over the old one, without the in-app updater, is noticed. The editor shows "FactorIA was updated on disk
  (old -> new). Restart the editor to use it." with **Restart** (reopens on the same project, chats included) and **Not now**;
  Restart is off, with the reason, while an AI run, a play session or an export runs. `factoria mcp` restarts itself in place on
  Linux and macOS (same stdin and stdout, no disconnect, no lost request), sends `tools/list_changed` and says so in the next tool
  result; on Windows it says in the next tool result and a log message that the client must reconnect (`/mcp`). A client that
  started before `.mcp.json` changed is told once to restart or reconnect, and a missing `"timeout"` is added to the file. The
  new read-only command `engine.update_status` (MCP `engine_update_status`) reports it.

Art without an image provider

- `assets.generate_texture` (MCP `assets_generate_texture`) paints a material offline, seeded, with no provider and no key:
  `paper`, `parchment`, `wood`, `planks`, `leather`, `fabric`, `stone`, the noises `value`, `fbm` and `cellular`, and
  `gradient`, `radial` and `vignette`. `color`, `accent`, `scale`, `roughness`, `tileable` (no seam at the edges) and
  `normalMap` (also writes `<name>_n.png`) tune it; the provenance is `original`, CC0 (Roguestory/FB-0001).
- `assets.rasterize_svg` (MCP `assets_rasterize_svg`) turns an SVG, as text or a project file, into a PNG at the size you
  ask for, with the vendored nanosvg (zlib license): paths, basic shapes, gradients, strokes and transforms; no text,
  filters, masks, clip paths, `<use>` or CSS classes (named in `warnings`).
- The `no_provider` error of `assets.generate_image`, the sprite sheet and the other generators lists which configured
  providers can make that kind and which cannot (and why), the environment variables that would enable one, and the
  offline commands to use meanwhile. `assets.import` of an `.svg` points to `assets.rasterize_svg`.

Drawing and menus

- `Shape2D` gets rounded corners, soft edges and gradients, one entity each instead of stacks of translucent rectangles: `cornerRadius` (rectangle), `softness` (a blurred edge of that width on a rectangle or circle: drop shadows, vignettes, light pools) and `gradient` (`linear` with `gradientAngle`, or `radial`) from `color` to `color2`, dithered so it does not band. Everything defaults to off and plain shapes draw and batch as before (Roguestory FB-0003).
- Four more built-in fonts, all SIL OFL: `builtin:serif` (Crimson Text, with real bold, italic and bold italic), `builtin:hand`
  (Kalam, with bold), `builtin:blackletter` (UnifrakturMaguntia) and `builtin:display` (IM Fell English, with italic), for
  storybook and handwritten looks (Roguestory/FB-0002). They are files of `factoria` and the editor, not of the player: an
  export copies the ones a game names to `builtin-fonts/` and adds their licenses to `FACTORIA_NOTICES.txt`, so other games do
  not grow. `[i]...[/i]` joins `[b]` in rich text (italic face from `text.fonts` `"italic"` or the built-in family), and
  `[b]` / `Text.bold` use the built-in families' real bold faces. An unknown `builtin:` name now fails with the list of all of
  them (`docs/TEXT.md`, "Built-in fonts").
- New `Interactable` component: any entity made of sprites, shapes, text and children is a widget of the same focus, navigation and events
  as Button, Toggle and Slider, in world space (hit through the camera, following moving, scaled and turning parents) or on the
  screen. Hover, press, click, focus, arrows and d-pad, `Tab` / `Shift+Tab` (new default actions `ui_next` and `ui_previous`), confirm and cancel,
  `Panel.modal` scopes, `kind` toggle and slider (with a `knob` and a `fill` entity), and `InteractableVisual` children that show, hide or tint per state with no
  script. `ui.on` gets `hover`, `blur`, `press` and `release`; `game.click`, `ui.widgetAt`, `ui.rectOf`, `ui.focus`, `ui.state` and
  `ui.set_slider` find it by id. The recipe is in docs/MENUS.md, "Widgets from your own entities" (Roguestory FB-0006).

Watching the game and reading the docs over MCP

- Every log line carries the computer's time. The editor Console starts each line with `HH:MM:SS.mmm` (hover it for the date, the frame and the seconds since start); `game.logs` and `game.step`'s `newWarnings` give `wallTime` (ISO 8601 with offset), and the text and JSON stderr formats show it too.
- `game.click` (MCP `game_click`) clicks like a player: by UI widget `id`, screen `position` or `world` point it moves the mouse,
  presses, steps a frame, releases and steps another, so scripts see `input.mouse.pressed` then `released` and Buttons get their
  `click`. The AI guide and the generated AGENTS.md give the recipe (Roguestory/FB-0004).
- `docs.read` fits an MCP tool result by default (`maxBytes`, 40000): a cut page carries `contents` (headings with line numbers)
  and `next`, and `heading` reads one section. `docs.components` and `docs.commands` list names with a one-line summary by
  default; `name` returns one in full, `filter` narrows the list, `full` returns everything (Roguestory/FB-0005).

## 0.3.0

FactorIA 0.3.0 is about the games themselves: four more reference games (a 3D phone game, a couch co-op game, a management
game for the browser and a 3D story adventure) were made with the engine, and everything they asked for is in.
Split screen and actions per player, gamepads that come and go and the Steam Deck; tile paths, flow fields and behaviour
trees; lights with shadows from tiles; audio buses with effects, ducking and snapshots; a video player; drag and drop,
tooltips, rich text, buttons with icons, right-to-left languages and isometric tilemaps; tests that drive the UI like a
player; ads with consent, analytics and remote config; and players for the web, Android and iOS that are checked against
the engine they were built with.

Audio without a provider

- `assets.generate_voice` names the keys it needs (`ELEVENLABS_API_KEY`, `OPENAI_API_KEY`) when no provider is configured, and
  `silent: true` writes a silent clip of the line's length (or `seconds`) to test voice-dependent code (LL/FB-0601).
- `assets.generate_loop`: a seeded, seamless noise bed (wind, fire, clock) or chord drone, as WAV or Ogg. `assets.convert_audio`:
  WAV to Ogg Vorbis with an encoder built into the engine (long blocks, mono or stereo). Larkspur Lodge's beds and scores are made
  by calls kept in `assets/src/sound/*.json`; its `make_sound.py` is gone (LL/FB-0701).

Docs for what is already there

- A Button's `key` is a localization key, not a hotkey: the field's doc string (and COMPONENTS.md) says so and where a key press
  goes instead (an input action read with `input.pressed`) (LL/FB-0006).
- docs/MENUS.md, "Anchors and pivots": anchors count Y down, widget pivots count Y up, with a picture. `factoria validate` warns
  about a widget of a scene that lies completely outside the design size, naming it, the rectangle it covers and the fix
  (LL/FB-0007).
- `platform.*` in tests: the fake serves a request inside the call (also from an event handler), and the Promise settles in the
  next microtask; docs/PLATFORM.md and SCRIPTING.md say so, and a test pins it. `fake.achievements` lists only the ids that were
  touched (LL/FB-0504).
- docs/MOBILE.md, "Tablets and the iPad": `display.scaleMode: "expand"` shows more world on a 4:3 screen instead of black bars
  (LL/FB-0803, first half).

Hangul on the on-screen keyboard

- The menu kit's on-screen keyboard has an input-method hook, `IME` in `scripts/ui/keyboard.js`: per language, `{ compose(text, ch),
  decompose(text) }` say what the field's text becomes when a key is typed and when Delete is pressed. Korean's is built in: the keys
  are Hangul jamo (Shift gives the doubled ones), jamo make syllables (ㄱ + ㅏ = 가, 가 + ㄴ = 간, 간 + ㅏ = 가나) and Delete takes the
  last jamo away. `tests/slots.test.js` types a Korean slot name with the pad through the slot dialog (LL/FB-0905).

The menu kit: text speed and save slots

- `project.add_menu_kit` has a `textSpeed` part: a "Text speed" row (slow, normal, fast, instant) in the Options Audio tab, saved as
  `settings.textSpeed` in characters per second, with `settings.revealedCharacters(seconds)` for the dialogue box. `addOptionsRow()`
  of `scripts/ui/options.js` adds a row of the game to any Options section without editing the panel (LL/FB-0011).
- A `slots` part: five named slots and an autosave in `storage`, each a record with a counter, name, chapter, play time, picture and
  the game's data; a cloud copy with a higher counter replaces the local slot; damaged slots say why and can be deleted; and a
  save / load screen whose dialog names a save, with the on-screen keyboard for a gamepad player. It brings `core` and `keyboard`
  and its own `tests/slots.test.js` (LL/FB-0501).

Shipping checks: a sandboxed save, long recordings and the iPad

- The exported player takes `--persist-storage` with `--frames`, `--input`, `--dump-state` and `--screenshot`: `storage.*` and the
  save files go to the game's real user folder (the container of a sandboxed Mac App Store build) instead of memory, so a
  replay that presses Play and saves leaves a real file with no click (LL/FB-0801). `cli_larkspur_ship` does it for Larkspur Lodge.
- `--record-video` no longer grows with the length of the recording: on macOS every frame read back from the GPU was kept until
  the end of the run (4.4 GB for 25 s at 1080p); the memory is now flat (LL/FB-0802).
- The iOS player plays an input replay in its window when started with `FA_INPUT_REPLAY=<file>` and turns the screen with
  `FA_ORIENTATION=portrait|landscape` (iOS 16 or newer). `player.run_ios_sim` installs a Simulator build on an iPhone or an
  iPad simulator, starts it with both, waits for the replay to end, takes a screenshot and stops it (LL/FB-0803). Not run on a
  real iPad.

Listing data files

- Glob import of JSON data: `import tables from "../data/dialogue/*.json"` is an object of the parsed files directly in that
  folder, keyed by file name (`"ch1.json"`) in sorted order. `*` is allowed in the file name only. Editing a matched file reloads
  the importers; a file added while the game runs is seen on the next start. The export already packs every data file, so the
  glob finds the same files in `game.pak` and on the web. The generated typings declare `*.json` modules (LL/FB-0005).
- Larkspur Lodge reads its chapter tables with a glob import: a new chapter file needs no edit to a list.

Entity and scene lifetime

- `scene.generation`: a counter that changes on every scene load (`scene.load`, `scene.reload`, `game.load` in a test), a reload
  of the same scene included. A script that awaits a timeline, a preload or an answer keeps it and drops the result when it
  changed, which `scene.current` cannot tell on a reload (LL/FB-0602).
- `world.entities()` skips entities destroyed this frame, as `find`, `findAll` and `findByTag` already did, and the doc of
  `Entity.destroy` says when an entity is gone: lookups and ids at once, the handle (`alive`) at the end of the frame
  (LL/FB-0015). Larkspur Lodge's screens no longer prefix their ids with a build serial.

Tests that drive the UI like a player

- `game.tap(action)` taps the first key (or else the first gamepad button) bound to the action, so the UI and every action on
  that key see it: `game.tap("ui_submit")` presses the focused Button or Toggle (LL/FB-0009). An action with only a stick, the
  mouse or no binding is still held as the action.
- `game.checkLayout(options?)`, and `ui.check_layout {current: true}` for the command: measures the scene that runs now, with the
  panels a test has opened, without loading anything, and keeps the game state (LL/FB-0702, TM/FB-0063).
- `game.resetState()` also stops the music (`persist: true` included) and the voices; `{ audio: false }` leaves them (LL/FB-0704).
- The fake store applies `platform.stats.add` on the value it holds when it serves the request, so two adds in one frame both
  count; the call log shows one `stats.add` instead of a `stats.get` and a `stats.set`. A real store still gets a get and a set
  (LL/FB-0502).
- Larkspur Lodge drops its `tapKey("Space")` calls, its manual layout walk, its music reset and the pause between two saves.

A camera inside the UI, and studio lighting

- New widget `CameraView`: it draws a named Camera inside its rectangle, clipped by a ScrollList, layered like any widget and
  under a modal Panel's own widgets, so a 3D item, a portrait or a minimap needs no hole cut in the page. The pointer over it
  is the game event `ui.viewPointer` (`ui.on("viewPointer", fn)`: down, drag, up and the wheel, with `u`, `v`, `dx`, `dy`) so a
  script can turn what it shows; `pointerEvents`, `captureWheel`, `tint` and `resolution` tune it. docs/MENUS.md, "A camera inside
  the UI". Not yet: a render texture as the source (only cameras), and in a view no bloom, colour filter or debug draw.
- `Camera.lighting: "studio"` ignores the scene's lights, ambient, sky and fog and lights with a key, fill and rim of its own
  (`studioIntensity` scales them): an item looks the same on a stage far from the level and in a bright scene.
- `Camera.viewport` says which rectangle its fractions count (the game target, the design resolution grown by Expand), and
  `Camera.viewportSpace: "design"` counts them on the design area instead (LL/FB-0014). `RenderStats` has `views`.
- Larkspur Lodge's item view is a `CameraView`: no four bands around a hole, no darkened colours; the wheel zooms it.

Input routing: a consumed action, text input mode and the wheel under a modal

- `input.consume(action)`: later readers in the frame see the press as gone, for the action and for every action on the
  same key (Escape is `ui_cancel` and `pause`). The UI consumes `ui_submit` when it clicks a focused Button or Toggle and
  `ui_cancel` when a drag takes it or a `ui.on("cancel")` handler returns `true`, so Escape closes a dialog without also
  opening the pause menu (LL/FB-0008).
- `input.textInputMode`: true while a TextField has the focus (or a script set it); actions bound to printable keys read
  as up meanwhile, so typing P in a TextField does not pause. The menu kit's on-screen keyboard sets it, its
  `ui.on("cancel")` returns `true`, and `MenuStack.busy` resets when a scene builds a `MenuStack` (LL/FB-0503).
- `Panel.wheelPassThrough`: a modal Panel leaves the mouse wheel to scripts (LL/FB-0012).
- Larkspur Lodge drops its `MenuStack.busy` routing around the dialogue log, the screens and the save dialog.

Right to left: the UI mirrors itself and a Text has a direction

- `ui.mirrorRtl` (on by default; `"ui": { "mirrorRtl": false }` in factoria.json, `ui.mirrorRtl = false` in a script, the
  `ui.set_mirror_rtl` command): in a right-to-left language (`i18n.direction` rtl) the screen-space UI is mirrored by the
  engine. The `anchor.x`, `pivot.x` and `position.x` of every widget flip, a Toggle's box sits at the right of its label, a
  Slider runs from right to left (drawing, click and arrow keys), a Button's icon changes side, and the Text, Sprite and
  Shape2D below a widget go with it. `ui.rectOf`, `ui.state`, clicks and the editor's picking follow. A project that placed
  its widgets by hand for Arabic or Hebrew turns it off, or deletes that code (LL/FB-0903).
- A `CameraView` changes side with its layout but never shows a mirrored picture, and its `ui.viewPointer` `u`, `v`, `dx` and `dy` are not
  flipped.
- `UiBox.mirror` (`mirror: false` on any widget): the widget and everything below it keep the place they were authored in,
  for a map, a 3D view or a joystick.
- `Text.direction`: `auto` (default), `ltr` or `rtl`, the base direction of the paragraphs. `auto` with a localization
  key (`key` on a Text or a widget) takes the language's direction, so a Hebrew line that starts with a key name or a
  placeholder is right to left without a U+200F mark; `rtl` also makes `align: "start"` the right edge. The `visibleCharacters`
  reveal still follows the order of the text (LL/FB-0904). docs/LOCALIZATION.md, section 6.
- Larkspur Lodge lost `kit.mx` and the U+200F marks of `locales/he.json`.

A typewriter reveal and Korean that keeps its words

- `Text.visibleCharacters` (-1 = all, the default) draws only the first n characters of a Text, counted in grapheme clusters
  (a letter with its accents, an emoji sequence or a Hangul syllable is one). The text is laid out as a whole and then
  clipped, so the box keeps the size of the full line while it reveals; a right-to-left line appears from its right end
  (LL/FB-0004). docs/TEXT.md, "Typewriter reveal".
- `Text.wordBreak`: `auto` (default), `normal` or `keepAll`. A wrapped Korean line now ends at spaces and keeps its words
  whole by default; `normal` also breaks between Hangul syllables (the old behaviour), `keepAll` makes Chinese and Japanese
  break at spaces only too (LL/FB-0902). Chinese and Japanese without spaces still wrap between characters under `auto`.
- Larkspur Lodge's dialogue box lays its line out with `maxWidth` and reveals it with `visibleCharacters`: no hand-written
  wrapping, no blank lines padding the box.

Every hit of a ray, and colliders you can switch off

- `physics.raycast3dAll(origin, dir, maxDistance, opts)` and `raycast2dAll(from, to, opts)` return every collider the ray
  crosses, nearest first, up to `opts.maxHits` (default 32); the command is `physics.raycast_all`. No more casting again
  from just past each hit.
- `Collider3D.enabled` and `Collider2D.enabled` (default true), writable at run time: a disabled collider is skipped by
  raycasts, shape casts, overlaps, contacts and trigger events and left out of the NavMesh3D bake, and the component stays,
  so a door that opened can close again. The change takes effect at the next physics sync (once a frame, before scripts).

Glyph atlas that refills its texts

- The glyph atlas grows 1024 -> 2048 -> 4096 before it clears, and says so in the log. When it grows or clears halfway
  through a frame, the frame is gathered again, so no `Text` or UI label stays blank (LL/FB-0901). `RenderStats` has
  `glyphAtlasSize` and `glyphAtlasResets`. docs/TEXT.md, Limits.

Isometric tilemaps and cell picking

- `Tilemap.projection: "isometric"` draws diamond tiles (a 2:1 city or strategy map) as one batched mesh, row by row so the
  tiles nearer the viewer cover the ones behind them. `groundHeight` is the diamond's height (0 = `tileSize.y`) and
  `groundOffset` the pixels between the top of the tile image and the diamond's top corner, so a tile can be a block, a tree or
  a house taller than its ground. The entity's position is the top corner of cell (0, 0).
- Everything that reads a Tilemap follows the projection: `solidTiles` colliders are diamonds, `occludesLight` shadows follow
  the diamonds, `nav.findTilePath` returns the diamond centres and distances, `entity.bounds()` and the editor's outline and
  click area cover the diamonds, `scene.import_ascii` and `tilemap.set_tile` work as before, and the `anchor` of
  `scene.import_ascii` places an isometric map by its bounds.
- `entity.tilemap.cellAt(point)` (a `{col, row}`, or `null` outside the map) and `entity.tilemap.cellToWorld(col, row)` for both
  projections, and the commands `tilemap.cell_at` and `tilemap.cell_to_world`.
- The sprites section of the AI guide says how items of one layer are ordered (lower y on top, then creation order).
- Tidewater Market's ground (terrain, trees and roads, about 2600 sprites) is one Tilemap with a tileset per season: its game
  scene has 246 entities instead of 2826, the title 112 instead of 2712 and the stress scene 1029 instead of 4840. The title and
  stress scenes draw one call more, because the tileset is a second texture. The trees are part of the ground now, so a
  building covers the trees in front of it.

A CJK font subset from the locales

- `assets.subset_font {source, locales, keep, out, axes}` cuts a font down to the characters of `locales/<language>.json` (the
  languages of `localization.languages` by default; the same characters `factoria validate`'s glyph check asks a font for) plus
  ASCII, Latin-1, the full-width forms, CJK punctuation and `keep`. A variable font is pinned to one instance (`wght` 400 by
  default), the shaping tables stay, and the result lists the characters the source lacks. It uses HarfBuzz's subsetter (vendored in
  `external/harfbuzz`, linked by the tools only): no Python or fontTools. Tidewater Market's 17 MB Noto Sans SC becomes a 340 KB
  subset with the command, and its `make_subset.py` is gone. TEXT.md and LOCALIZATION.md no longer send you to `pyftsubset`.

A picture of the running game as a texture

- `render.captureTexture({ width, height, fit })` makes a `Texture` of the frame the player sees (HUD included) at the size
  asked, up to 2048 px a side: `fit: "cover"` (default) cuts the middle part with that aspect ratio out, `"stretch"`
  squeezes the whole frame in. A capture at the game's size has exactly the pixels of a screenshot. `texture.id` (`"runtime:3"`)
  goes in `Sprite.texture`, `Panel.texture` or `Button.icon`. `texture.toPNG()` gives the picture as Base64 text (`storage`
  keeps JSON), `render.textureFromPNG(text)` makes a texture of it again, `texture.destroy()` frees it; 32 textures at most.
  A run with no renderer gets a flat placeholder of the right size (`texture.placeholder`), so the saving code still runs.
  The pixels come from the readback each backend already had for screenshots. See SCRIPTING.md, "Render".
- Tidewater Market's save slots (and the autosave) show a real picture of the town at the moment of the save instead of the
  run-length map; an old save with no picture keeps the map. The pictures are not part of the cloud copy.

Web audio without the deprecated node

- The web player plays through an `AudioWorkletNode` fed from the main thread by messages (no threads or `SharedArrayBuffer` needed),
  with a `ScriptProcessorNode` only where worklets are missing: no deprecation warning in the console, a smaller buffer, and no
  underruns at 60 fps. Latency is measured in EXPORTING.md (TM/FB-0054).

Gendered strings and the kit's loading line

- A string table entry can have a gender, `{"text": "Ligera", "gender": "f"}` (`f`, `m` or `n`), and a sentence picks its
  form by it: a select entry is an object with `f`, `m`, `n` and `other` forms (`"ship_the": {"f": "la {name}", "m": "el
  {name}", "other": "{name}"}`), chosen by `args.gender`. `i18n.gender(key)` gives the gender of a string; `i18n.t` falls to
  `other` (warning once) when the gender or the form is missing. `factoria validate` warns about a select entry without a form
  the language uses and about a name that lost its gender; `i18n.export` and `i18n.import` (CSV and XLIFF) carry the forms
  (`ship_the#f`) and a `key#gender` row. docs/LOCALIZATION.md, section 5c, also says how to phrase around case.
- The menu kit's loading screen writes `i18n.t("loading.progress", {percent})` (the Text has no key), so "Cargando... 40%"
  is Spanish in Spanish. Games that copied the kit keep `loading.text` until they take the new `loading.js`, scene and strings.

A chart widget

- `Chart` draws `values` (one series, or several) as bars or lines inside a widget rectangle, in one batch: the axis is
  automatic (always including the `baseline`, zero by default) unless `min` / `max` are set, a baseline rule, `marks` (vertical
  rules at sample indexes), `colors` per series, and the axis maximum and minimum written in the language's number format.
  `slots` keeps each sample's width while a rolling series fills up. The sample under the pointer is reported: `ui.on("chartHover",
  (e) => ...)` gets `index`, `series` and `value` (`index` -1 when the pointer leaves), and `Chart.hoverIndex` / `hoverSeries`
  hold it. Tidewater Market's charts panel is two Charts instead of pools of rectangles and lines.

A choice card and modal panels

- `Panel.modal`: while the panel is active the mouse, the wheel and keyboard / gamepad navigation reach only its widgets (a
  focus scope). What is under it gets no hover, press, click, focus, tooltip or drop, the focus stays inside it,
  `ui.pointerOverUi` is true everywhere and the wheel is not passed on. The topmost modal panel (highest `layer`) is the scope.
- The menu kit has a `card` part: `Card` in `scripts/ui/card.js` with `prefabs/ui/card.prefab.json` is a modal card with a
  title, a wrapped rich-text body, choice buttons that each have a detail line, a choice greyed out with its reason shown, a
  result stage with Continue and a `holdClock` option (`game.paused` while it is open); mouse, arrows and pad. See MENUS.md.
- Tidewater Market's event and story cards are the kit's card; its draw calls and entities are the same.

Atlas packing while developing

- `assets.pack_atlas {folder, out, table, maxSize, padding}` packs a folder of images into one PNG and writes the frame table
  (`rect` and `pivot` per frame) that a Sprite's `region` and `pivot` read. Packing again keeps the frames whose size did not
  change where they were, so adding a picture changes one line of the table. docs/ASSETS.md says when the export's atlas
  groups are enough and when an atlas while developing is worth it. Tidewater Market uses it instead of its Python script.

A strategy camera

- Camera helpers for a 2D camera: `camera.zoomAt(screenPoint, factor, { min, max })` zooms towards the cursor (the world point
  under it stays under it), `camera.panBy(screenDelta)` moves the world with a drag, `camera.clampTo(rect, { margin })` keeps
  the view inside a rectangle (centred when it is smaller), and `camera.zoomOf()`, `camera.setZoom(zoom)` and
  `camera.orthoSizeFor(zoom, designHeight)` convert between pixels per world unit and `Camera.orthoSize`.
- The menu kit has a `cameraRig` part: `scripts/camera_rig.js`, a behaviour for the camera entity with drag pan, keys, edge
  pan, wheel zoom to the cursor between `zoomMin` and `zoomMax`, and a limit from `entity.bounds()` (`boundsEntity`). It
  ignores the wheel and new drags over the UI and the wheel a ScrollList took. `project.add_menu_kit` adds its `camera_*`
  input actions. The recipe is AI_GUIDE.md section 9.6.1.
- Tidewater Market drops `camera_math.js` and `camera_rig.js` for the kit's rig (`scripts/game/map_camera.js` adds its gamepad
  cursor and latched drag on top); its draw calls and entities are the same.

Buttons with an icon

- `Button.icon` (a texture), `iconRegion` (a sprite-sheet frame), `iconSize` and `iconPosition` (`left`, `top` or `alone`)
  draw an icon inside the button, so a click on the icon presses it. The label sits beside or under the icon, the pair
  centred; `alone` draws the icon only. `autoSize` grows the button to hold both and `autoShrink` shrinks the label to the
  room the icon leaves. Tidewater Market's build menu items are Buttons with the building as their icon.

Drag and drop

- `draggable` on any widget or Panel (`true`, or `{ "payload", "slop" }`) lets the player drag it with the mouse, a finger or
  a gamepad cursor (`ui.setPointer`). `ui.on("dragStart" | "dragOver" | "drop" | "dragCancel", fn)` reports the source, its
  payload, the pointer and the target (a widget, or `null` over the world). `ui.setDropTarget(widget, true | false | fn)` and
  `ui.setWorldDropTarget(...)` say what accepts, `ui.setDragImage(widget)` makes a widget follow the pointer, `ui.dragging`
  tells scripts a drag is on, `ui.cancelDrag()` ends it, and `game.drag(from, to)` drives it in tests. When a drag starts the
  press is dropped: the release makes no click, and a tooltip hides. `ui_cancel` cancels a drag instead of sending `ui.cancel`.
  Tidewater Market drops its own drag code for the worker chips.

Modifier chords in input bindings

- A binding takes modifiers: `"Ctrl+Z"`, `"Shift+MouseLeft"`, `"Ctrl+Shift+S"`, in `factoria.json` `input.actions`,
  `input.rebind` and `input.player(i).rebind`. `Ctrl`, `Shift`, `Alt` and `Super` name either side's key, and so do they in
  `input.keyDown` / `keyPressed` / `keyReleased`; `"Shift"` alone is a binding too. When one action binds `Z` and another
  `Ctrl+Z`, the chord wins: `Z` does not fire while Ctrl is held. Chords print back as `Ctrl+Alt+Shift+Super+input`.
  A bad chord is an error that says which part is wrong and what to write (`"Cntrl+Z"`: did you mean `Ctrl`), in
  `factoria validate` too.
- `input.lastPressed()` (and the player's) returns the chord when modifiers are held. A modifier pressed on its own is
  now reported when it is released, not when it goes down, so a "press a key" screen can record `Ctrl+Z`. The menu kit's
  Controls tab records and shows chords (and keeps mouse chords out of per-player bindings).
- Tests: `game.keyDown("Shift")` / `keyUp("Shift")` hold a modifier (the left key), `game.tapKey("Ctrl+Z")` taps a chord. The
  `game.input` command and replay files accept `Ctrl`, `Shift`, `Alt` and `Super` as key names too.
- Tidewater Market binds Ctrl+Z, Ctrl+Y (with the plain Z and Y it had) and Shift+click (a road or a demolish takes two
  clicks, as with the hold-free option) through the engine.

Tooltips

- `tooltip` on any widget or Panel (a localization key, `{ title, lines, args }`, or a function from
  `ui.setTooltip(entity, fn)` that returns the text when it shows). It shows after `ui.tooltipDelay` seconds of rest within
  5 pixels, beside the pointer and flipped to stay on screen, is styled by the new `"ui": { "tooltipDelay", "tooltipOnTouch",
  "tooltip" }` of `factoria.json` and stays off on touch unless the project turns it on.
- `ui.showTooltip(content, { x, y })` and `ui.hideTooltip()` for what is not a widget, `ui.setWorldTooltip(fn)` for a
  pointer over no widget, and `ui.tooltip` (also `tooltip` in `ui.state`) to read what shows. `ui.check_layout` reports a
  `tooltip` issue for an invalid or screen-sized tooltip. Docs: MENUS.md, SCRIPTING.md.
- Tidewater Market drops its own Tooltips class for the engine feature (TM/FB-0007).

The web's hide and close signals, and storage that scales

- A web export raises `suspend` when its tab is hidden and `resume` when it is shown again (`visibilitychange`), and `quit`
  when the page goes away (`pagehide`; it cannot be cancelled there). The save folder is copied to IndexedDB right after
  those handlers run, so a `storage.set` inside one is kept (before, only a 500 ms timer was scheduled). SCRIPTING.md
  ("Window close") lists which of `blur`, `suspend` and `quit` each platform raises; MOBILE.md and EXPORTING.md say what the
  web does (TM/FB-0021).
- `storage` writes one file per key in `<save folder>/storage/`, so a save rewrites its own key only. An older `storage.json`
  is read at the first start, split into key files and renamed `storage.migrated.json`. `storage.size(key)` gives the bytes
  of a key's file. `storage.set(key, value, {compress: true})` stores the value zlib-compressed. `storage.setAsync(key, value,
  options?)` returns a Promise and writes off the frame (a worker thread; between frames on the web); the writes still waiting are made after the
  `suspend` and `quit` handlers. Docs: SCRIPTING.md
  (storage) (TM/FB-0022).
- Tidewater Market writes its timer and season autosaves with `storage.setAsync` (compressed) and its blur, suspend and quit
  saves at once with `storage.set`.

Tile paths on a reusable grid, and flow fields

- `nav.createGrid({ width, height, cost?, origin?, cellSize? })` keeps a cost grid in the engine. `nav.findTilePath(grid,
  from, to)` takes it instead of the `{ width, height, cost }` array, with the same options and the same paths, but a call
  no longer converts the whole array and sweeps it for its cheapest cell, so a short route stops costing the size of the
  map. `grid.setCost(col, row, cost)` changes one cell (`getCost`, `setCosts`, `version` and `findPath` are there too).
  The array form works as before.
- `nav.flowField(grid, goals, { diagonals })` searches once from one or more goal cells: `field.stepToward(col, row)` gives
  the next cell toward the nearest goal in O(1), `field.distance(col, row)` the cost and `field.pathFrom(col, row)` the
  whole way. A field made before `grid.setCost` is rebuilt the next time it is asked.
- The `nav.flow_field` command is the stateless form (distances for the whole map, plus the next step and the path from a
  cell). In a debug build, 600 walkers on a 60 x 60 map for 75 ticks cost about 228 s with the array form, 8.2 s with the
  kept grid and 0.16 s with flow fields (a benchmark test prints it). Docs: NAVIGATION.md, PERFORMANCE.md.
- Tidewater Market's own distance fields are now `nav.flowField` over a `nav.createGrid` (TM/FB-0006).

Players for a development build

- `factoria setup webplayer` (and `setup.install {component: "webplayer"}`) builds the web player from the engine checkout
  `factoria` was built from: it uses an Emscripten SDK it finds (`$EMSDK`, `emcc` on `PATH`, the checkout's `.cache/emsdk`,
  `~/emsdk`) or fetches the pinned 6.0.10 into `.cache/emsdk`, runs the `web-release` preset and leaves the player in
  `build/web-release/player`, which `factoria export --platform web` prefers. An up-to-date player is not built again.
- `factoria setup players` on a development build whose version has no release no longer stops: it takes the players of the
  newest release, installs them under this version's folder and warns that their build fingerprint will not match, so an
  export that uses them needs `allowPlayerMismatch` (`--allow-player-mismatch`).
- docs/EXPORTING.md: the Emscripten setup under Web and "A development build: players from the checkout".

The export's size report, and the web page's icon

- Every export names the five folders that weigh most in what ships (`largestFolders` in `--json`) and warns when a `store/`,
  `screenshots/` or `src/` folder, at any depth, is packed, pointing at `export.exclude`.
- A web export lists the raw and about-gzip size of each file of the zip, the total, and how long the gzip total takes to
  download at 1, 5, 20 and 100 Mbit/s (`webFiles`, `webBytes`, `webGzipBytes`, `webDownloadSeconds` in `--json`).
- A web export links a `favicon.png` (64x64) made from the game's `icon` in `index.html`, instead of an empty icon; the
  page template has a new `{{favicon}}` placeholder. A game without an icon keeps the empty icon.

Rich text: bold, colours and icons inside a text

- `Text.markup: true` reads `[b]bold[/b]`, `[c:good]coloured[/c]` and `[icon:fish]` in the text, and so does the label of a
  `Button`, `Toggle`, `Slider` or `TouchButton` with `markup: true`. Wrapping (also between CJK characters), alignment,
  `maxWidth` and `autoShrink` work on the whole line, and `ui.measureText(text, { markup: true })` and `entity.bounds()`
  measure what is drawn. An icon is a rectangle of a project texture as tall as the line. The glyphs of a Text, of any
  colour and weight, are one batch; each texture that icons come from adds one more.
- The new `text` section of `factoria.json` names the colours (`text.colors`), the icons (`text.icons`: texture and pixel
  region) and the bold file of each font (`text.fonts`). `Text.bold` (and the same field of the widgets) draws a whole text
  bold. A font without a bold file is emboldened by the engine; `factoria validate` suggests adding one, and checks the
  section, the files it names and the markup of scene texts.
- Mistakes never hide the sentence: an unknown tag, a `[` without `]` or an unknown colour shows as written, with one
  warning per text. `ui.markupProblems(text)` lists them for a test. `[[` writes a literal `[`.

An interface size, Panel minimum and maximum sizes, and events for the size options

- `ui.scale` (0.5 to 3, default 1) makes the whole screen-space interface bigger or smaller: the size, offset, padding,
  spacing, margins and font size of every widget and of screen-space `Text`, `Sprite` and `Shape2D` are multiplied by it
  (`ui.textScale` comes on top for text), and anchors do not move. `ui.rectOf`, `ui.state` and the hit test are in screen
  pixels and follow it; `Panel.size` and `ui.measureText` stay in UI units. `"ui": { "scale": 1.25 }` in `factoria.json` is
  the start value (a project reload applies it only when the file changed), `ui.set_scale` is the command and `ui.state`
  reports `uiScale`. Screen-space particle emitters are not scaled. docs/TEXT.md, "Interface size".
- `Panel.minSize` and `Panel.maxSize` (0 = no limit on an axis) bound the size of a Panel, also one with `fit: true`.
- `ui.on("scale", fn)` and `ui.on("textScale", fn)` run once per change, with `{ value, previous }`, like
  `i18n.on("change")`.
- `ui.check_layout` takes `uiScales` and crosses them with the languages and text sizes. The menu kit's Options has an
  "Interface size" button (the sizes at which its panel fits), saved as `uiScale` in `settings.js`. Games that copied the
  kit copy `scripts/settings.js`, `scripts/ui/options.js`, `prefabs/ui/options.prefab.json` and the `options.uiScale`
  string of `locales/*.json`.
- Fixed: a `Text` with `maxWidth` and a centred or right-aligned `align` is drawn in a box of `maxWidth`, but its bounds (layout,
  `ui.state`, editor) were those of its widest line, so a right-aligned note in a right-to-left Panel was drawn off its
  rectangle. Its bounds are now the box it is drawn in; left-aligned text is unchanged.

Tooling: feedback merges, perf files of several scenes, and recording progress

- `factoria feedback collect` no longer merges two gaps whose titles only share a few words: a title that contains
  another needs four shared words, the `missing` text weighs in, an entry may list `distinctFrom` ids it never merges
  with, and the report prints each merged entry's similarity to its group.
- ctest runs every `<example>.perf.json` and `<example>-*.perf.json` file of an example, so a game with a title, a game
  and a stress scene keeps a budget for each (docs/PERFORMANCE.md).
- `factoria run --record-video` prints its progress (frames written of the total) on stderr while it records.
- PLATFORM.md says that `game.platform.calls()` shows a `stats.add` as a `stats.get` and a `stats.set`.

Audio: buses of your own, the voices that play, `onEnded`, and a listener zoom

- `factoria.json` `audio.buses` declares buses with a parent (`"ambience": { "parent": "sfx" }`). A bus scales the sounds
  played on it (`audio.play(clip, { bus: "ambience" })`), its parent scales it in turn, and it takes `audio.setVolume`,
  `audio.bus(name)` effects, ducking and snapshots like the built-in ones. `factoria validate` checks the names with a
  "did you mean". The built-in buses (`master`, `sfx`, `music`, `ui`) work as before.
- `audio.activeVoices()` lists the sounds that play now, and `audio.play(path, { onEnded })` calls back once when a sound
  finishes, is stopped with `audio.stop` or is dropped by a full mixer (not on `stopAll` or a scene load).
- `game.audioLog()` has an entry for every `audio.setVoiceVolume` on a playing voice (`kind: "setVoiceVolume"`, with
  `voice` and `fade`); `toContainPlayed` skips them.
- `AudioListener.zoom` (default 1) scales how far positional sounds reach: a zoom of 2 doubles the distance.

Script helpers: the rng state, running a module, did-you-mean, a shadowed method

- A generator from `rng.create` has a `state` (a 32-bit integer) you can read and assign, documented as stable like the
  algorithm: store it in a save and assign it to resume the same stream.
- `script.eval` takes `module` (a project path), `call` (an exported function) and `args`, and returns the function's
  result: `factoria call script.eval` runs a pure module with no scene.
- `didYouMean(word, choices)` is exported from `"factoria"`; docs/EXTENDING.md has a recipe for a project tool that
  validates the cross references of `data/*.json` with file, JSON pointer, hint and did-you-mean.
- A `Behaviour` field named `on`, `after`, `every` or `world` replaced that method without a word. The first instance of
  the class now logs one warning naming the field, and `factoria validate` reports it.

`ui.rectOf` and hidden parents; docs for what was already there

- `ui.rectOf(entity)` returns `null` for a widget or screen-space Text hidden by an inactive parent, as `ui.state` already
  left it out; it used to give the rectangle it would have had. The docs now say that a child of a hidden Panel keeps
  `active` true (ask `activeInHierarchy`), that a screen-space line's `size.y` points up, how a Panel's children are
  placed, how to press the focused widget in a test, and the test section of SCRIPTING.md uses `fa.call("ui.state")`.

A wrapped text measures its widest line; a Toggle's box follows the font size

- With a renderer a wrapped text was at least as wide as its `maxWidth`, so `ui.overflowed`, `ui.check_layout` and
  `autoShrink` flagged and shrank a short label for nothing, while headless measured the widest line. Both measure the
  widest line now, so a layout test and the window agree. A wrapped Text with a pivot or centre alignment is placed by that
  width, so it can sit a little differently than before.
- A Toggle's box is one line of its label high (`fontSize` at the player's text size, times 1.2, plus 4 px), no longer the
  widget's height minus 12: a two-line label or a taller toggle keeps the same box. `Toggle.autoShrink` and `minFontSize`
  fit the label into the room right of that box.

Web, Android and iOS players are checked against the engine build

- `factoria export` compared only a desktop player with its own build. It now compares the web player
  (`factoria_player.wasm`) and the prebuilt Android and iOS libraries too: a player of another build stops the export with
  the two builds and what to do (`factoria setup players`, the checkout's `build/web-release`, or `--allow-player-mismatch`).
  A web export with no `--player` takes the player whose build matches, the checkout's `build/web-release` before the
  installed one. A script that imports an export the player lacks, or calls a method of the engine's objects it lacks,
  now gets an error naming the module and the missing export and saying the player may be older than the game's engine.

A UI hit test, a virtual pointer, the consumed wheel and an empty focus

- `ui.widgetAt(x, y)` returns the topmost visible widget or Panel at a screen point (nothing for empty space or a row a
  ScrollList clips) and `ui.pointerOverUi` says whether the pointer is over one. A game with a gamepad cursor no longer
  scans the scene itself.
- `ui.setPointer(x, y, { down })` drives hover, press and click like the mouse, from the next frame on, until
  `ui.setPointer(null)`: for a gamepad cursor and for tests.
- A ScrollList with more content than it shows keeps the mouse wheel: `input.mouse.wheel` reads 0 that frame and
  `ui.wheelConsumed` is true, so a camera that zooms with the wheel needs no check of its own.
- `ui.focus(null)` holds until the next arrow / D-pad press: an open panel's `autoFocus` no longer takes the focus back
  on the next frame.

Web exports download the game's code once

- The page of a web export handed the downloaded wasm to the player through `Module.wasmBinary`, which Emscripten 6 no
  longer reads, so the browser fetched the 8 MB file a second time on every load. It now uses `Module.instantiateWasm`:
  one download, with the progress bar, and a plain error when the browser cannot compile it. Re-export a web game to get
  the new page.

Versions for the script API

- `tools/common/api_since.json` has a `"script"` section: each function, type and member of the scripting API says which
  release added it, taken from the `api.json` of every release tag. The typings (`types/factoria.d.ts`) and the
  scripting API part of docs/COMPONENTS.md carry it as `@since` for what came after 0.1.0, so `nav.findTilePath`,
  `bt`, `http.fetch` or `game.today` tell when they appeared.

Two more behaviour tree nodes, and a tile counter that sees every change

- `bt.parallel(...children)` (or `bt.parallel({ succeed: "any" }, ...children)`) ticks all children each tick and fails at
  the first failure; `bt.repeat(child, times?)` runs the child again after each success (once per tick), forever or `times`
  times. SCRIPTING.md, "AI: behaviour trees".
- `nav.tileVersion(tilemap)` now also counts writes that replace `tiles` as a whole (`tilemap.tiles = [...]`,
  `scene.set_component`, editor edits), not only `setTile`.

A smaller player

- The linker drops the engine code no game reaches: `-dead_strip` on macOS and iOS (the macOS player goes from 10.2 to
  9.1 MB without symbols), `--gc-sections` on Linux. Android, Windows and the web already did. A game plays the same: five
  levels of the reference games give the same world state and screenshot after 1200 frames. Sizes per platform:
  docs/EXPORTING.md, "Size of the player".

Burrow Brigade drops the workarounds M29 made unnecessary

- Burrow Brigade gives every torch, crystal and magma source its own Light2D (no pool of 16), writes fog and shift tiles with
  `tilemap.setTile`, copies and pastes through the system clipboard, keys its daily dig and board by the UTC day with
  `{day}`, and detects a Steam Deck with `game.device.steamDeck`. Its feedback entries are closed with what it kept and why.
  Its perf baselines count the real lights (entities 145, lights 20, `maxLights` 24).
- Burrow Brigade's Options > Video uses the window API: windowed, borderless window and full screen with
  `window.setMode`, and a monitor button (`window.monitors()`, `window.setMonitor`) where the platform has several
  monitors; an older save's full screen flag still works. A pad player keeps its pad's `padId`, and a pad that returns
  in another slot is followed (`gamepadConnected`).

Split screen: camera viewports

- `Camera.viewport` is the part of the screen a camera draws into: `[x, y, width, height]`, each 0 to 1, origin top-left, default
  `[0, 0, 1, 1]`. Every active camera with `primary: true` draws in ascending `depth`, each with its own scissor, culling, 2D lights
  and 3D lights, and `clear` per camera. Two or more cameras make a split screen (two or four players) or an inset. The UI and every
  `space: "screen"` item is drawn once over the whole screen; bloom and `colorFilter` run once with the lowest-`depth` camera's
  settings. A scene with a bad `viewport` fails to load, naming the entity and the field; a script that sets one live is clamped
  with one warning. At most 8 cameras are drawn. A scene with one full-screen camera renders as before. Before, only the
  lowest-`depth` primary camera drew: a scene with a second active `primary: true` camera now draws it too, over the first; set
  `primary: false` on a camera that must not draw.
- Scripts: `camera.all`, `camera.at(point)`, `camera.screenRay(point, camera?)`, and `camera.worldToScreen(v, camera?)` /
  `camera.screenToWorld(v, depth?, camera?)` take an optional camera (without one, a screen point uses the camera under it, so a click
  picks what the player under the pointer sees). `input.mouse.world` and a touch's `world` use that camera. The audio listener
  without an `AudioListener` is the first camera drawn. `game.renderStats()` counts per frame, over all cameras. Recipe: AI guide
  section 9.29. Known limit: screen-space `lit` visuals get only ambient light in a frame with several cameras.
- Burrow Brigade: Options > Video > "Split screen when players part" (off by default). On, miners can part and the screen splits into
  two to four views; off keeps the shared camera and the leash.

The exported player checks a build

- `factoria_player` (the exported game) takes `--input <replay>`, `--dump-state <file>` and `--screenshot <file>` together
  with `--frames N`: the game runs headless through the same code as `factoria run --headless --frames N`, plays the replay
  `input.record` writes, writes the world state after the last frame and a PNG of the last frame. Both equal what
  `factoria run` writes for the same replay and frame count. Exit codes: 0, 1 after a script error, 2 for a missing replay,
  an unwritable output or a missing `--frames`. New test `cli_player_replay`; EXPORTING.md has "Checking an exported build".

Tile pathfinding and behaviour trees

- `nav.findTilePath(map, from, to, {costs, diagonals, maxNodes, closest, allowBlockedGoal})` and the command
  `nav.find_tile_path`: deterministic A* over the cells of a `Tilemap` (solid tiles block, `costs` per tile index) or of a
  `{width, height, cost}` grid for games that keep their own map. Diagonals never cut corners; `closest` returns the nearest
  reachable cell. The result lists `cells` and the world `points` of their centres. `nav.tileVersion(tilemap)` counts the
  `setTile` writes so a script knows a kept path is stale. NAVIGATION.md, section 7.
- `import { bt } from "factoria"`: behaviour trees in plain JS (`Tree`, `sequence`, `selector`, `condition`, `action`,
  `wait`, `cooldown`, `inverter`, `succeeder`, `SUCCESS`, `FAILURE`, `RUNNING`), ticked by the script with its own `dt`.
  SCRIPTING.md, "AI: behaviour trees", and an enemies recipe in the AI guide (section 9.27).

Steam Remote Play guests and `platform.cloud.stat`

- New platform service `remotePlay`: `platform.remotePlay.sessions()` lists the guests connected through Remote Play
  Together (`[{ id, guestName, guestId, deviceName, formFactor, resolution }]`) and `platform.on("remotePlay", ...)` gets
  `{ status: "connected" | "disconnected", session }` as each comes or goes. The Steam plugin offers it when the Steam
  library has `ISteamRemotePlay`. A guest's controls arrive as one more gamepad; the engine does not say which pad is which
  guest. The fake store has `game.platform.remotePlayConnect(info)` and `remotePlayDisconnect(id)` (commands
  `platform.remote_play_connect` and `platform.remote_play_disconnect`).
- New `platform.cloud.stat(key)`: `{ exists: false }` for a missing key, else `{ exists: true, size, modified }` without
  returning the text (`modified` in Unix seconds, `null` on Apple, which keeps no time). Steam answers the file's time,
  Google Play the snapshot's last-modified time (it opens the snapshot to count the bytes), the fake a deterministic
  counter (`game.platform.set({ cloudClock })` sets it). To tell which save is newer keep a revision counter in the saved
  value; PLATFORM.md says why.
- The Steam, Apple and Google Play code for both was checked against the mock (Steam) and by reading (Apple, Google Play)
  only: no real Remote Play session or real store was tried.

Light2D on a light buffer: shadows from solid tiles and no 16-light cap

- Point lights are now added up in a light buffer (one draw call, RGBA16F, or RGBA8 at half range on a GPU that cannot
  blend half floats) that lit sprites, tiles and shapes read, instead of every pixel looping over 16 lights. A frame keeps
  up to 256 lights (it was 16): the same choice as before (directional first, then the lights that reach the view, more of
  their radius in view first, then the brighter), the same stats (`lights2d`, `lights2dDropped`) and the same
  `perf.measure` `lights`. The look of a scene with 16 lights or fewer is unchanged (the render goldens still match).
  A lit sprite or tile WITH a normal map is still shaded per pixel by the first 16 lights, because its shading depends on
  the direction of each light; flat surfaces get all of them. A scene without Light2D, or without lit visuals, draws no
  light pass; one with them adds one draw call (the perf baselines of Burrow Brigade went from 10 to 11 draw calls).
  The light pass needs an orthographic camera; a perspective camera shades per pixel with 16 lights as before.
- New field `SceneSettings.lightScale` (0.25 to 1, default 1): the size of the light buffer as a fraction of the
  picture. 0.5 quarters the fill cost of the lights, a good setting for phones and the web.
- New `Light2D.castShadows` and `Tilemap.occludesLight` (both default false). A Tilemap with `occludesLight` makes the
  tiles of its `solidTiles` block the light of every point Light2D with `castShadows`: the far side of a wall stays
  dark, the wall's own face stays lit, and a light inside a solid tile shines out of it. Editing a tile at run time
  (`tilemap.setTile`, the command `tilemap.set_tile`) moves the shadows on the next frame. The
  shadows are traced on the CPU per light (1024 rays) and looked up on the GPU; a light that does not move reuses its rays.
  At most 32 point lights per frame cast shadows (the ones ranked first); the others shine through walls, with one
  warning per scene. The new stat `lights2dShadowed` (`renderStats()`, `game.render_stats`) counts the ones with a shadow.
- docs/PERFORMANCE.md has the cost per light and per shadow-casting light measured on a Mac, and advice for mobile and
  the web; docs/AI_GUIDE.md a recipe for lights with tile shadows. The doc strings and docs no longer say "16 lights".
- `FA_LIGHT_FORMAT=rgba16f|rgba8|none` picks the light buffer format at start-up (testing the fallbacks; `none` uses the
  per-pixel loop over 16 lights, the same as a GPU that cannot render to either format).

Analytics with consent and remote config

- New `analytics` and `remoteConfig` in `factoria`, on top of `http.fetch` (docs/ANALYTICS.md). `analytics.event(name,
  props)` queues small events and sends them in batches to the `endpoint` of the new `"analytics"` section of
  `factoria.json`, but only after `analytics.setConsent(true)`: before that nothing is kept or sent, and a refusal forgets
  the queue. A batch goes out at `batch` events, after `flushSeconds`, on suspend and on quit (the quit waits up to 3
  seconds for the request). A failed send (no connection, 408, 429, 5xx) is retried with a doubling wait, at most 3
  attempts per event; another 4xx drops the batch. `consentFromAds: true` lets the ad consent answer the question until
  the player does. `remoteConfig.get(key, fallback)` reads the JSON of the new `"remoteConfig"` section, caches the last
  good answer in `storage` for offline runs and checks each value against the type of its fallback.
- `factoria validate` checks both sections (hosts declared in `"network"`, `https://`, ranges, misspelled keys) and warns
  about an `analytics.event(` call in a game without the section. The iOS export adds a Product Interaction (Analytics, not
  linked, no tracking) entry to the privacy manifest when the section exists.
- Menu kit: new part `analyticsConsent` (the question on the first run, from the main menu) and an Options switch,
  with `analyticsConsent.*` and `options.analytics` in the locale tables. The kit's own `recipe.test.js` answers the
  question before it opens the main menu.
- Tests: `game.analytics` (`sent`, `requests`, `queued`, `restart`) and `game.remoteConfig.restart`; the answers come from
  the fake `http.fetch`. `storage.keys()` hides the engine's `factoria.*` keys and `storage.clear()` removes them.
- No new command and no `api_since` row: both services are script modules, listed in `factoria api`.
- Burrow Brigade's statistics, balance and online news now use the engine API.

Local multiplayer: actions per player

- `input.player(i)` (0..3) gives each person sharing the machine their own view of the project's actions: `down`,
  `pressed`, `released`, `value`, `axis` and `vector`, driven only by the devices assigned with `player(i).use({ pad,
  padId, keys })`. `keys` names a key scheme (`"all"`, `"left"`, `"right"` or one from the new `factoria.json`
  `input.schemes`, which can `extend` another, add `keys` and give per-action `actions`); `padId` follows a physical
  gamepad across slot changes. A player with no device reads nothing; the global `input.*` still hears every device.
  Each player has bindings of their own: `bindings`, `rebind`, `reset`, `lastPressed`, and `export` / `import` to save
  them in `storage`. A bad slot, scheme, key or action throws with "did you mean" and changes nothing. Mouse and touch
  are not read by players. `input.keySchemes()`, `input.keySchemeKeys(name)` and `input.maxPlayers` list what exists.
  Tests start with no devices; a game assigns them when its scene starts. SCRIPTING.md and the AI guide (9.28) have the
  recipe.
- The menu kit's options script has a `players` property: with more than one, the Controls tab gets a Player button and
  rebinds, resets and saves the controls of the chosen player (`settings.playerBindings`); a single-player game is
  unchanged. MENUS.md and the `en`/`es`/`ar` texts have the two new keys (`options.player`, `options.playerBinding`).
- Burrow Brigade drives its four diggers with `input.player(i)` and four key schemes in `factoria.json`; its saved
  controls move to the engine's action names the first time they are read.

Recording input and starting a scene with props

- The input recorder moved from the editor into the engine and now hears the keys, mouse, touches, Back and gamepads
  (connections, buttons, axes) itself. The new command `input.record` (`{action: "start" | "stop", path?}`) records any
  running game; `stop` returns the replay that `factoria run --input` plays (optionally written to `path`). The editor
  records its Play sessions with the same recorder. Not recorded: mouse wheel, locked-mouse movement and typed text.
- Scenes can start with props: `scene.load(path, props)`, `game.load(path, props)`, `game.loadJson(scene, props)`, the
  `scene.load` command's `props`, and `factoria run --props JSON|FILE`. `game.sceneProps()` returns them from the scene's
  first `onStart`. A reload keeps them; a load without props gives `{}`.

Monitor choice and window modes

- `window.monitors()` lists the monitors (`index`, `name`, `size`, `primary`, `current`), `window.monitor` is the one the
  window is on and `window.setMonitor(i)` moves it there (Windows, macOS, Linux; XRandR on Linux is loaded when the game
  starts, so a machine without it lists one monitor). `window.setMode("windowed" | "borderless" | "fullscreen")` and
  `window.mode` choose how the window is shown; `setFullscreen(bool)` keeps working. On Windows and Linux full screen is
  a frameless window over the monitor, so `"fullscreen"` and `"borderless"` look the same; on macOS `"fullscreen"` is the
  native Space and `"borderless"` a frameless window that hides the menu bar and the Dock. SCRIPTING.md says what each
  OS does. `window.supports("borderless")` and `window.supports("monitors")` tell what the platform can do.
- Menu kit options screen: the Full screen toggle is now a Window mode button (windowed, borderless, full screen) and a
  Monitor button (only with more than one monitor). `settings.js` saves `windowMode` and `monitor` (`{ index, name }`)
  instead of `fullscreen` (a save from the older kit is still read) and restores the monitor, then the mode, at start.
  The locale tables have `options.windowMode`, `options.mode.*` and `options.monitor` instead of `options.fullscreen`.

`http.fetch` on every platform

- `import { http } from "factoria"`: `http.fetch(url, { method, headers, body, timeout })` returns a Promise of
  `{ status, ok, headers, text, json() }`. Windows uses WinHTTP, macOS and iOS `NSURLSession`, Linux libcurl (loaded
  when first used: the player does not link it, and without it `platform.has("http")` is false), Android
  `HttpURLConnection` and the web build the browser's `fetch` (CORS applies). An HTTP error status resolves with
  `ok: false`; a request that did not complete rejects with `code` and `hint`.
- A game declares the servers it calls in `factoria.json` `"network": { "hosts": [...], "purpose": "..." }`: `https://`
  only (plain `http://` to `localhost` for a test server), the host must be listed (`"*.example.com"` covers
  subdomains), no password in the URL, redirects only to https. `factoria validate` checks the section and warns about a
  script that calls `http.fetch` with no host declared. The Android export adds the `INTERNET` permission only when
  hosts are declared.
- Tests, `factoria call`, `session`, headless runs and MCP never touch the network: the fake answers what
  `game.platform.respond("http.fetch", { status, headers, text, json, error })` scripted. An input recording
  (`input.record`, editor play sessions) keeps the answers in the `"http"` field of the replay, and
  `factoria run --headless --input` plays them back.
- `platform.state` shows `httpBackend`, `httpWhy` and `networkHosts`. A plugin cannot offer the `"http"` service.
- New [NETWORKING.md](docs/NETWORKING.md); LEGAL.md and MOBILE.md no longer say that games have no network.

Audio buses: effects, ducking and snapshots

- Every bus (`sfx`, `music`, `ui`) is mixed into its own buffer before the master, so a bus can have effects:
  `audio.bus("music").lowpass(800)` (12 dB per octave, 0 or null = off), `.reverb(0.3)` (a small room), and
  `.duck("sfx", 0.5, 0.05, 0.5)` to push the music down while a sound effect plays (`.unduck()` or `duck(null)` ends it).
  `lowpass`, `reverb` and `volume` take `{ fade }` to slide; a bus with no effect does no effect work. The master takes
  a low-pass and a reverb too, but no ducking. Effects stay across scene loads, like volumes.
- Changing a bus volume (`audio.setVolume`, `audio.bus(name).volume(v)`) now ramps over about 10 ms instead of jumping, so
  it no longer clicks; `{ fade }` makes it a longer, straight-line fade.
- Snapshots: factoria.json `audio.snapshots` names sets of bus settings (volume scale, low-pass, reverb, ducking) and
  `audio.snapshot("underwater", { fade: 1 })` moves every bus to one, a bus it does not list going back to neutral.
  `factoria validate` reports a bad catalog with the JSON pointer, a fix and a "did you mean".
- Commands `audio.bus` (set or read a bus) and `audio.snapshot` (apply one, or list them) for MCP and the CLI.
  SCRIPTING.md ("Audio buses") has the cost of each effect and a recipe.

Test runner and `ui.check_layout`

- `game.click(widget)` (and `mouseMove`, `touch`, `touchStart`, `touchMove` with a widget) lays the UI out first, so a
  panel opened in the same frame can be clicked with no `step` or `ui.layout()`. It throws, naming the widget and why,
  for a widget that is inactive, has no area or is scrolled out of its `ScrollList`, instead of clicking nowhere.
- `game.tapKey(key)` presses and releases a key over one frame; SCRIPTING.md shows `game.tapKey("Enter")` submitting a
  `TextField`, and `fa.call("fs.write", ...)` saving a file from a test.
- `ui.check_layout` judges a widget in a `ScrollList` by the part the list shows (a row half inside is no longer
  reported for its clipped half) and takes `steps` per scene (click, key, action, frames) to open a panel before the checks.

Menu kit: optional shop and age gate, a Controls tab from the actions

- `project.add_menu_kit`: the `main-menu` part no longer brings `shop` and `ageGate`. `{"parts":["main-menu"]}` writes a
  main menu without the Shop button, the shop panel and the age gate line (and without their scripts); add `shop` and
  `ageGate` to `parts` to have them (no `parts` still adds everything).
- The options screen's Controls tab lists every input action of the game except the `ui_*` ones (it was a fixed list of
  `move_left`, `move_right`, `jump`, `pause`), labelled with `options.action.<action>` or the action's name when the game
  has no such string. The `actions` property of the prefab's Script (`"props": { "actions": [...] }`) picks and orders them.

Gamepads that come and go, and the Steam Deck

- `game.on("gamepadConnected" | "gamepadDisconnected", fn)` gives `{ slot, id, name, type }`. `input.gamepad(i).id` and
  `.name` read the same. The id is stable per physical pad on Windows (XInput slot), Linux, macOS, iOS, Android and the web,
  and a pad that returns gets its old slot when it is free. Tests: `game.gamepad(i).connect({ id, name, type })`.
- `game.device.steamDeck` and `game.device.handheld`. The Steam plugin says whether this is a Deck (plugin API version 4,
  `set_device_fact`); without it the `SteamDeck=1` environment variable decides. `game.setDevice` accepts both.

Tilemap: tileset margin and spacing, `setTile` without rewriting the array

- `Tilemap.margin` and `Tilemap.spacing` (pixels, default 0) describe a tileset image with a border and gutters between
  tiles. The 2D renderer (also the normal map), the tile count, `factoria validate` and the level commands read them.
  `assets.slice_sheet` is for animation grids and does not take them.
- `entity.tilemap.setTile(col, row, id)` and `getTile(col, row)` change one tile in place, and the new command
  `tilemap.set_tile` does the same from the CLI and MCP. The renderer reads the grid in place (no copy per frame), and 2D
  physics rebuilds only the colliders of the tiles you changed; a write of the whole `tiles` array still works and is
  caught by a hash.

The time of day and the day boundary

- `game.today()` also returns `hour`, `minute`, `second` (the local time of day) and `utc: { year, month, day, iso }` (the
  date in UTC). A built game reads the clock again about once a minute and on focus or resume, and `game.on("dayChanged",
  fn)` runs once when the local calendar day changes. `game.setDate`, `--date` and replay files (`time`) take a time,
  `game.setDate(iso, { utcOffsetMinutes })` the time zone; moving a test across midnight sends `dayChanged`.
- `platform.leaderboards.submit(id, score, { day })` and `entries(id, { day })` address the daily board of a given day (the
  fake and Steam keep every day). Without `day` a daily board is the local date's; pass `game.today().utc.iso` to both
  for one board worldwide. Game Center and Play Games reject a day other than the local or UTC today with `unsupported`.

Thai line breaks and the sara am check

- A wrapped line now also breaks after U+200B ZERO WIDTH SPACE (no width, never drawn), the UAX #14 spaces (U+1680,
  U+2000-U+2006, U+2008-U+200A, U+205F) and a hyphen (`-` unless a digit follows, U+2010), so Thai, Khmer, Lao and Burmese
  text whose translator marks word boundaries with U+200B wraps there. Unmarked text still needs a dictionary and is not broken.
- `FontCoverage::missing`, `localization validate` and the runtime missing-glyph warning check U+0E33 and U+0EB3 as the parts
  HarfBuzz always decomposes them into (U+0E4D U+0E32, U+0ECD U+0EB2), so a font lacking the nikhahit is reported.

Light2D in the stats and the perf budget

- `RenderStats` (`game.render_stats`, `game.renderStats()`) gets `lights2d` and `lights2dDropped`: the Light2D lights
  that shade a frame (at most 256 since the light buffer, see above) and the ones left out. `lights` and `lightsDropped` stay the 3D lights.
- `perf.measure`'s `lights`, and so the `maxLights` budget, is now the most 2D plus 3D lights of any frame: a budget
  written for a 2D game used to watch nothing.
- The Light2D lights of a frame are the ones that light the view: directional lights first, then the point lights whose
  radius reaches the camera's visible rectangle (more of their radius in view first, then the more intense ones). A light
  entirely off-view is never kept over one in view. More than the budget (256) in view logs one warning per scene naming the count.

Clipboard and window close

- `clipboard.read()` (a Promise) and `clipboard.write(text)` work on Windows, macOS, Linux and the web
  (`window.supports("clipboard")`); phones answer `unsupported`. Headless runs and tests use an in-memory clipboard, and a
  replay's `"clipboard"` entry sets it. A focused `TextField` pastes with Ctrl+V (Cmd+V) and copies with Ctrl/Cmd+C.
- `game.on("quit", fn)` runs when the player closes the window (close button, Cmd+Q, Alt+F4); `event.cancel()` keeps the
  game running. `game.quit()` closes without asking again. Desktop only. Test helper `game.closeWindow()`.

Music: scene loads, live volume, layers

- Fixed: a scene load stopped the sounds but kept the old scene's music in the mixer's memory, so a scene with the same
  `settings.music` started nothing (state said the track played, no voice did). A scene load now restarts the new scene's
  music, the same track included. `audio.music(path, { persist: true })` keeps a track playing through scene loads; a scene
  with the same `settings.music` does not restart it, another track replaces it.
- `audio.setVoiceVolume(id, volume, fade?)` changes the volume of a playing sound, with a straight-line fade.
- `audio.musicLayers({ name: path }, { volume, fade, persist, levels })` starts stems on the same audio sample (one lock,
  so no block of audio has only some of them) and `audio.setLayer(name, level, fade?)` fades them; the play log entries
  have a `layer` field. Layers loop, are never evicted by a full mixer, and `audio.stopMusic` stops all of them.
- `assets.synth_sound` levels every preset to about -18 LUFS (peak under -1 dBFS) instead of a -3 dBFS peak: squares, saws
  and noise were around -5 LUFS and tripped `factoria validate`'s loudness warning. The bytes of every seed change.

Steam from one Mac: optional plugin, exports, app 480, capsules

- The Steam plugin logs a warning, not an ERROR, when Valve's library is missing or Steam is not running. `project.new_plugin`
  (so `platform.add_backend`) now declares the plugin `"optional": true`; pass `optional: false` for a plugin the game needs.
- `project.export` takes `allowMissingPlugins` (`--allow-missing-plugins`): a plugin whose build for the target platform is
  missing is left out instead of stopping the export, a warning names it and the result lists it in `pluginsLeftOut`. It also
  works for a plugin that is not optional (the warning says scripts that call it fail). Plugins are still built only for the
  computer you build on: EXTENDING.md and EXPORTING.md say to take the other platforms' builds from CI.
- A desktop player with no build fingerprint (release 0.2.0 and older) now gets its own error: it predates fingerprints,
  `factoria setup players` installs the same one again, so use a newer player, `--player` or `--allow-player-mismatch`.
- `publish.steam` accepts app 480 (Spacewar) in a dry run with a warning; a real upload still refuses it.
- `assets.draw_capsules` takes `safeArea` (margins the logo stays inside, per store if needed; the Microsoft poster keeps its
  bottom third free by default) and `logoAnchor` (a name or a point of the safe area), and `focus` moves the logo when the key
  art already has the capsule's proportions. Misspelt keys get a "did you mean".

Video player

- A `Video` component draws an `.mpg` (MPEG-1 video with MP2 sound, decoded by pl_mpeg on the CPU, the same on every
  platform) in a UI rectangle: `fit` (`contain`, `cover`, `stretch`), `path`, `autoplay`, `loop`, `volume`, `bus`, `tint`.
  Time follows the game clock (it pauses with the game, headless runs and tests decode the same frames) and the sound plays
  through the mixer. Scripts use `entity.video`: `play`, `pause`, `stop`, `seek`, `time`, `duration`, `playing`, and
  `on("ended", fn)` (the game event `video.ended`).
- `assets.import` converts `.mp4`, `.m4v`, `.mov`, `.webm`, `.mkv` and `.avi` to an `.mpg` in `assets/video/` with ffmpeg
  (`factoria setup ffmpeg` installs one) and records where it came from; an `.mpg` is checked and copied. `factoria
  validate` reports a `Video` whose file is missing or that the engine cannot play, with the ffmpeg command that fixes it.
- `docs/MENUS.md` has a studio-intro recipe where any button skips the video. Clockwork Courier's intro is now a 4.8 second
  video of half a megabyte (FB-0051), recorded from an animated scene kept in `store/intro/`.
- Software renderers (llvmpipe, WARP) draw a full-screen video in about half the time: batches of plain textured quads
  (sprites, panels, a video) use a shader without the branches of glyphs, shapes and 2D lights, and a `Video` leaves out
  its background when the opaque picture covers it and draws an opaque picture without blending.

Steam Deck keyboard

- Plugin API 3: `add_text_input` registers a handler the engine calls when a `TextField` takes or loses the focus with a
  gamepad (the field's rectangle in window pixels, its text, `maxLength`), and `submit_text` hands text from the platform's
  keyboard back to that field on the next frame. Plugins built for version 1 or 2 are unaffected. `input.platformKeyboard`
  is true while a plugin's keyboard has the field, and the menu kit's on-screen keyboard stays closed then.
- The Steam plugin uses it: on a Steam Deck or in Big Picture it opens Steam's floating keyboard over the field, or the
  full-screen one where the floating one is not offered. Real-Deck check steps are in `docs/PLATFORM.md`.

Navigation: off-mesh links and walkable moving bodies

- `NavLink3D` (an entity's position to `end`, `bidirectional`, `cost`) is an off-mesh link: `nav.findPath` may take it to
  cross a gap, and the result's `links` lists `{point, entity}` where each link starts. A one-way link refuses the way
  back; a link whose end is off the mesh is ignored.
- `Collider3D.navWalkable` on a kinematic or jointed body (a rope bridge, a seesaw, a moving platform) leaves it out of
  the static bake and adds its top surface as walkable cells wherever it is now, joined to the ground within
  `stepHeight`; only the cells it left and entered are re-marked. `nav.info`, `nav.bake` and the editor's "Show navmesh"
  show links and these cells (`links`, `walkableBodies`). Clockwork Courier marks its bridges, seesaw and platforms, and
  `dog.js` needs one query instead of two (CC/FB-0056).

Physics across platforms

- The engine is built with no floating-point contraction (`-ffp-contract=off`, `/fp:precise`), and the simulation no longer
  calls the C library's `sin`/`cos`/`atan2`/`asin`/`acos` (each platform rounds their last bit differently): it uses
  deterministic versions built from `+ - * / sqrt` (`fa/core/det_math.h`), so physics is meant to give the same bits on
  Linux, Windows and macOS. CI prints a physics replay hash on those jobs and compares it with one committed value
  (`FA_PHYSICS_REPLAY_HASH`).
- `robust(check, { runs, nudge })` in `factoria:test` runs a check under small repeatable nudges of the bodies, so a level
  test asserts what is robust instead of an exact frame count. Clockwork Courier's "shortcut is not slower" test uses it
  (FB-0055).

Ads with consent on Android

- A plugin backend that offers only the `"ads"` service is an **ads backend**: it works next to the game's store backend, the
  engine sends `ads.*` to it and everything else to the store backend, `platform.ads.backend` picks one when a game has
  several, and `platform.state` shows `adsBackend` and `adsWhy`. Development runs and tests keep the fake.
- `platform.add_backend {"backend": "admob"}` writes and builds the `admob` plugin: Google's consent form (UMP) first, then
  the Mobile Ads SDK, one kept rewarded ad per placement, `{rewarded: true}` only from the SDK's reward callback. The
  app id is `platform.ads.appIds.android` in factoria.json, written into the manifest by the export; a development
  export always uses Google's test app id and test rewarded ad. `factoria validate` and a release export warn about the
  sample id, a missing app id or a placement without `ids.admob`. The command `admob.status` lists what is wrong.
- `platform.ads.audience` (`"general"`, `"children"`, `"mixed"`), `platform.ads.setUnderAge(bool)` and
  `platform.ads.privacyOptions()`; `platform.ads.consent()` gains `privacyOptions`. In a `"mixed"` game nothing is requested
  until the age is told. The menu kit has an `ageGate` part for it (`project.add_menu_kit {"parts": ["ageGate"]}`), and
  its options screen shows an "Ad privacy settings" button when Google requires one. The fake store answers all of it.

Ads with consent on iOS

- The `admob` plugin now has an iOS side, written in Swift: Google's consent form (UMP) first, then, only when
  `platform.ads.trackingPrompt` is true, Apple's "Allow tracking" sheet (never for a player under age), then the Mobile Ads
  SDK and the kept rewarded ad per placement. It behaves and answers like the Android one, including the audience,
  `setUnderAge`, `privacyOptions` and `admob.status`; `platform.ads.consent().tracking` is Apple's status when the game asks
  for the sheet. macOS has no AdMob SDK: the plugin offers no ads there and `platform.has("ads")` is false.
- Google's iOS SDK is a download, never in the repository: `platform.add_backend {"backend": "admob", "sdk": "<zip or folder>"}`
  copies its two XCFrameworks into the plugin (git ignores them) and builds the Swift side with Xcode.
- A plugin's `ios/plugin.json` can list vendored `xcframeworks` (the iOS export checks them, links the slice of the SDK and
  embeds a dynamic one) and `infoPlist` keys. The export writes `GADApplicationIdentifier` (`platform.ads.appIds.ios`; a
  development export always carries Google's iOS test app id), Google's `SKAdNetworkItems` and
  `NSUserTrackingUsageDescription` (`platform.ads.trackingDescription` or `trackingDescriptionKey`, translated per language of
  the game). A placement's iOS unit is `ids.admob_ios`. `factoria validate` and the export warn about the sample or missing
  iOS app id, a placement without `ids.admob_ios`, a tracking prompt with no ads plugin for iOS, and a tracking prompt with
  `export.ios.privacy.tracking` off.

Menu kit command

- `project.add_menu_kit {parts, overwrite}` (`factoria call project.add_menu_kit`) copies the menu kit of `docs/MENUS.md`
  into a game: main menu, options, credits, shop, pause, loading screen, on-screen keyboard and subtitles, each part with
  what it needs. It merges the kit's texts into the game's `locales/<language>.json` without replacing a key, leaves a
  file the game changed alone unless `overwrite` is true, and does nothing the second time. The kit lives in
  `templates/menus/`. The Controls tab of the options leaves out an action the game does not have.

Text entry on every device

- A focused `TextField` raises the phone's keyboard and hides it on blur (not for gamepad players). The menu kit in
  `docs/MENUS.md` has an on-screen keyboard for gamepad players (Latin, Cyrillic and Greek layouts; other scripts fall
  back to Latin). The web player takes typed text on mobile browsers through a hidden input, and the web smoke types
  into a field.

A 3D example game for phones

- Clockwork Courier (`examples/clockwork-courier`) is a complete 3D game made for phones first, the way your AI makes a
  game: a wind-up robot delivers parcels across six toy-town levels before its spring runs down, with touch controls
  (stick, buttons, drag to orbit, pinch to zoom), keyboard and gamepad, imported CC0 models and sounds, guard dogs,
  physics props, a studio intro and a loading screen, achievements, leaderboards, a paint shop, a "remove ads" purchase
  and a rewarded "more time" offer on the test store, comfort and accessibility options (left-handed layout, control size,
  reduced motion, assist mode, captions), English, Spanish and Japanese, and store texts, images and a trailer. Its
  `SHIPPING.md` says how each export was run (iOS Simulator, Android emulator, browser, macOS) and what is still done by
  hand.
- With this release's fixes, Clockwork Courier dropped the rest of its workarounds: the dog and tap-to-move walk on a
  `NavMesh3D`, the level panels are three shared prefabs, the name screen uses the menu kit's keyboard, the paints are
  per-material colours, the stars are ★ and ☆, and its tests reset their state with `game.resetState` and drive the
  mouse and the wheel. `ui.check_layout` finds no issue in it. Its studio intro is a video (FB-0051) and its dogs
  follow the courier across the rope bridges (FB-0056): no entry of its feedback is open.

A couch co-op example game for the desktop

- Burrow Brigade (`examples/burrow-brigade`) is a complete 2D game for one to four players on one screen, made for the
  desktop and Steam first, the way your AI makes a game: the miners dig down through mines generated from a seed (the
  same mine on every machine), in three strata with water, cave-ins and magma, gather ore, rescue moles and ride the lift
  up before their lamps burn out, while beetles, goblin thieves and the Mole King hunt them through the tunnels they dig.
  It has a join screen for four pads or a keyboard, per-player rebinding, a shared camera, revives, a pad unplugged
  mid-game, a camp with upgrades, three save slots whose format changed once (old saves are migrated), cloud copies, a
  daily dig and seed codes, achievements, stats and all-time and daily leaderboards on the test store, rich presence and
  Steam Deck checks, a news panel, remote balance values and opt-in analytics from its own server (a fake one in tests),
  music layers, ducking and captioned sound cues, display options, hold or toggle, a game speed for assist, English,
  Russian and Thai, and store texts, images and a trailer rebuilt by scripts. Its `SHIPPING.md` says how the Windows,
  Linux and macOS exports were made and what is still done by hand, and its `ENGINE_FEEDBACK.json` what it had to work
  around: those entries rank the next milestone.

Sliders and lists

- `Slider.format` shows the value as a pattern: `"{v:1}x"`, `"{percent}%"` (the value times 100); `Slider.formatKey` takes the
  pattern from a string table, so it can differ per language. `game.setSlider(id, value)` in a test drags a slider like a
  player: clamped, snapped to `step`, `ui.change` sent (the `ui.set_slider` command); writing `Slider.value` from a script
  still sends nothing. `ScrollList.shrink` makes a list as tall as its content up to the room the other children leave, so a
  short list in a `fit` panel makes a short panel.

Tests

- `factoria:test` can hold a mouse button and turn the wheel (`game.mouseDown`, `mouseUp`, `wheel`), so a drag orbit and a
  wheel zoom are tested through the input path. `game.resetState({ storage, platform })` clears the save data and the fake
  store between tests of one file, `game.setSystemLanguages([...])` sets what `i18n.systemLanguages` answers, and a quit
  request in a test (`game.quit()`, Back nobody consumes) sets `game.quitRequested` instead of stopping the run.
  SCRIPTING.md says `scene.load` from a test takes effect next frame while `game.load` is immediate. The hook warning
  skips a method that takes arguments, like `start(seconds)`.

Animation

- Models animated by node transforms play with no change to the file: a body part that is a child of an animated bone
  (RobotExpressive) and an animated mesh node with no skin at all (Kenney's cube pets) follow their node, through a
  rigid skin the importer makes. A file with clips that nothing can play logs one warning naming the clips.
- A glTF with several skins is drawn with each mesh's own skin (it used the first skin's palette for all, which bent the
  second skin's mesh out of shape). `Animator::skinPalettes` holds one palette per skin. Clockwork Courier imports the
  original robot and dog again and drops `tools/skinify.py` (FB-0001, FB-0002).

Graphics quality

- `window.renderScale` (0.5 to 1) draws the picture at a share of the window's size, in games and in tests;
  `window.supports("frameCap" | "renderScale" | "fullscreen" | "resize")` says what this run can do (the frame cap still
  throws on a phone: read it first); `game.device` gives `formFactor`, `gpuBackend`, `memoryGB` and a `tier` (`"low"`,
  `"medium"`, `"high"`) to pick a preset, with fixed values headless; tests pretend with `game.setDevice(...)`.
- `game.renderStats()` in tests (and the `game.render_stats` command) draws a frame when none was drawn yet and adds
  `shadowCasters` and `textureMB`. `perf.measure` records `triangles`, `lights` and `textureMB`; `perf.check` fails when
  they pass the baseline (only for baselines that have them) or the new `budgets` (`maxTriangles`, `maxLights`,
  `maxTextureMB`, `maxDrawCalls`, `maxEntities`).

Rendering

- `MeshRenderer.materialColors` colours one material of a glTF model: `{"Body": [0.2, 0.8, 0.7, 1]}` replaces the
  base colour factor of the material named "Body" on its sub-meshes (its texture still multiplies it), while
  `color` keeps tinting the whole model and the other materials keep their own colour. Entities that differ only in
  `materialColors` are drawn in separate batches. `factoria validate` checks the names against the model and suggests
  the right one for a typo (FB-0031).

Scripts

- `scene.preload(path)` and `assets.preload(paths)` read a scene's files (or a list of assets) ahead of time, a few per
  frame, and return a handle with `progress` (0..1), `done` and a `promise`: a loading screen keeps animating while the
  next level is read, and the `scene.load` that follows reads nothing from the disk. Tests do a fixed amount of work per
  frame, so they give the same result on every machine; `game.fileReads()` counts disk reads. Clockwork Courier's
  loading bar now shows real progress and its intro reads the title screen while it plays (FB-0012).
- A script stopped for running too long while inside `find`, `findIndex`, `findLast` or `findLastIndex` no longer
  crashes the game (a QuickJS bug freed one of the array's objects too early; the engine replaces those four). And a
  timer, tween or `world.on` listener stopped this way ends alone: before, every script after it was stopped too.

Platform services

- Ads: the new `platform.ads` service (`available(placement)`, `showRewarded(placement)` resolving `{rewarded, reason?}`
  and `consent()`) works with the placements of `factoria.json` `platform.ads.placements`, and `platform.release` is
  false in development runs, tests and the MCP server. The fake store answers with a scripted test ad (nothing is
  drawn): `game.platform.ad("watched" | "closedEarly" | "noFill" | "consentRefused")` chooses how it ends (command `platform.set_ad`). The real
  networks (Google UMP and AdMob, Apple ATT) are not in yet: the native backends answer `unavailable`.
- A leaderboard takes `period`: `"allTime"` (default), `"daily"` or `"weekly"`. The fake keeps one board per day or
  week of `game.today()`, so a daily board is empty again after `game.setDate` moves to the next day. The store backends
  map the period too (next bullet).
- Daily and weekly leaderboards on the stores. Steam keeps one board per period, named `<store name> <periodKey>`; Game
  Center uses a recurring leaderboard of App Store Connect as it is, at its current occurrence, or reads a classic board
  with the `.today` / `.week` time scope; Play Games reads the `TIME_SPAN_DAILY` / `TIME_SPAN_WEEKLY` table. These backends
  no longer reject periods with `unavailable`. Each store starts a period at its own time (table in docs/PLATFORM.md,
  "Leaderboard periods"); `submit` and `entries` carry `periodStart` and `periodEnd` when the store says them (Game Center's
  recurring boards), on `entries` as properties of the array (FB-0030).
- Clockwork Courier uses them instead of its ad stub and its single daily board (FB-0028, FB-0030).
- The fake store can take a purchase back, as a refund does: `game.platform.revoke(productId)` in tests (command
  `platform.revoke`) removes it from `restore()` and sends the `purchase` event with `status: "revoked"`.
- `platform.purchases.finish()` of a transaction the game was not told about now rejects its Promise with code
  `unknownId` (it used to throw at the call), so `.catch()` handles it like any store failure.
- Leaderboards in factoria.json take a `nameKey` (a locale key) instead of `name`, like achievements; the request
  the backend gets carries the name in the current language. PLATFORM.md documents `game.project.platform`, the
  catalog scripts can read.

Localization

- Numbers and times follow the language: `{v:number:1}` and `{t:duration}` in a string table and `i18n.number(v, {decimals})`
  and `i18n.duration(seconds)` in scripts write 1234.5 as "1,234.5", "1234,5" (Spanish; "12.345,5" from five digits),
  "1.234,5" (German), "1 234,5" (French, narrow no-break space) or "١٬٢٣٤٫٥" (Arabic digits), and 83.4 seconds as "1:23.4".
  A small table in the engine, no ICU; a language it does not know is written like English (docs/LOCALIZATION.md).
  Clockwork Courier uses it instead of its own helper (FB-0039).
- `keyArgs` on `Text`, `Button`, `Toggle`, `Slider`, `TextField` and `TouchButton`: the values of a key's `{placeholders}`
  (and the `count` of a plural entry), so a script sets them once instead of rewriting `text` every frame, and a language
  switch keeps them. `TouchButton` has a localization `key` like the other widgets. `factoria validate` checks a key's
  placeholders against the entity's `keyArgs`: it warns for a placeholder with no arg and for an arg no translation uses,
  not for every key with placeholders.
- `ui.check_layout {scenes, languages, textScales, pseudo}` loads each screen with UI in each language and text size
  (default: every language, scales 1 and 2) plus a pseudo-localized pass that lengthens every string by 40 %, and lists
  every text that overflows its box (the `ui.overflowed` test), overlaps another or leaves the screen, with the scene,
  the entity and its path, the key and the languages and scales where it happens. Clockwork Courier's profile keys and
  intro texts that broke at 200 % now shrink (FB-0043).

Tools

- `scene.format` with neither `paths`, `all` nor `check` writes nothing and fails with `paths_required`, saying how many
  scene and prefab files would change and the first ones; `paths` names the files or folders to format and
  `"all": true` takes the whole project. `factoria validate`'s hint names the files.
- `project.new_plugin` and `platform.add_backend` take `dryRun` (they list the `files` and the `keys` of
  `factoria.json` they would write, and write nothing) and refuse an argument they do not know, with a "did you mean".
- They patch `factoria.json` instead of rewriting it: only `plugins.<name>` is added, and the other keys, their order
  and the layout stay as they were. `export` and `icon` saves (the editor, `assets.draw_icon`) use the same patcher.
- The plugin templates come with a `.gitignore` for their build output.
- `factoria api --dts` lists a native plugin that is not built without its load error, so the typings no longer
  carry this machine's folders and come out the same on every machine.

Exports and store files

- `Products.storekit` is written by every iOS export whose catalog has products, with or without the Apple plugin, and
  holds one localization per language of the game (names and descriptions from the products' `titleKey` /
  `descriptionKey` in `locales/`).
- An Android source build reads the CMake version it will use instead of requiring `cmake;3.31.6`: the SDK's, else the
  newest 3.24+ in the SDK, else a 3.24+ of the computer (passed to Gradle as `cmake.dir`), so it works offline. The error
  hint says how to get one.
- `factoria` and `factoria_player` carry a build fingerprint (the commit, `-dirty` when it had uncommitted changes;
  `factoria version` prints it). A desktop export with a player from another build stops with an error that names both
  builds; `--allow-player-mismatch` (the `export` command's `allowPlayerMismatch`) bundles it anyway.
- `setup.install {"component": "ffmpeg"}` (`factoria setup ffmpeg`) downloads a pinned static ffmpeg, so
  `factoria run --record-video trailer.mp4` works without installing it by hand; `setup.status` lists the component.

Assets

- `assets.import` of a `.glb` or `.gltf` copies the textures and buffers its `uri`s point at next to the model (with
  provenance), shares an identical file already there, warns when the destination holds a different image of the same
  name (kits that ship different `colormap.png` files) and stops on a different buffer; `factoria validate` reports a
  model whose texture or buffer file is missing.
- `assets.set_provenance` (and every command that edits `assets.json`) keeps the order of a hand-ordered file instead of
  sorting all of it; a sorted file stays sorted.
- `factoria validate`'s loudness warnings use the sound as it plays: a project with `defaults.audio.normalize` has no
  peak or loudness warning left for it.
- New `assets.synth_sound {path, preset, seed}` makes barks, growls, meows and the usual effects (coin, jump, hit,
  explosion, laser...) offline as a deterministic WAV, with its provenance; no provider and no key.

Physics

- 3D physics no longer depends on what the World held before a scene loaded: `Joint3D` constraints are solved in the
  scene's entity order instead of the order of their entity ids, so a rope bridge or a seesaw behaves the same after
  other scenes, destroyed entities or reused entity slots (a level test could take 2000 or 2800 frames depending on
  which tests ran first).
- `CharacterController3D` on moving and dynamic bodies: a kinematic platform it stands on carries it (displacement, and the
  turn of a spinning platform; `carriedByPlatforms`, default true), it presses on the dynamic body below with
  `mass` x gravity (`applyWeight`, `mass`), so a seesaw tips and a bridge plank sags, and `pushStrength` scales the push on
  the free dynamic bodies it walks into (a body held by a `Joint3D` is never shoved). Clockwork Courier dropped its
  workarounds (FB-0010, FB-0011).
- A dynamic body that starts inside a static collider is reported once in the log (both entities, the depth and the fix),
  and `factoria validate` warns about it for scenes.
- Joints form islands: a chain of planks falls asleep when it is at rest, a collision in one island no longer stops the
  rest of the world, and two bridges side by side move exactly as each would alone. Chains of three or more jointed
  bodies get more solver iterations and settle by themselves, so a rope bridge no longer needs heavy damping
  (FB-0014, FB-0015, FB-0017, FB-0053, FB-0054).
- `Joint3D.damping` (friction on the relative turning) and `Joint3D.stalled` (read only: a motor pushes and the joint
  cannot turn, for example a gate against a wall). `docs/AI_GUIDE.md` has a rope bridge recipe.
- `connected: ""` means the world on `Joint3D` and `Joint2D` in scenes, `factoria validate` and scripts.

Navigation

- Path finding for 3D characters. A `NavMesh3D` component (`size`, `cellSize`, `agentRadius`, `agentHeight`,
  `stepHeight`, `maxSlope`) is baked by itself from the static colliders inside its box into a walkable grid;
  `nav.findPath(from, to, { radius })` in scripts and `nav.find_path` return the few corner points of a path around
  walls and up ramps, never up a step above `stepHeight`. A start or goal off the walkable ground, or in another
  area, comes back as a result that says how far the nearest walkable point is and how to fix it; a `radius` bigger
  than the mesh was baked for is an error that says to bake for the bigger agent. `nav.bake` and `nav.info` report the
  cells and areas (no timing: two bakes are identical). A collider with `navObstacle` is left out of the bake and blocks
  the cells it covers each time it moves (a gate, a crate). The editor draws the walkable cells (Window > Show navmesh).
  Guide: docs/NAVIGATION.md (FB-0009).

Native plugins

- `"optional": true` on a plugin in `factoria.json` says the game runs without it: when its build for your computer is
  missing (a store SDK only some developers build), `factoria validate` warns instead of failing. Exporting for a
  platform still needs that platform's build.

Mac App Store

- `sign.macos` takes `distribution: "appStore"`: it signs the macOS export with the App Sandbox, an Apple Distribution
  certificate and a provisioning profile, and builds the signed installer `<game-slug>-macos.pkg` with `productbuild`.
  `identity: "-"` signs ad hoc so you can run the sandboxed game on your own Mac.
- `publish.appstore` uploads that `.pkg` too (`platforms: ["macos"]`).
- New `export.macos` settings: `buildNumber`, `usesNonExemptEncryption` and `entitlements`.

Microsoft Store

- `factoria export --platform windows --format msix` (or `export.windows.format: "msix"`) writes
  `<slug>-windows.msix` next to the Windows folder, from any computer: the unsigned package the Microsoft Store takes, with
  the manifest, the logos cut from your icon and the block map. The identity comes from the new `export.windows.msix`
  settings (the editor's Windows tab and Export window have them).
- New `sign.windows` signs the package with your `.pfx` (`signtool`, or `osslsigncode` on macOS and Linux) to install it on
  a PC; on Windows `testCertificate` makes a self-signed one. The password is only read from the environment.
- New `publish.microsoft` uploads the package with the Microsoft Store Developer CLI.
- The web export and the AppImage use a shared zip writer; their bytes did not change in meaning.

Scripting

- New `game.today()` returns `{ year, month, day, weekday, utcOffsetMinutes, iso }`: the player's real local date in a
  built game, the fixed date `2026-01-01` in `factoria test` and headless runs, and the date a replay recorded when it
  plays (an old replay without one uses the fixed date). `game.setDate("YYYY-MM-DD")` in `factoria:test` changes it, and
  `--date` does the same for `run`, `screenshot`, `test`, `call`, `session` and `mcp`. An impossible date (`2026-02-29`)
  or another format is an error that says what is wrong. Read the date with `game.today()`, never `Date`.
- New `game.on("suspend" | "resume" | "focus" | "blur", fn)` and `game.focused` tell scripts when the app goes to the
  background and back, or the window loses the focus. The new `factoria.json` setting `pauseOnSuspend` (default `true`)
  pauses the game and the music while the app is in the background; `game.suspend()`, `game.resume()`, `game.focus()`
  and `game.blur()` in `factoria:test` test it. A pause menu opened by a `suspend` handler stays after resume.
- Clockwork Courier uses the date and the lifecycle API instead of its workarounds (FB-0019, FB-0035).
- `factoria test` no longer stops a test file after 600 s in all: only a single test over 60 s is stopped, so a long file
  of quick tests passes in a Debug build on a busy machine. The message says which limit it was.

UI

- A child can be put at a place among its siblings, which is the order a `column` or `row` layout follows:
  `scene.set_parent {id, parent, index}` (also `scene.spawn {index}`), `entity.setParent(parent, keepWorld, index)` and
  `world.spawn(json, { parent, index })` / `world.spawnPrefab(path, { parent, index })`. 0 is first; an index outside
  0..(number of the parent's other children) is an error that says the range. The order is saved with the scene.
- One panel can serve several scenes: a prefab reference takes `overrides`, a map from a child of the prefab (its id,
  name or a path like `"Panel/Title"`) to the `name`, `tags`, `active` and `components` to change, and
  `world.spawnPrefab(path, { childOverrides })` and `scene.spawn {prefab, overrides}` do the same. A child or field that
  does not exist is an error with a "did you mean". docs/MENUS.md shows it. Clockwork Courier's FB-0032 and FB-0023.
- Text that fits: `autoShrink` (with `minFontSize`, default 10) on `Text`, `Button`, `Toggle`, `Slider` and `TouchButton`
  shrinks the font until the text fits its box (`Text.maxWidth` x the new `Text.maxHeight`, or the room the widget leaves
  its label), never under `minFontSize` times `ui.textScale`. `maxTextScale` on `Text`, every widget and `TouchButton`
  stops `ui.textScale` from growing that text past a scale (a heading at 1.3). `Toggle.maxWidth` and `Slider.maxWidth`
  wrap long labels, `Slider.labelAbove` puts the label above the track. Layout, `autoSize`, `ui.measureText` (new
  options, returns `fontSize` too), `ui.rectOf` and the 2D and 3D renderers use the same size.
- New `ui.overflowed(idOrEntity)` and `"overflowed": true` in `ui.state` say a text still does not fit its box.
- Clockwork Courier dropped its text-fit workarounds in the level select, HUD, toasts and options (FB-0041, FB-0042).

## 0.2.0

FactorIA 0.2.0 is about finishing and shipping a game: edit scenes by hand next to your AI, translate the game, add
achievements and purchases on Steam, the App Store and Google Play, and export it for desktop stores, phones and the
browser.

Edit by hand in the editor

- The editor has a Hierarchy and an Inspector now. The Hierarchy lists every entity as a tree: click one to select it (a
  click in the game view selects it there too), drag it onto another to make it a child, drop it on the empty space to
  make it a top-level entity, and right-click for create child, duplicate, rename, active and delete. There is a search box.
- The Inspector shows the selected entity's components with a field for every value: tick boxes, number drags that
  respect each field's range, vectors, colour pickers, drop-downs for choices and for other entities, file pickers for
  pictures, sounds and materials, and a text box for free-form JSON. Hover a name to read what it does. Add Component and
  the x on a component's header add and remove components.
- Everything you change by hand goes through the same commands the AI uses, so Undo works (one drag is one step) and a
  value a field does not accept is refused with the reason. While the game plays you can edit the running game; Stop
  takes those edits back.
- A `MeshRenderer` shows its material's settings with the right widgets (sliders, vectors, colour pickers) and a Reset
  button for each, and a material that does not compile shows its error right under the material field.
- The new Project panel (a tab next to Console, also in the View menu) lists the project's files with thumbnails, a folder
  tree, a type filter and a search box. Drag a picture, sound, font, mesh, script or material onto an Inspector field of that
  type to set it, drag a prefab onto the game view to spawn it where you drop it, double-click a scene to open it, and
  right-click a file to show it in the file manager, copy its path or delete it. `assets.list` now also reports `material`
  for `.material.json` files.
- New command `scene.set_parent` moves an entity under another one (or to the top level), for the AI too.
- Move, rotate and scale in the game view: select something and drag the arrows (W), the rings (E) or the handles (R) that
  appear on it; Q goes back to just selecting. The four buttons next to Undo do the same. Hold Ctrl to snap, press Esc in
  the middle of a drag to cancel it. A whole drag is one Undo step, it works for 2D and 3D, for things on the screen (like
  a score) and for things inside another, and while the game is paused it edits the running game.

Revert an AI run

- Before each AI run the editor now saves a checkpoint of the project's files. When the run changed something, the chat
  shows "This run changed N files" with a Revert button: one click (after a confirmation) puts back every file, deletes the
  ones the run created and puts the scene back as one Undo step. Undo revert takes it back, and Edit > Revert Last AI Run
  does the same from the menu. The AI is told about the revert in your next message. Checkpoints are kept in
  `.factoria/checkpoints/` (newest 30) and are also available as the commands `checkpoint.create`, `checkpoint.list`,
  `checkpoint.diff` and `checkpoint.restore`.

Debug your scripts in VS Code

- Press F5 in VS Code on a FactorIA project: the game starts and stops on your breakpoints. Step through your code line
  by line, look at every variable and at `this`, watch expressions, and type JavaScript in the debug console to read or
  change the running game. `factoria setup vscode` (or Install in the editor's Setup window) adds the extension to VS
  Code, and to Insiders, VSCodium and Cursor when you have them; new projects come with a `.vscode/launch.json`.
- Breakpoints can have a condition, a hit count or a message to print instead of stopping (a logpoint, with
  `{expressions}` filled in). The debugger can stop on every error your scripts throw or only on the ones nothing
  catches, and Pause stops the game wherever it is, even in an endless loop.
- Three ways to start: play the game in its window, run it without a window for a number of frames (with an input
  replay), or run your tests and stop inside them.
- For the AI: `script.trace` puts the same breakpoints on a headless run and returns what it saw as JSON (the call stack,
  the local variables and your watch expressions at each hit, and the logpoint lines), so it can find out why a script
  misbehaves without guessing. See `factoria docs read debugging`.
- Exported games cannot be debugged: debug the project.

Find out what makes your game slow

- A profiler: it tells you where the time of a frame goes, per part of the engine (physics, scripts, sound, drawing...) and
  per script class, with the milliseconds each class takes per frame and how often it runs, plus the GPU time (on
  Windows and Linux; other systems say why not) and memory use. It only measures: your game plays exactly the same.
- In the editor, View > Profiler shows it live while you play. Every play session you record now also keeps this
  summary in `play.report`, so the AI can see which script is the slow one.
- `perf.profile` does the same on a headless run, with an optional input replay to reach the heavy part of the game. See
  `factoria docs read performance`.

Your game in every language

- Keep your texts in string tables (`locales/en.json`, `locales/es.json`...) and show them with a `key` on a `Text` or an
  interface widget, or with `i18n.t("score", { points: 3 })` in scripts: placeholders, plural forms for each language and
  a fallback language are built in. The game starts in the player's system language, and `i18n.setLanguage("es")`
  switches at any moment, every text at once.
- Text is laid out properly in every script: Arabic letters join and right-to-left lines start from the right, Chinese,
  Japanese and Korean lines break between characters, and fallback fonts (`fallbackFonts` for the whole game,
  `languageFonts` per language, in the `localization` part of `factoria.json`) fill in the characters your main font
  does not have.
- A text size option for players: `ui.textScale` makes every on-screen text and widget label bigger or smaller.
- `factoria validate` finds missing and leftover keys (with "did you mean"), wrong placeholders and plural forms, and
  any character none of your fonts can draw, naming the text and the file.
- Send your texts to translators as a spreadsheet (CSV) or an XLIFF file with the command `i18n.export`, and bring the
  translations back with `i18n.import`.
- `factoria docs read localization` is the guide, and the ready-made menus have a Language option.

Achievements, leaderboards, cloud saves and purchases

- One script API for what a store gives a game: `platform` has achievements, stats, leaderboards, cloud saves, in-game
  purchases (with restore), the store's overlay and rich presence. You write your game once, and the store it runs in
  answers. List your achievements, leaderboards and products in the `platform` part of `factoria.json`.
- Steam, Apple (App Store purchases, Game Center, iCloud) and Google Play (Play Billing, Play Games, Play Integrity):
  `factoria call platform.add_backend '{"backend": "steam"}'` (or `"apple"`, `"googleplay"`) sets one up in one step and
  lists what is left for you to do in the store's dashboard.
- While you make the game, and in every test, a pretend store answers, so your AI can test a purchase, a cancelled one
  or an achievement without a store account. An exported game with no store set up never gives purchases away.
- `platform.integrity.token` gives your game's server a signed token that vouches for the app and the device (Google
  Play).
- So far these were tried against simulated stores only: make a test purchase with the store's sandbox or test account
  before you release. `factoria docs read platform` is the guide.

Ready for the desktop stores

- `factoria export --release` on Windows, macOS and Linux puts the whole game in one file, `game.pak`, with the scripts
  compiled to bytecode. Exports no longer copy the project's top-level `README.md`.
- When an exported game crashes it writes a report (what happened, where in the code, the last lines of the log) in a
  `crashes` folder next to `log.txt`, plus a minidump on Windows. Nothing is sent anywhere: a player can send it to you.
- Upload your game to Steam (`publish.steam`, with steamcmd), itch.io (`publish.itch`, with butler), the Epic Games
  Store (`publish.epic`, with BuildPatchTool) and GOG (`publish.gog`, with Galaxy Pipeline Builder) from your AI or the
  command line, each with a dry run to try first. Passwords and keys stay in environment variables or your user
  folder, never in the project.
- macOS: `factoria call sign.macos` signs your exported app with your Developer ID, has Apple notarize it and staples
  the ticket, so players can open it without a warning.
- Linux: `factoria export --platform linux --format appimage` makes the game one AppImage file with its icon and menu
  entry. Linux games exported from the FactorIA download now run on older systems and in the Steam Linux Runtime (glibc
  2.31 or newer).
- `factoria call project.new_ci_workflow` writes a GitHub Actions workflow that validates, tests and exports your game on
  every push.

Phones and tablets

- Change to know about: `factoria export --platform android --release` now stops when your game has no signing key,
  because Google Play rejects an app signed with the debug key. The message tells you how to make a key. To try a release
  build on your own phone anyway, add `--allow-debug-key` (the export command's `allowDebugKey` option).
- Menus and heads-up displays can keep clear of the notch, rounded corners and system bars: switch on `safeArea` next to
  `anchor` on a sprite, text, shape, particle emitter or interface widget, and it is placed against the free part of the
  screen. Scripts can read it as `screen.safeArea`. You can try a notched phone without one with
  `screen.set_safe_area {"profile":"phone-portrait"}`.
- The Android Back button and gesture now reach your game as `input.onBack`: close a menu or go up one screen and the game
  stays open. If nothing handles it the game closes, as before.
- `input.vibrate()` makes a phone vibrate (a light tap on iPhones). Exported Android games include the permission for it.
- Android games can raise the on-screen keyboard for text fields and receive what is typed. Keyboards that compose words
  (predictive text, swipe typing, emoji, Asian languages) still cannot type into an Android game; physical keyboards work.
- An on-screen gamepad for games made for a controller: add a `TouchStick` and a few `TouchButton`s to a scene and players
  move with the thumb and press A, B... on the screen. They press the same gamepad buttons and stick a real controller
  does, so your game needs no other change. Several fingers work at once, the controls stay clear of the notch, and they
  only show while the player is using touch (they hide when a real controller or keyboard is used).
- Tests can press Back, fake a notch, check vibrations and touch the on-screen gamepad without a device.
- iPhone and iPad exports include the privacy file the App Store asks for (`PrivacyInfo.xcprivacy`), listing the few
  system features FactorIA uses and saying that nothing is collected or tracked. If your game or a plugin collects data,
  tracks players or uses more system features, add them under `export.ios.privacy` in `factoria.json`; mistakes in it are
  reported with the fix. The app also says it uses no special encryption, so App Store Connect stops asking at every
  upload (`export.ios.usesNonExemptEncryption` changes it).
- `factoria setup players --platforms mobile` now also downloads the iPhone and iPad libraries on Windows and Linux, so
  you can prepare an iOS project there without pointing at a macOS download. Building it still needs a Mac.
- The mobile guide lists what to answer in Google Play's Data safety form and in App Store Connect's App Privacy section.

Upload your phone builds

- Upload your iOS build to TestFlight and App Store Connect from your AI or the command line (`publish.appstore`,
  on a Mac): you archive the game in Xcode as before, FactorIA sends the `.ipa` with an App Store Connect API key. Run it
  with `dryRun` first to see the exact command.
- Upload your Android release bundle to Google Play (`publish.googleplay`, needs fastlane): pick the track (internal
  testing by default), leave the release as a draft or roll it out, and send the "What's new" text per language from
  files of your project. A bundle signed with the debug key is refused before anything is sent. Google Play still wants the
  first bundle of a new app uploaded by hand.
- Your keys stay in files outside the project and are never shown or logged.

Games in the browser

- Export your game for the web: `factoria export --platform web` (or Web in the editor's Export window) makes a folder
  with an `index.html` that plays the game in any modern browser, and a `.zip` of it ready to upload to itch.io as an
  HTML5 game. The page shows a loading bar and explains in plain words when something is wrong (an old browser, a
  download that failed).
- In the browser, saves made with `storage` are kept between visits, sound starts with the player's first click or key,
  and gamepads work. Native plugins and store services (achievements, purchases) are not available on the web.
- The web player comes with every FactorIA download; `factoria setup players --platforms web` installs it if you need it.

Better looking 3D, and much bigger 3D scenes

- Materials look like real materials: `metallic` and `roughness` now use physically based shading, and shiny surfaces
  reflect the sky of your scene (`skyColor` and `horizonColor`), so a metal sphere looks like metal without any extra
  file. Scenes you already have look close to before, with a faint sheen on plastic and stone.
- Normal maps: give a `MeshRenderer` a `normalMap` picture to add bumps, scratches or bricks without extra triangles, and
  `normalScale` to make them stronger or softer.
- glTF models keep their materials: metallic and roughness (with their textures), normal maps, ambient occlusion and
  glowing parts are read from the file. Models without tangents get them generated.
- Big scenes are cheaper: anything outside the camera's view is skipped, and many copies of the same mesh with the same
  material are drawn together. Ten thousand identical cubes now cost one draw.
- Up to 32 lights at once instead of 8. With more, the engine keeps the sun and the brightest, nearest lights.
- The render statistics (`play.report`) now also count `meshesCulled`, `meshBatches` and `lightsDropped`.
- Your own shaders: a `MeshRenderer` can use a material file (`material`) with a few lines of GLSL that change how the
  surface looks (a pulsing glow, cut-out leaves, moving water) or move its vertices. Shadows follow the moved or cut-out
  shape, each entity can change the material's values (`materialParams`), and a change to the file shows up at once
  while the game runs. A material that does not compile draws magenta and says which line is wrong.
- A new guide for your own shaders (`factoria docs read shaders`): how to write a material, the rules for its few lines
  of GLSL, and five ready examples: a pulsing glow, dissolving, water, wind on grass and a rim light. The shader
  compiler comes with FactorIA, next to `factoria` in every download, so there is nothing to install. If Windows
  Defender removes `sokol-shdc.exe` by mistake, restore it from Windows Security > Protection history, or run
  `factoria setup shaders` to get it again.
- In the editor, saving a material, a shader or a texture updates the game view right away, while editing and while
  playing. A mistake in a shader keeps the last picture that worked and shows one error in the Console with the file
  and the line.
- The Gem Roller example has glowing, pulsing gems made with a custom material.
- Not yet: an environment picture for reflections.

Animation

- 3D models with skeletons: a glTF/GLB with named animation clips plays through the new `Animator` component, which goes on
  the entity with the model's `MeshRenderer`. Switch clips with a smooth cross-fade (`entity.animator.play("Run", 0.2)`),
  change the speed, and get an event when a clip reaches a moment you chose (a footstep at 0.3 s) with `world.on`.
- A small state machine is built in: list the parameters, the states (a clip each) and the transitions in the scene file
  (`"when": "speed > 0.1"`), then your script only sets values: `entity.animator.set("speed", 3)`. Animation runs in the
  fixed step, so tests and replays give the same result every time.
- New `tween` and `ease` in the scripting API: slide a menu in, fade a sprite, grow a pickup. Works on numbers, vectors
  and colors of anything, in 2D and 3D, with 30 easings (`"backOut"`, `"bounceOut"`...), delay, repeat, yoyo, chaining and
  `await tween(...).finished`.
- Animated models are drawn deformed by the animation, shadows included (up to 64 joints per model; a model with more
  is drawn in its bind pose and a warning says so). The new guide is `factoria docs read animation`.

3D physics: new shapes, joints and a character controller

- 3D colliders can now be capsules (`shape: "capsule"` with `radius` and `height`), convex shapes (`"convex"`, the
  smallest solid that wraps a model) and triangle meshes (`"mesh"`, the exact surface of a model, for terrain, ramps and
  level geometry). For the last two, set `Collider3D.mesh` to a primitive name or to your `.glb`/`.gltf` file, usually
  the same as the entity's `MeshRenderer.mesh`. All shapes collide with each other, and raycasts, shape casts, triggers,
  sleeping and the physics debug view work with all of them.
- A mesh collider is for things that never move. Put it on a body that moves and the engine tells you once, in plain
  words, to use a convex collider or several boxes and capsules instead.
- Joints: add a `Joint3D` to an entity that has a body to make a hinge (doors, pendulums, wheels, with optional angle
  limits and a motor), a ball joint (chains, shoulders) or a fixed joint, hanging from the world or from another body.
  A swinging pendulum keeps its real period.
- Character controller: add `CharacterController3D` to an entity and call `physics.moveCharacter(entity, delta)` each
  frame. It slides along walls, steps up stairs and kerbs (`stepOffset`), refuses slopes steeper than `slopeLimit`, stays
  on the ground going down a ramp, pushes crates, and tells you if it is on the ground (`isGrounded`, `groundNormal`).
  You add your own gravity and jump.
- Limits for now: a model with more than 256 vertices used as a convex collider is simplified to 256 points, jointed
  bodies never fall asleep, and the character is not carried by moving platforms.

More for 2D games

- Flipped and rotated tiles: a tile number can carry a flip or turn, so one picture serves four directions. In
  `scene.import_ascii` a legend entry accepts `flipX`, `flipY` and `rotate` (0, 90, 180, 270). Collision follows the
  plain tile number.
- 9-slice sprites: give a `Sprite` a `slice` (left, top, right, bottom in pixels of the picture) and it stretches like a
  button background, corners intact. It works with flips and with pictures packed in an atlas.
- 2D lights: a `Light2D` entity (point or directional) lights the sprites and tilemaps that set `lit`. Add a
  `normalMap` and the sprite shows bumps that react to the light. `SceneSettings.ambientLight` is the unlit brightness.
  Up to 16 lights at once; the nearest to the camera win.
- Parallax: a `Parallax` component makes a far background move slower than the camera (or faster, for foreground), and
  a sprite can repeat endlessly with `repeatX` / `repeatY`.
- Joints: a `Joint2D` on a body ties it to the world or another body as a hinge (revolute), rope (distance), slider
  (prismatic) or glue (weld), with limits, motors and springs. Scripts can read the reaction force and switch a motor.

Accessibility, speed checks and legal texts

- Colour filters for players: `colorFilter` on the `Camera` turns the whole picture greyscale, raises the contrast, or
  corrects the colours for players who cannot tell red from green (`protanopia`, `deuteranopia`) or blue from yellow
  (`tritanopia`). Your options screen sets it from the player's choice.
- See your game as a colour-blind player does: `factoria run --headless --screenshot-at 60 --screenshot-simulate
  deuteranopia` (or `simulate` in `game.screenshot`) saves the screenshot that way without changing the game, so you or
  your AI can check that hazards still stand out.
- Read menus aloud: `ui.speak(text)` says a line with the computer's or phone's own voice, in the game's language, and
  `ui.speechAvailable` tells whether the system can speak. Speak the button that has the focus and players who cannot
  read the screen can use your menus. Tests check what would be said with `game.spoken()`, without sound.
- Start from the player's own settings: `game.accessibility` tells you the text size the player set on their system,
  and whether they asked for less motion, high contrast or use a screen reader. Use it to set your options on the first
  run; what the player then chooses in your game wins.
- Subtitles: add a `Captions` entity to your scene, then `audio.play("voice.wav", { caption: "Watch out!" })` shows the
  line while the sound plays, and `ui.caption(text)` shows one with no sound. They follow the text size and the player's
  language, and an option can turn them off. Tests list them with `game.captions()`.
- `factoria docs read menus` shows each of these as an option of the ready-made menus, and the accessibility part of
  `factoria docs read finishing` lists them all.
- Speed and memory checks: `factoria call perf.baseline` measures how much CPU time and memory your game uses and how
  many things it draws, and saves it in `perf.json`. `factoria call perf.check` then fails when the game got much
  heavier, so you notice before your players do. `factoria docs read performance` explains how to use it in your own
  checks.
- Privacy policy and license: `factoria docs read legal` says what FactorIA sends from your game (nothing by itself),
  gives a privacy policy you can copy for a game that collects nothing, the paragraphs to add when you use analytics,
  ads, accounts or cloud saves, and when you need a license agreement of your own. It is not legal advice.

Guides for finishing and publishing

- `factoria docs read finishing` takes a game that plays to a game a store accepts, step by step with Lantern Keep's
  code: menus, options that stay set, saves that survive updates, languages, accessibility, credits and tests.
- `factoria docs read publishing` has one checklist per store (Steam, Epic, GOG, Microsoft Store, Google Play, App
  Store, itch.io, your own site): what FactorIA does for you and what you still do by hand, with fees and review times.
- Store images and trailers: `assets.draw_capsules` makes every picture a store page asks for (Steam capsules, Epic,
  GOG, Microsoft Store, Google Play, App Store screenshots, the itch.io cover) from one picture of your game and your
  logo or title. `factoria run --headless --input replay.json --record-video trailer.avi` records a trailer from an
  input replay, with sound; ask for `trailer.mp4` when ffmpeg is installed.

A complete example game

- Lantern Keep (`examples/lantern-keep`) is a small but complete 2D platformer, made the way your AI makes a game: six
  levels, menus, three save slots with a level select and cloud saves, achievements, leaderboards and a shop of cosmetics
  on the test store, accessibility options (text size, a slower game, invincibility, no screen shake), four languages
  including Arabic, an on-screen gamepad for phones and export settings ready for the stores. Read it, copy from it, or
  point your AI at it. Its `SHIPPING.md` lists what each store needs and what is still done by hand.

Learn FactorIA

- Two tutorials for people. `factoria docs read first-game-with-ai` makes your first game with the editor and an AI in
  six rounds, starting from the 2D platformer template: what to type, what to look for and how to undo.
  `factoria docs read make-by-hand` builds a small game by hand from the empty template (collect four gems, then a "You
  win!" screen), one whole file at a time, with a check after each step.
- What a game costs to make with AI: `factoria docs read ai-costs` shows what a complete game cost in a real run, what
  makes a run cheap or expensive, how to set a spending limit and where to see what you spent.
- A browsable API reference in the FactorIA repository: `docs/reference/` has an index of every component and command,
  one page per category, and the version that added each one.
- Searching the docs (`factoria docs search`, and your AI over MCP) shows the best section of each guide first, so a
  name like `onTriggerEnter` finds the scripting reference instead of many sections of one tutorial.

Fixed while making Lantern Keep

Lantern Keep showed what a complete game still had to work around. These are now in the engine, so your AI writes less
code of its own:

- Menus fit their texts: `autoSize` on `Button`, `Toggle` and `Slider` grows the widget to its label at a big text
  size or in a longer language. A button label with several lines is centred line by line, `maxWidth` wraps it, and a
  label that still does not fit is cut at the button's edge. `ScrollList.fill` lets a list take the height the rest of a
  column leaves, and a fitted panel bigger than the screen logs a warning naming it.
- Scripts can apply the layout right away: `ui.layout()` sizes and places the widgets at once, so a script that changes
  a text can read the real sizes (`Button.size`, `Panel.size`, `ui.rectOf`) straight after, without waiting for the next
  frame.
- Panels that do not fit: `fallbackLayout` (row, column or grid) is used instead of `layout` when the panel would leave
  the screen, for example a column that becomes a row at a big text size. `uniformSize` makes the `autoSize` buttons,
  toggles and sliders in a panel all as wide as the widest one and as tall as the tallest one.
- Right-to-left languages: a `Text` with `align: "start"` or `"end"` follows the language's direction, and a panel with
  `direction: "auto"` lays out its rows right to left in Arabic or Hebrew. Scripts read `i18n.direction`.
- Panels: a script hook `onEnable()` runs every time an entity is shown and `onDisable()` every time it is hidden, before
  the frame is drawn, so a panel never shows its placeholder texts for a frame. A hidden panel already has its
  `.behaviour`.
- Focus with a gamepad or the keyboard goes to the widget you expect in the direction you press, and a greyed-out
  `autoFocus` button no longer keeps the focus.
- 2D: a moving platform carries the bodies standing on it, also when the player's script sets its speed every frame
  (that speed is now relative to the platform; drop any carry code of your own). `Shape2D.lit` lets the placeholder
  shapes be lit by `Light2D`.
- ASCII levels: `scene.import_ascii` keeps prefabs as references, so editing a prefab changes every level without
  importing the maps again, and level files stay small. Several maps can share one legend file (`legendFrom`).
- Scripts: vectors and colours work like small arrays (`const [x, y] = position`, `position[0]`, `...color`), reading
  `game.screenSize` is about 60 times faster, and a promise rejection you handle a moment later is no longer reported.
  Unpausing the game keeps the speed you set in `time.scale`.
- Saves: a save file is written in one go, so a crash cannot leave half a file. A save file that does not load is kept
  as `storage.corrupt.json` instead of being overwritten, and `storage.corrupt` tells your game.
- Store texts can be translated: achievements and products in `factoria.json` can name a key of your `locales` files
  (`nameKey`, `descriptionKey`, `titleKey`), and the game lists them in the player's language.
- Tests: `factoria test tests/saves.test.js` runs one test file (or several, or a pattern). `game.click("playButton")`
  presses a widget by its id, `ui.rectOf` gives where a widget is on screen, `expect(x).toMatchObject({...})` checks
  some fields of an object, `game.platform.set({ backend: "none" })` tests the game as on a store-less build, and a
  "not a function" error shows the line with a mark under the call.
- Exports: `export.exclude` in `factoria.json` leaves folders out of every export (`"store/**"`). A publish dry run
  works before the store's upload tool is installed and lists what is missing. The exported game takes `--frames 120` to
  run a few frames and exit, as a quick check in CI. `factoria validate` warns about pictures phones cannot compress, and
  new projects keep `build/` out of git.
- The export guide (`factoria docs read exporting`) has one table of what each export needs (downloads, Android tools,
  Xcode) and whether your computer can make it at all, offline or after a download. A new Microsoft Store section says
  what FactorIA covers and what you still do by hand.
- A game icon without an image service: `assets.draw_icon` draws your icon and the Android icon from shapes, colours and
  text, so you need no paid picture provider and no Python.
- Store screenshots at full size: `game.screenshot` takes a `scale` (so does `factoria run --render-scale`), so a
  1280x720 game makes sharp 1920x1080 pictures instead of enlarged ones. The HUD and the visible area stay the same.
- `i18n.import` for a new language keeps the shape of your main language file, and `factoria docs read` prints clean
  text on Windows.
- The reference (`factoria api`, `docs/COMPONENTS.md`, the MCP tool list) now says which version added each component,
  field and command, and marks with "Not released yet" what is only on the main branch, so you can tell what your
  installed FactorIA has.
- Editing an ASCII level no longer means counting characters: `scene.ascii_edit` changes the map file of a level with
  operations (fill a rectangle, replace a glyph, insert or delete columns, put a coin "2 tiles above the ground" of
  column 40), rewrites only the rows and rebuilds the level, and tells you where every object ended up.
- On Windows, deleting a folder that holds files with very long paths (a macOS export nests four folders) now deletes
  all of it: exporting again into the same folder, `fs.delete` and deleting a project from the editor no longer leave
  old files behind.

Smaller improvements

- The editor's Screenshot toast has a "Show in Finder" / "Show in Explorer" button (it names your file manager) that reveals
  the new PNG, and File > Open Screenshots Folder opens the hidden `.factoria/screenshots/` folder (creating it if needed).
  A toast with a button stays longer and does not vanish while the mouse is over it.
- `factoria validate` no longer warns that a hand-written scene or prefab is "not in the canonical layout": such a file is
  valid. The report has a new informational `notes` list (`note:` lines in the text, `notes` in `--json`, the
  `project.validate` result and the editor's Validation report) with ONE entry naming those files and the optional
  `factoria call scene.format`. `scene.format {check, strict}` is still the CI gate.
- On Windows `factoria` now prints LF line endings like on macOS and Linux, so a doc or a JSON answer saved with `>`
  has no carriage returns.
- A Linux game named "game" now exports with the executable `game-bin`, so it no longer clashes with the `game` data
  folder next to it.

## 0.1.6

Menus and on-screen interface

- New interface pieces for your game: buttons, toggles, sliders, text fields, scrolling lists and panels with
  stretchable backgrounds, laid out in rows, columns or grids. Players use them with the mouse, the keyboard or a
  gamepad.
- Scripts can switch to full screen, change the window size, vsync and frame-rate cap, let players remap the controls,
  show the right button names for their gamepad, take typed text, and show or hide the cursor.
- A menus guide your AI follows to build a main menu, options, a pause menu, credits and a loading screen when your game
  needs them. New projects still start empty.
- Pausing really pauses now: physics, particles and animations stop too, while a pause menu keeps working.

Art, sound and music made by AI

- Your AI can generate images, sprite sheets, sound effects, music, voices and 3D models with the providers you set up
  (OpenAI, ElevenLabs, Meshy), keeping one style and colour palette across a game.
- Every generated or imported file remembers where it came from, and exports include `AI_CONTENT_DISCLOSURE.md` with
  the answers Steam asks about AI-generated content.
- Import Aseprite, Photoshop (PSD), OBJ and FBX files (FBX needs Blender or FBX2glTF installed), and cut sprite sheets
  into frames automatically.
- Lighter games: textures are compressed for each platform and packed into atlases, long music streams instead of
  loading whole into memory, and sounds can be evened out to the same loudness.
- `factoria validate` warns about images that are too big, sounds that clip or are too quiet, and games over a store's
  size limit.

Native plugins

- A game can bring its own native code as a plugin (C or C++ on desktop, Java or Kotlin on Android, libraries on iOS)
  without changing the engine. Plugins can live outside the game's folder, for SDKs you are not allowed to share.

## 0.1.5

- Exported Windows games open without a black console window, and the `.exe` carries your game's name and version
  (Properties in File Explorer shows them).
- Every run of a game writes a `log.txt` in the game's save folder, so a player can send it to you when something goes
  wrong.
- Exporting no longer fails on Windows when the output folder is deep enough to make paths longer than 260 characters.
- When a text uses characters its font does not have (Chinese, Japanese or Korean with the default font, for example),
  the log says which characters are missing and which font has them, instead of leaving the text blank without a word.
- When a command fails, your AI assistant always gets an error it can read and act on.

## 0.1.4

- Android: export your game as an APK to test or an AAB for Google Play, signed with your own key, with its icon.
- New Export window in the editor, with a button per platform and the settings each one needs (name, version, icons).
  What an export still lacks (Android SDK, players for another system) is installed in one click, or with
  `factoria setup` from a terminal.
- macOS: FactorIA is signed and notarized by Apple, so it opens without a security warning.
- iPhone, iPad and Apple Silicon Macs: touches and clicks land where they should, and games run on real devices.
- Android: a game you leave and open again starts correctly.
- The editor's title shows the FactorIA version and the open project.
- Exporting again only replaces a folder an earlier export made, never a folder of yours.
- Scripts: a warning when a method looks like a misspelled event name (for example `onUpdat`), which would otherwise
  never be called.
- License: FactorIA is MIT and the templates are MIT-0, so your game's code is yours to license as you like. Exported
  games include the license notices they need (`FACTORIA_NOTICES.txt`).

## 0.1.3

- Windows installer: installs for your user without an administrator prompt, adds FactorIA to the Start menu and
  makes `factoria` work in any terminal.
- Linux: a single-file AppImage, besides the `.tar.gz`. macOS: one download for Apple Silicon and Intel.
- Android and iOS export work straight from the download: you no longer need the engine's source code.
- Gamepads: hundreds more models are recognised on Linux, and on Android an unplugged pad frees its slot.
- 3D physics: balls roll and spin naturally when hit off-centre, resting bodies sleep and wake like in 2D, and fast
  objects no longer pass through walls.

## 0.1.2

- Editor: fixes in the AI chat, and projects can be deleted from the project list.
- Destroying an object also removes its physics body.
- Your AI assistant can export the game by itself.
- Screenshots taken by tests always show a complete, up-to-date frame.

## 0.1.1

- Editor: Ctrl+C and Ctrl+V work.

## 0.1.0

The first release of FactorIA, a 2D and 3D game engine made for an AI to build your game.

- Games are plain text (scenes in JSON, logic in JavaScript), so an AI can read and change every part of them, check
  its work and run tests.
- The editor is built around an AI chat: send pictures as references, keep several chats with their history, see how
  much of your plan you have used, and choose the model for each AI role.
- Templates to start from: a 2D platformer, an empty 2D game and an empty 3D game.
- 2D and 3D physics, gamepads, and play sessions that can be replayed exactly, with a report your AI can read.
- Downloads for Windows, macOS and Linux. The editor offers each new version and updates itself when you say so.
