Part of [EDITOR.md](../EDITOR.md): The AI Assistant panel and the Sharing feedback window.

# Editor: assistant

## AI Assistant

The panel holds several conversations as **tabs**: **+** opens an empty chat, the **x** on a tab closes it (the chat stays
in History), and the title is the first message ("New chat" until then). Each tab has its own transcript, input, usage and
attachments; a message in a tab continues that tab's conversation (see `docs/AI_PROVIDERS.md`). Several chats can run at the
same time, up to `limits.maxConcurrentRuns` (default 3, `ai.json`; `docs/AI_COSTS.md`): each has its own agent, live progress,
usage, **Stop** and Revert point (see "Several chats at once" below). A tab with a run shows a `*` before its title. Run is
disabled in a chat that is already running, and in the others once the limit is reached (hover it to see why). **History**
lists the saved chats, newest first; click one to reopen it as a tab (the next message resumes it) or Delete it from the list.

The transcript follows new output only while it is scrolled to the bottom: scroll up to read and it stays where you are
while the agent keeps working, with a **Jump to latest** button in its corner that goes back to the bottom (and following
starts again, as it does when you scroll down yourself or send a message). The message box is three lines high; drag the
grip just above it to make it taller (it grows upwards) or shorter, and double-click the grip to go back to three lines.
The height is kept with the layout.

- **Roles:** your messages always go to the orchestrator role, which answers, plans and hands implementation work to
  the worker role, small mechanical edits to the fast role, the art to the artist role and the sound to the audio role
  by itself. The `artCritic` and `reviewer` roles never run unless you ask (see **Reviews** below). **AI > Roles...**
  (the **Roles** tab of the AI settings window) picks the provider, model and effort of each of the seven roles, listed with readable names in three
  groups (Orchestration and code: Orchestrator, Worker, Fast; Art and audio: Artist, Audio; Critics and reviewers: Art
  critic, Reviewer; hover **AI > Roles...** to see the current ones). Each role has an **Enabled** checkbox: untick one you do
  not want to use and the orchestrator does that work itself (nothing is delegated to it; for the Art critic and the
  Reviewer, the review buttons still work but run on the orchestrator's model). The orchestrator's box is ticked and cannot
  be changed. Save writes them into `ai.json`
  and the next message uses them (see `docs/AI_PROVIDERS.md`, Roles). The **Model** column is a dropdown of the models
  the provider really offers, fetched when the project opens; **Refresh models** asks again (new releases show up), and
  **Other...** types a name that is not listed (see `docs/AI_PROVIDERS.md`, Choosing a model). **Revert** drops the
  changes made since the last Save. **AI > Roles...** is disabled until `ai.json` has been read. Its **Context** column caps how much of the
  conversation a session keeps (full, or 100k to 800k): past it the earlier part is summarized, so each message costs
  less. It works with Claude Code and the Anthropic API.
- **AI > AI Settings...** (the **AI** menu of the menu bar, next to File, Edit, View and Help; on macOS also **FactorIA > Settings...**, Cmd+,; there is no button for it in
  the panel) opens a window with four tabs. **Roles** (the first) is the role table above, and **AI > Roles...** opens
  the window on it. The **External tools** tab lists the MCP servers the AI may use (a service such as Scenario): a form
  to add one (name, address or program, key), a **Test** button that connects and lists its tools, **Paste JSON** for a
  `.mcp.json` snippet from Claude Code, and **Remove**; **Save** keeps every other key of `ai.json` (see `docs/AI_PROVIDERS.md`,
  "External tools (MCP servers)"). The **Extensions** tab lists the plugins, skill folders and hooks the AI agents load, with
  on/off per role, **Trust this project** for a project's programs, and a **Hooks** section at its end: every saved hook
  handler (entry, event, matcher, type, command or module) with where it runs (every provider, the engine's own events for every caller,
  or Claude Code only), and the **Recent runs** of this editor (time, event, what it matched, handler, result `ok` / `block` /
  `failed` in red, milliseconds; the tooltip has the error, reason, output and exit code) with a **Clear** button
  (`docs/HOOKS.md`). The **Assets** tab is for what the AI makes besides
  code and where it finds it. **Asset generation** picks, for each kind (Image, Sound, Music, Voice, 3D model), the provider
  that makes it (only providers that can make that kind, or **None**, which leaves it to the procedural commands), the model
  and, for Voice, the voice id, with a status per row (key found, or what is missing); a masked box stores an API key in your
  `ai.json` (your own file outside any project; an environment variable is safer and the window names it), and
  `asset-command` takes a program and its arguments. **Asset sources** lists the websites the AI should look at for images
  and textures, 3D models, audio, fonts and other assets (a domain or an address, and an optional note), and **Use only these
  sites** forbids searching anywhere else (enforced for Claude Code; for other providers it is an instruction). **Save**
  rewrites only those parts of `ai.json` and the next message uses them (see `docs/AI_PROVIDERS.md`, "The AI settings
  window" and "Asset sources"). The **Agents** tab sets the permission mode of Claude Code and Codex (a combo and one line per value
  on what it allows; a dangerous mode asks first; docs/AI_PROVIDERS.md, "Permission mode"). Section D2 of the autotest covers it.
  **With a project open** the window is titled "AI settings - This project: <name>" and edits that project's own settings,
  `<project>/.factoria/ai/settings.json`, instead of `ai.json`; without a project it says "Your defaults" and edits `ai.json`.
  The Roles tab has a **From** column and the Assets tab one per row and category: **This project**, **Your defaults** or
  **Built in**. **Reset** on a row that says This project takes that value out of the project's file, **Reset tab to my defaults**
  does it for the whole tab, and **Save as my defaults** writes the values you see to your `ai.json` (every project starts from
  them; the project's file keeps only what still differs). **Save** writes only what differs from your defaults into the project's
  file and the next message uses it. A file that came with a copied project and is not accepted yet shows an orange box at the top
  of the window: what it would change, **Accept**, **Ignore** (work with your settings; **Review it** brings the box back) and
  **Delete the file** (it asks first and forgets the acceptance); Save and Reset wait while the box is shown, and a Save after Ignore asks
  before it replaces the file and keeps it as `.factoria/ai/settings.replaced.json`. A file that cannot be accepted shows its error and no Accept. The
  External tools, Extensions and Token savers parts stay your own (`ai.json`) and say so. Switching project reloads what the window
  shows. On a small window the rows scroll sideways and the buttons wrap onto the next line, and the orange box scrolls inside the window
  instead of pushing the tabs off it. When `ai.json` or the project's file changes behind the window (an AI's `ai.settings.set`, another
  program) or after Accept, the window shows the new values and keeps the rows you had changed and not saved.
  (`docs/AI_PROVIDERS.md`, "This project's settings in the window")
  The **Extensions** tab ends with a **Skills** table: one row per skill the AIs can read (FactorIA's own, yours in
  `~/.factoria/skills` and the project's `skills/`), with an On box, where it comes from, what it is for, one box per role and a
  status. Switching a box adds a skill entry (`docs/SKILLS.md`) and **Save** writes it; a project skill with the name of an
  engine skill shows the engine one as `Replaced`.
- **Reviews:** at the top of the panel, above the chat tabs (they are not about one chat), **Review:** has an **Art critique** and a **Game review**
  button (and **Reviews...**, below), then a **Reviewers** count (1 to 5 reviewers, each with a different point of view,
  one after another) and an optional focus ("the shop screen"); a narrow panel moves the count and focus to a line of their
  own. Pressing
  one opens a confirmation (what runs, how many reviewers, the role's model, the focus); **Start** starts read-only
  agents that look at and play the game (they read `REVIEW.md` first) and give an opinion with a score from 0 to 10 and
  sub-scores. Each reviewer works in a chat tab of its own, titled "Art critique" or "Game review", where
  you see what it does. They cost tokens, so nothing starts them but you: the orchestrator cannot. A reviewer is one more run: it counts
  toward the limit of chats at once (`limits.maxConcurrentRuns`), and the orchestrator's chats keep working while it does. The
  buttons are disabled while the game runs (the reviewers start it themselves) or that limit is reached. Stop in the review's
  tab ends the review and the reviewers after it. When a review is ready, the **AI
  reviews** window opens (also from **Reviews...**) with every saved review of the project, newest first, with its score,
  persona and game version, and the text of the selected one. **Send to orchestrator** posts that report as your message
  into the active orchestrator chat (a new one when the active tab is a review's own) so it plans the fixes and delegates
  them; **Copy** puts the text on the clipboard. Nothing is sent unless you press it. The reviews are files in
  `.factoria/ai/reviews/` (`docs/AI_PROVIDERS.md`, Reviews).
- **Pictures:** drop image files (png, jpg, jpeg, gif, webp) on the window, press Ctrl+V in the input with a picture on the
  clipboard, or press **Attach image...**. Pending pictures show above the input (remove one with its x); sent ones show
  in the transcript. Copies live in `.factoria/ai/attachments/`; other file types are refused with a message saying why.
  A big picture (a 4K screenshot) is scaled down to 1568 px on its long side, what the model looks at anyway, so it costs
  fewer tokens and stays under the API's 5 MB limit.
- **Usage:** the plan limits (Session (5h) and Week, with the reset time) belong to the provider, not to a chat, so they
  sit at the top of the panel above the chat tabs, with the provider problems ("No AI provider is configured", an unreadable
  `ai.json`) and the review row. Under the tabs, above the transcript, are the chat's own Context, Tokens and **API cost est.**
  Hover a line for details. The cost is what the same tokens would cost on the provider's pay-per-token API; with a
  subscription (Claude Code / Codex sign-in) none of it is charged on top of the plan, and the line says "(not billed on a
  subscription)": only the plan limits matter there. Tokens and Cost move while the agent works: every model call
  adds its usage (the worker's too, each agent counted on its own and summed) and the cost is the engine's running estimate
  from its price table until the CLI reports its own total, which replaces it when the agent finishes. Claude Code reports
  a message's output tokens early, so "out" can lag until the end. The plan limits are the last ones the provider reported in
  this run of the editor; Claude Code reports them once per message (after its first model call), so they do not move while
  it works (the tooltip says "As of HH:MM"). `limits.maxCostUsd` / `limits.maxTotalTokens` see the live numbers: a CLI agent
  is stopped as soon as it crosses them.
- **Selection:** the entity selected in the viewport (click it) is named to the AI in each message.
- **Claude Code** runs its own loop in a child process, but its tools are the editor's: the editor serves MCP on a loopback
  port (`http://127.0.0.1:<port>/mcp/<token>`) and the MCP config it writes for the CLI points there. Its tool calls run on
  the editor's main thread like an API provider's, so its edits show in the viewport as it works, each is a Ctrl+Z step,
  and Play waits for it. Codex still uses a `factoria mcp` process of its own (see `docs/AI_PROVIDERS.md`, CLI agents in
  the editor).
- **A run that is going shows its pulse** under the transcript: `running 4 min | last activity 12 s ago | <last thing it
  did>`. A CLI agent's sub-agent (the orchestrator's `ai_run`) streams into the chat as it works, each step indented under
  the `ai_run` call, so a long delegation is not a silent wait.
- **"The agent may be stuck":** after `limits.stuckAfterSeconds` (default 180, `ai.json`, 0 turns it off; `docs/AI_COSTS.md`)
  without any event from the agent, a warning appears with two buttons. **Stop** cancels the run and a worker it started.
  **Check activity** looks, without touching anything, at the agent's CLI process and everything below it (is it alive, CPU
  used over the last seconds, child processes such as a shell command), the tool call it waits for and for how long, the
  files that changed in the project in the last 2 minutes, and its last event. It writes a chat line starting with
  "Activity check:" with a verdict (a plain `Still working: ...` or `Looks stuck: ...`, followed by the evidence) and
  keeps the warning quiet for another `stuckAfterSeconds`. A model thinking for a long time looks like a stuck agent
  (alive, idle, no tool), so the verdict says to press Stop if you do not want to wait. It reads the CPU and process
  list through the operating system (`/proc` on Linux, `libproc` on macOS, the toolhelp snapshot on Windows); where a
  figure is not available the check skips it and still reports the rest. An API provider has no process, so the verdict
  there covers only the tool call, the files and the last event. The panel also stops a run by itself, with a message, when
  the CLI process has disappeared for 10 seconds while the run goes on. "Disappeared" is confirmed with a direct question to
  the operating system (is that pid still running) and only counts while the run has produced no event for 10 seconds: a
  process the list does not show, or a run that still reports, is never stopped for it.
- **Why a run was cancelled:** every cancel records its cause. The session transcript's `end` event
  (`.factoria/ai/sessions/*.jsonl`) has `"cause"` (`user_stop` the Stop button, `stuck_stop` the Stop of the stuck warning,
  `watchdog_process_gone`, `activity_check_process_gone`, `project_closed`, `editor_closing`, `editor_restart`, `run_ended`)
  and an `error` such as `cancelled: the user pressed Stop`. The chat shows the same text, and the `ai_run` call of an
  orchestrator whose worker was cancelled fails with it, so neither the user nor the orchestrator has to guess.
- **Worker still running:** if the orchestrator's turn ends while an `ai_run` is still going (Claude Code cut the call off, for
  example), the panel says "Worker still running: the orchestrator's turn ended, its report will continue the chat" and keeps
  showing the worker's live steps. Play stays blocked. When the worker finishes, its report goes into the chat and the
  editor sends it to the orchestrator as a new message of the same conversation (Claude Code `--resume`), once. **Stop**
  stops the orchestrator and the worker, and sends no continuation.
- **Paid assets ask first.** When the assistant asks a provider for a picture, sound, voice or model estimated above
  `limits.askAboveUsd` (default $0.50; the estimates and limits are in [AI_COSTS.md](../AI_COSTS.md#asset-generation), AI Settings >
  Assets > Spending limits), the call waits and a card appears under that chat's messages: what will be made, how many, with
  which provider, the estimate (an estimate from the provider's price list, not an invoice) and when the prices were looked up.
  **Approve** lets this call go, **Approve all for this run** lets the rest of this chat's run go without asking (the spending
  limits still hold), **Cancel** declines it and the assistant carries on without it. The editor stays usable while the card
  waits; the chat's tab shows `?` and a card in a chat that is not in front raises a toast; the "may be stuck" warning does
  not appear while a card waits, and the run's **Stop** ends the wait (the assistant is told the run was stopped, not that you said
  no). Small calls that were not asked about count together: the card of the call that takes them over the limit says how much came
  before it, and **Approve** starts that count again. The buttons are at the top of the card so that they stay visible in a
  narrow panel; the text under them scrolls. The assistant's own `approved` argument is ignored here. The card is only for runs this editor started (its chats, the
  CLI agents it launches, the Image panel's popup); a terminal command or an MCP client with its own `factoria mcp` gets a
  `needsApproval` answer instead. A refund of a failed call that could not be written is a warning in the Console and in the
  result of the next paid call that goes ahead (AI_COSTS.md, "The day total"). What you answered is written into the chat. While a run
  has spent something, its status line ends with `assets ~$X (estimate)`. The `fake` provider and your own programs never ask.
  A Claude Code, Codex or other MCP client that waits for the card can hit its own tool-call timeout (often 60 to 120 seconds); if the
  call comes back abandoned the card stays, and approving it late still makes the picture, but the agent is not told: answer
  soon, or ask the agent to try again.
- Chats are saved in `.factoria/ai/chats/` after each answer and when a tab closes; the open tabs come back when the project opens.

### Several chats at once

Each chat that runs has its own agent thread (and, for Claude Code, its own MCP endpoint), so its transcript, status line,
stuck warning, **Check activity**, usage and **Stop** are the chat's alone: Stop in one tab ends that run and its worker and
leaves the other chats going. A worker that outlives its orchestrator's turn (see above) is also per chat. The commands of all
the runs share the editor's main thread, one after another, and the Undo history gets each command's step in the order they ran.
`limits.maxCostUsd` and `limits.maxTotalTokens` apply to each run on its own; the plan limits (Session, Week) are shared by all
chats, since they are the provider's.

- **Play and the scene:** while any run is going Play waits, and the note names the chats working ("The assistant is changing
  the scene (chat "Add a coin" and "Fix the menu")").
- **The same file in two chats:** when two chats that run at the same time change the same project file (a script, or the open
  scene), both transcripts get an amber note: `Chat "Fix the menu" is running at the same time and also changed
  scripts/menu.js. ...`. The editor sees a file changed through the editor's commands, through Claude Code's own Write / Edit
  tools, and, when a run ends, through the checkpoint (a file a shell command wrote is credited to the run that has no other
  claim on it). Each pair of runs is told once per file. Two runs writing the same
  file is not prevented: the later write wins, and the note is there so you check the result.
- **Revert with several chats:** each run has its own checkpoint, taken when it started. Reverting a run while no other chat's
  run overlapped it works as before (the whole checkpoint goes back). If another chat's run was going at the same time (or ran
  after it), only the files this run changed go back, and the dialog lists the files both runs changed, and names the chats
  still running. **Revert, keep their changes** puts back the files only this run changed and leaves the listed ones, and
  the open scene when the other chat edited it too, as they are now; **Revert including those files** also takes them back to
  how they were before this run, losing the other chat's changes to them. Undo revert of a revert that kept someone's files
  restores only the files that revert wrote. A run saved by an older editor has no start time and is treated as if it ran alone.
  Revert stays disabled in a chat that is running.

### Revert an AI run

Before every run the editor takes a **checkpoint**: a copy of every file of the project (scripts, tests, scenes, assets;
not folders starting with `.`, `node_modules` or a top-level `build/`) plus the open scene as it is in memory. When the
run ends and it changed something, the transcript shows **"This run changed N files"** with a **Revert** button (and the
list of files, and whether the open scene changed). Revert asks for confirmation, then puts every file back, deletes the
files the run created, and puts the scene back as ONE Undo step (Ctrl+Z brings the run's scene back). Scripts are
reloaded. The item then reads "Reverted ..." with an **Undo revert** button, which restores the state the project had just
before the Revert (nothing is lost: Revert makes its own safety checkpoint first). **Edit > Revert Last AI Run** does the
same for the newest run. The button works after a restart too (the item is saved with the chat), and it is available only
in edit mode with no AI run in progress. The next message you send tells the AI that you reverted, so it reads the files
again instead of assuming its changes are still there. Revert covers files, not what lives outside the project folder.
It does not replace git: use git for long-term history.

Checkpoints live in `.factoria/checkpoints/` (each distinct file content is stored once; the newest 30 checkpoints are kept)
and use disk space, mostly for big assets. To clear them, delete that folder; the editor never needs it back. They are
never exported or bundled (folders starting with `.` are skipped), and the template `.gitignore` lists `.factoria/`. The same
engine is available as the commands `checkpoint.create`, `checkpoint.list`, `checkpoint.diff`, `checkpoint.read` and `checkpoint.restore`.
`checkpoint.read {id, path}` returns one file as it was at a checkpoint (text inline; a binary as base64, or any file into `out`)
without restoring anything, and `checkpoint.restore {id, paths:[...]}` puts back only the listed files, with the same safety checkpoint.

## Sharing feedback

The engine developers can read the gaps your game found in the engine (docs/ENGINE_FEEDBACK.md, "Sharing with the engine
developers"). Nothing leaves the computer until a person chooses, and only here or in the terminal (`factoria feedback
sharing`): no command, MCP tool or script can set the mode, so an AI cannot turn sharing on.

**The consent dialog.** While the mode is unset, the editor asks once: when you open a project that has feedback entries,
or when the first entry with a `share` text is written. It says in plain words what is sent (the sanitized share text,
category, severity, effort, who wrote it, whether it was reviewed, the engine version, the operating system and a random
installation id) and what never is (the game's name, files, paths, scene, entity and script names, your code and assets, the
entry's own text, your name). Under that, the next report exactly as it would leave this computer, built from the entries
that wait now (`feedback.share_preview`; nothing is sent by showing it). The buttons are **Always**, **Ask me each time** and
**Never**; a discreet **Decide later** closes it for this session and asks again the next time the editor starts. Once you
choose, it does not come back (change your mind in Feedback Settings). The dialog is not shown in a build without a feedback
server address, where there is nothing to send.

**Feedback Settings** (File > Feedback Settings...):

- **Mode** (titled **Default** while a project is open): Always, Ask me each time, Never. This is what every project follows
  unless it has its own choice.
- **This project: <name>** (only with a project open): **Follow default**, **Always**, **Ask me each time** or **Never** for this
  project alone, and a line that says which mode applies now and where it comes from. The choice is kept in your own
  `feedback-sharing.json`, keyed by the project folder's path, never inside the project (a copied or downloaded project does not inherit it and follows the
  default); moving the folder drops it back to the default. The four choices wrap onto more lines in a narrow window. Changing the
  project's choice acts on its waiting items: Ask puts queued ones back to waiting, Never drops them (entries marked skipped), and
  Follow default applies the default to them, except that it never answers yes for what waited (a note says so when the default is Always: those entries stay in Send feedback until you confirm them). After Never, a batch whose upload had already started finishes (the notice says so); nothing after it is sent. A default of Always or Never never touches a project that has its own choice. The Engine Feedback panel's "sharing:" label, the consent dialog,
  Send feedback, the outbox and the sending all use the project's mode. The outbox line says how many items are not sent because
  their project is Never. The consent dialog (shown while no mode is chosen at all) sets the default; ask mode's question is
  per project, because the waiting entries and the Review notification belong to the project's feedback file.
- **Installation id** and **Reset id**, which makes a new random one (the old reports stay with the old id). The settings, the outbox and
  the lock they share with the terminal and the MCP server never make the window wait: when another program is changing them, the
  action says so (a notification, or the row of Send feedback) and nothing is changed; try again a moment later.
- **GitHub (optional)**: **Sign in with GitHub** shows the code to type, the address and **Open in browser**; the window finishes by
  itself when you authorize (**Cancel** stops it), then shows your login and **Sign out**. Signing in only makes your reports
  count as verified; no GitHub permission is requested.
- **Outbox**: how many entries wait to be sent and how many wait for your answer, the next retry time and the last error of
  an entry that could not be sent, the last attempt, and **Send now**, which sends what is due without waiting for the
  retry time.

**Send feedback.** The **Send feedback** button of the Engine Feedback panel opens a window with every entry that would be sent:
open, not sent yet and not refused by the server (an entry sent before is listed again only when its `occurrences` went up, at
most 3 sends). Each row has a checkbox, checked by default, and the exact text that leaves the computer, with the names of your
game already cut out: the entry's `share` when an AI wrote one, otherwise a text made from the entry's title, what is missing and
suggestion. An entry too short to make a text from is listed unchecked and disabled, with the reason. You never write a share
text. **Send** stores the text in each checked entry, queues it and sends it at once; the rows then say *Sent*, why the server
refused one, or that it waits in the outbox for a retry. An unchecked entry is marked `skipped` and comes back unchecked the
next time. **Cancel** (or the window's X) sends and changes nothing.

When an AI provider is set up (docs/AI_PROVIDERS.md), each text that was not reviewed before is checked in the background while
the window is open (`ai.review_feedback` on the "fast" model, with the text of the row as the candidate): the row says
*checking with AI...*, then either *Checked by AI* (when the check rewrote the text in engine terms, the row shows the rewrite and
that is what is sent) or the reasons it did not pass, with the row unchecked. Send waits for the checks of the checked rows. With
no model set up there is no check and no message. Nothing is stored until you press Send.

The consent dialog (see above) comes first when no mode is chosen yet and you press Send feedback. With **Never** the button is
disabled: turn sharing on in File > Feedback Settings. In **Always** mode an entry that already has a `share` text (an AI wrote
it) is queued and sent as it is recorded, as before; entries without one wait for Send feedback. In **Ask me each time** mode,
when entries with a `share` text wait for your answer, a notification with a **Review** button opens this same window.

**Add feedback.** The **Add feedback** button opens a form: category, severity, title, what is missing, the workaround you used and,
optionally, a suggested engine change. **Add** checks the form, records the entry in `ENGINE_FEEDBACK.json`, selects it and closes
the form; **Cancel** (or the X) closes it and keeps nothing. There is no share text to write. When the engine already has what the
form says is missing ("No one-way platforms": `Collider2D.oneWay` exists), **Add** does not record it: the form stays open and says what
exists and where it is documented (docs/ENGINE_FEEDBACK.md, "The check before filing"). A bug report (it exists but does not work as
documented) and a request for an extra option on an existing component are recorded.

**The Engine Feedback panel.** The table is as tall as its rows need, up to two thirds of the panel, and scrolls inside when there are
more. It has a **share** column: *not sent*, *waiting* (queued or waiting for your answer), *sent*, *rejected* (hover for the reason:
the sanitizer, the server or the limits) and *skipped* (left out of a Send). The selected entry is shown read-only, with its share
state and the **status** box: changing it to anything but `open` moves the entry to the archive file.

**Rejected entries, closed entries, the entry window.**
- The engine rejects an open entry that says the engine lacks something it has when the project opens, and tells you with a
  notification; the entry is closed as `rejected` with the reason (what exists and where it is documented) and moves to the archive. The
  engine developers can reject a report you sent as well: the editor asks the server about every 30 minutes while sharing is on, and
  the entry closes as `rejected` with their reason and a *declined* share state.
- The **closed** checkbox adds the archived entries to the table (the status filter does too when you pick a closed status). A closed
  entry that has a reason shows `*` after its status: hover for who decided (the engine, the engine developers, you) and why.
- Picking **rejected** in the status box of an entry asks for the reason first (a text box, up to 500 characters, OK disabled while it
  is empty); Cancel keeps the status. A person who reopens an entry that the engine rejected is not overridden: the engine never rejects it again.
- **Double-click a row** to open the entry in its own window: every field (also the ones the table does not show: workaround files,
  notes, reporter, the reason of a rejection, the share text and the server's answer), wrapped, scrolling when it is long. The window
  moves and resizes like any floating window, several can be open at once (one per entry), and each has the status box, **Copy**
  (the whole entry as JSON on the clipboard), **Delete** and **Close**. While an entry has a window, the strip under the table does not
  repeat these buttons.
- **Delete** asks "Delete this entry?" first and then removes it from the file or the archive for good (command `feedback.delete`).
  It is enabled for a closed entry and for an open one the engine developers declined; an open entry that nobody has answered is
  somebody's question and stays (hover the disabled button for why). Its id is not used again.
