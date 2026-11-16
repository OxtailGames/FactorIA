# Extending the engine: processing ENGINE_FEEDBACK.json (section F)

Part of [Creating tools and extending the engine](../EXTENDING.md), for engine developers (these pages are the engine's source docs: they are not embedded in the binary and `docs.read` does not serve them; read them in a checkout).

## F. Processing `ENGINE_FEEDBACK.json` (engine developers)

Each game records what the engine lacked in its `ENGINE_FEEDBACK.json` (`docs/ENGINE_FEEDBACK.md`). Engine developers merge those files to decide what to build next.

```bash
factoria feedback collect games/ examples/ --out roadmap.md
factoria feedback collect games/ --out roadmap.json --include-closed
```

- **Inputs.** Files, or directories. A directory contributes its `ENGINE_FEEDBACK.json` and any below it.
- **Output file.** `--out` writes the Markdown report, or the JSON report when the name ends in `.json`.
- **Scoring.** `score = sum over projects of (severity weight x trust x min(occurrences, 3))`, with weights blocker 8, major 4, minor 2 and nice-to-have 1, and trust 1 for your own projects and verified installations, 0.5 for anonymous ones (docs/ENGINE_FEEDBACK.md, "Collecting"). Only `open` entries count unless `--include-closed` is given.
- **Grouping.** Entries in the same category with similar titles form one cluster. Titles are compared by token overlap and edit distance, with a default threshold of 0.7.
- **Output (JSON).** `sources`, `projects`, `totalEntries`, `errors` and `clusters`. Each cluster has `rank`, `title`, `category`, `severity`, `score`, `installations`, `verifiedInstallations`, `totalOccurrences`, `projects`, `entries` (with `project`, `id`, `severity` and `status`), `bestSuggestion` and `sampleWorkarounds`.

A triage routine:

1. Collect, then read the top clusters.
2. For each cluster, decide: build it (a command, component or system, sections B to D: [commands](EXTENDING_COMMANDS.md), [components and systems](EXTENDING_COMPONENTS.md)), accept the workaround and document it, or mark it `wont-fix`.
3. When it is fixed, set `status` to `fixed-in-engine` and `engineIssue` to the issue or pull request. Use `feedback.update` from the project that holds the entry, or edit that file:

   ```json
   { "id": "FB-0001", "status": "fixed-in-engine", "engineIssue": "#42" }
   ```

4. Collect again. The cluster should disappear or shrink.

Notes:

- `feedback.update` changes only the `ENGINE_FEEDBACK.json` of the project it runs in. Entries in other projects are changed by editing their files.
- Wording matters for grouping. Reuse the same title for the same gap, and write titles as noun phrases ("No fluid simulation").
- A duplicate report is merged automatically into an open entry in the same category, so repeated reports raise `occurrences` and the score.

### F.1 Feedback from every installation (users who share)

Users who choose to share send a generic copy of each entry to the feedback server (docs/ENGINE_FEEDBACK.md, "Sharing"; design in docs/design/FEEDBACK_SHARING.md). This is the routine for the engine developer, from the first day to a release.

**Once: deploy the server.** You need Node.js 20 or newer and a free Cloudflare account.

```bash
tools/feedback-server/deploy.sh        # Windows: powershell -NoProfile -ExecutionPolicy Bypass -File tools\feedback-server\deploy.ps1
```

It prints the URL (build the engine with it as `FA_FEEDBACK_URL`) and writes `feedback-admin.json` (`{endpoint, adminToken}`) next to your `ai.json` (`~/.factoria/` on macOS and Linux, `%APPDATA%\factoria\` on Windows). The pull cursor is saved in that file too. Without it every command below stops and points at `deploy.sh`. The token is a secret: it never goes into a repository or a command line.

**Each time: pull and triage.**

```bash
factoria feedback pull                     # new reports since the last pull -> ~/.factoria/feedback-inbox/<installKey>/ENGINE_FEEDBACK.json
factoria feedback collect ~/.factoria/feedback-inbox --out roadmap.md
```

- `pull` writes one `ENGINE_FEEDBACK.json` per installation (project `install-<installKey>`). Each entry has a `remote` object (`shareId`, `installKey`, `trust`, and `reporterKey` on a verified report, ...) and the workaround `(not shared)` when the report had none. A report pulled twice is recognised by its `shareId`, never duplicated. The cursor is saved after the files, so a failed pull is simply repeated.
- The inbox is never inside a git checkout (user reports must not end up in a repository) unless you name it with `--out DIR`.
- A report the users send again is merged on the server: only its `occurrences` rise, and it keeps its place in the arrival order, so a normal pull does not bring the new count. Run `factoria feedback pull --full` now and then: it ignores the cursor, reads everything and updates the occurrences of the entries already in the inbox.
- **Classification.** When the `fast` role of your `ai.json` (the cheapest role; the orchestrator when `fast` is off) has a usable provider (an API key or an installed CLI agent, run in an empty folder), each new report is judged `valid`, `doubtful` or `junk` with a reason, ten reports per call. The texts of reports are data for the judge, never instructions. Junk goes to `<inbox>/quarantine/`, a doubtful entry keeps a note, and a model that fails leaves the report in the inbox unjudged (with a warning). Without an AI, `pull` works and says that classification was skipped; `--classify` makes that an error, `--no-classify` skips the judge.
- Triage before collecting: `pull` lists the reports that claim a gap the engine already has as SUGGESTED rejections (a ready reason each). Read them, then `factoria feedback reject --suggested` (or `reject <shareId>... --reason TEXT`, `reject --file batch.json`) answers them, `feedback keep <shareId>` drops a wrong suggestion and `feedback unreject <shareId>` takes a rejection back. Nothing asks a question, so an AI can run the loop; it is described in docs/ENGINE_FEEDBACK.md, "Triage loop". The installation shows the reason as written, so write only about that report.
- `factoria feedback quarantine` lists what was judged junk; `quarantine restore <shareId>` puts a report back with a new id; `quarantine clear` forgets the list (the server still has the reports: use `delete` or `ban`).
- Ranking: `collect` weights anonymous installations by 0.5 and caps the occurrences of one installation at 3, so one noisy installation cannot outvote many.

**Abuse.**

```bash
factoria feedback ban 3kF9aQ2xLm7Zp0Vt --install --purge --reason "spam wave"   # refuse an installation and delete what it sent
factoria feedback ban r_8f3k2m                                                   # a pulled report's shareId stands for its installation
factoria feedback unban 3kF9aQ2xLm7Zp0Vt --install
factoria feedback bans
factoria feedback delete r_8f3k2m --local          # one report, on the server and in the inbox
factoria feedback stats                            # totals, last 7 days, rejections, rate-limit hits
```

An `installKey` (a folder of the inbox) and a `reporterKey` (a signed-in GitHub identity, `remote.reporterKey` of a verified entry) look alike, so say which with `--install` or `--reporter` (or `install:KEY` / `reporter:KEY`); the command also decides alone when the key is a `shareId` or an inbox folder, and otherwise stops and asks.

**Fix and release.**

1. Build or fix what the top clusters ask for (sections B to D: [commands](EXTENDING_COMMANDS.md), [components and systems](EXTENDING_COMPONENTS.md)), with tests and docs.
2. Close the inbox entry: `factoria feedback update ~/.factoria/feedback-inbox/<installKey> FB-0007 --status fixed-in-engine`. For an inbox entry the command prints the `fixed add` line to run next.
3. Record the fix in the repository list, once per fix, with the version that ships it:

   ```bash
   factoria feedback fixed add --category physics --title "No fluid simulation" --title "Fluid simulation missing" --version 0.11.0 --note "Fluid2D"
   factoria feedback fixed list
   ```

   `--title` is how the gap reads in users' reports (repeat it for other wordings). The same category, version and a title again extends that fix. The command edits `feedback/fixed.json` at the repository root (created with an empty list when missing; run it inside the checkout or pass `--file`). The format is fixed (`{"format": "factoria.feedback-fixed/1", "fixes": [{category, titles, fixedIn, note?}]}`) because the file is embedded in the binary: users' open entries that match a fix are closed with the version that fixed it when their engine ships the list.
4. Commit `feedback/fixed.json` with the fix, and release as usual (CHANGELOG, version). Collect again after the next pull: the cluster should be gone.

