# Your first game with an AI

You describe, the AI builds, you play and say what to change. This guide takes you through one session in the editor:
you start from the platformer template, change it in a few rounds with real requests, and learn the habits that keep it
under control: test it, look at it, read what the AI says it is missing, and take back a change you do not like.

You need FactorIA installed, `factoria` on your PATH, and an AI connected: the sections "Requirements and installation", "Create your first game"
and "Connect an AI" of [GETTING_STARTED.md](GETTING_STARTED.md). Nothing here repeats them. The AI's answers are different
every time, so this guide never quotes one: it tells you what to ask, what to do while it works and what to look for
afterwards. A round takes a few minutes; what it costs is in [Keeping the cost down](#keeping-the-cost-down).

## 1. Start from a template and open the editor

```bash
factoria new my-platformer --template 2d-platformer
factoria editor my-platformer
```

The first command makes the folder (what is inside is in GETTING_STARTED), the second opens the editor on it. You should
see a window with the game on the left (the **Viewport**: a sky blue level with grass, a red player and yellow
coins) and the **AI Assistant** panel at the right. Under the viewport there are the tabs **Console**, **Engine Feedback**
and **Audio**. Along the top: the buttons Play, Pause, Step, Stop, Save, Reload, Validate, Screenshot, Export, Undo and
Redo.

Press **Play**. The game runs in the viewport: A and D (or the arrows) move, Space or W jump, and touching a coin counts it
at the top right. Press **Stop** to come back to editing. Play never changes your project: Stop puts the scene back as it
was.

Before the first round, take a safety net. The editor edits files in your folder, and (as round 6 explains) the
undo button does not cover everything the AI can change. If you have [git](https://git-scm.com) installed, in a terminal in
`my-platformer`:

```bash
git init
git add -A
git commit -m "Platformer template"
```

If you do not use git, copy the folder before each round. Either way, you will be able to go back.

If the AI panel says **No AI provider is configured**, the editor cannot find a key or a signed-in Claude Code or Codex:
GETTING_STARTED, "Connect an AI", fixes that, and **Re-detect** looks again.

## 2. How to talk to it (and the same thing from a terminal)

In the AI Assistant panel, click the box at the bottom ("Ask the assistant..."), type, and press **Enter** to send
(**Ctrl+Enter** makes a new line). **Run** does the same. While it works you see its steps in the panel and the viewport
changes as it edits; **Stop** (in the panel) cancels it. The game must be stopped to send a message: while it runs the box
says "The game is running: press Stop (F5) to talk to the assistant."

Everything the panel does is also available outside the editor. If you prefer to work from a terminal, open Claude Code
or Codex in the game folder and ask the same things: `factoria new` already wrote the `.mcp.json` (Claude Code) and the
GETTING_STARTED "Connect an AI" section says how to add the server to Codex. The tools are the same, but you lose the
live viewport and the Undo button, so this guide follows the editor.

## 3. Round 1: a change you can see

Type:

> Make the player run a bit faster and jump higher. Tell me which values you changed.

What to look for:

- The answer names a script or a scene file (`scripts/player.js`: `speed`, `jumpSpeed`) and the old and new values.
  If it does not name anything, ask: "Which file did you change?"
- The AI usually runs `factoria validate` and a test by itself and says so. If it does not mention it, you do the check
  in a moment.

Press **Play** and try the jump. It is higher? It can be too high now: that is normal, the numbers are a guess. Press
**Stop** and say: "A little lower, the highest platform should still be reachable but not by a lot." A change of
feel takes two or three small requests, not one big one.

Press **Save** (or Ctrl+S) when you like the scene. The AI writes scripts and other files to disk at once, but a change
to the scene lives in the editor until you save it.

Commit it, so the next round has a clean starting point: `git add -A` and `git commit -m "Faster, higher"`.

## 4. Round 2: something new

Ask for one thing at a time, with the effect you want to see. Type:

> Add two enemies that walk back and forth on the platforms. If the player touches one, the level restarts.

Watch: new shapes appear in the viewport as it edits, and a new script (probably `scripts/patrol.js`) appears
in the project folder. When it says it is done, press **Play** and walk into one.

What to look for when you play:

- The enemies stand on the ground and turn at the edges instead of walking off the map.
- The restart works every time, and the coin count starts again from zero.
- Look at the **Console** tab: a red line there is an error from a script. Copy it into the next message ("The Console
  says: ..., fix it"): errors from the engine say file, line and what to do, which is exactly what the AI needs.

If something is wrong, describe what you saw, not what to code: "The second enemy falls through the floor" is better than
"change the collider". If it keeps failing, see round 6.

## 5. Round 3: the game gets an end

Stop the game and type:

> When the player has collected every coin, show "You win!" in the middle of the screen and stop the player from moving.

This one touches the scene (a new text) and a script, so you will see the viewport change before you play. Play to the
last coin. What to look for: the message appears only after the last coin (not at the first), and the player really stops.
Save the scene, commit.

## 6. Round 4: make it prove itself (a test)

A test is a small script that plays the game without a window, in a fraction of a second, and says whether something
still works. Without tests, every new round can break an old one silently. Ask:

> Add a test for the win message: collecting every coin must show "You win!". Then run all the tests and tell me the result.

What to look for:

- A new file in `tests/` (`something.test.js`) and, in the answer, a count like "N passed, 0 failed".
- You can run the same yourself, in a terminal in the game folder: `factoria test`. The editor's own **Validate**
  button runs `factoria validate` (scenes, scripts, assets) and shows its result in a window.
- A test the AI writes is a claim, not a proof. Read the test name: does it say what you asked? If it passes at once on
  something you know was broken a minute ago, ask: "Show me the test failing first: break the win condition and run it."

## 7. Round 5: look at it

The AI can take screenshots and see them. You can too: press **Screenshot** in the toolbar and the editor saves the game
view as `.factoria/screenshots/editor_<frame>.png` in your game folder, and a note tells you the path. Open it in any
image viewer. For the AI, type:

> Take a screenshot of the level and tell me if anything looks wrong: overlapping things, text cut off, things off screen.

Or attach your own picture: press **Attach image...** (or drop a PNG on the window, or paste with Ctrl+V) and write
"This is what I see; the coin counter is hard to read. Fix it." A picture of the problem is worth more than a paragraph.
The AI's honest answer may be "it looks fine": check that against the real picture.

For a lasting record of what you saw, the **F9** key while the game runs marks a problem: the game pauses on that frame,
you type a one-line note and press Enter, and **Attach last play session** gives the AI the note, a screenshot of that
exact frame and the errors. That is the fastest way to say "here, this, just now".

## 8. Round 6: when something goes wrong

Ask for something ambitious on purpose:

> Add a second level with moving platforms and a door that opens when all coins are collected.

Bigger requests are where the AI goes wrong, and you now know how to go back. In order of the cheapest first:

1. **Undo** in the toolbar (Ctrl+Z; Redo is Ctrl+Y). It takes back the scene changes the AI made, one step at a time, and
   the viewport shows it at once. The AI makes many small changes, so one request is several steps: keep pressing it. It
   works only in edit mode (not while the game plays) and does not take back scripts, test files or any other file: they
   are on disk, outside what Undo knows.
2. **Revert** under the AI's message "This run changed N files" (or Edit > Revert Last AI Run). It takes back the WHOLE
   run: scripts, tests and other files as well as the scene, in one click after a confirmation. Changed your mind? **Undo
   revert** brings the run back. The editor takes the checkpoint by itself before each run; nothing to set up.
3. **Reload** in the toolbar: throws away the unsaved changes of the scene and reads it from disk (the editor asks
   "Discard unsaved changes and reload the scene from disk?"). If you saved after the AI's change, the scene on disk
   already has it.
4. **Git**, the long-term history and everything older than the last runs. In the game folder:

```bash
git status                 # which files changed since your last commit
git diff scenes/main.scene.json   # what changed in one of them
git restore .              # throw away ALL edits of tracked files since the last commit
git clean -n               # lists new files the AI created; -f deletes them
```

   `git restore .` and `git clean -f` cannot be undone: look at `git status` first. After restoring files, press
   **Reload** in the editor so it reads them again. If you only want to drop one file, `git restore scripts/patrol.js`.
   Because you committed after each good round, you lose at most the round that went wrong.
5. **Ask the AI to undo it**: "That broke the game. Go back to how it was before the second level and keep only the door."
   Works for small things, and the AI can see the diff; but it is not a guarantee, so keep the commits.

## 9. Read what the engine was missing

While it builds, the AI notes in the game's **ENGINE_FEEDBACK.json** what it could not do with the engine or had to work
around (see [ENGINE_FEEDBACK.md](ENGINE_FEEDBACK.md) and "ENGINE_FEEDBACK.json in plain words" in GETTING_STARTED). Open the
**Engine Feedback** tab under the viewport, or open the file itself in the game folder: each entry has a `title`, what was
`missing`, the `workaround` it used and a `suggestion`. If the list is empty, the AI found nothing missing, which is a good
sign; if the game did something odd, an entry often explains why ("no way to do X: faked with Y"). Entries are for the
engine's makers: nothing is sent anywhere unless you send it.

## Tips for good requests

- **One change per request**, and say what you will see: "an enemy that patrols between x = 300 and x = 700 and turns at the
  edge" beats "make the game harder".
- **Say what must stay as it is**: "Do not change the controls or the level layout."
- **Give numbers** when you have them (speeds, sizes, seconds, colors as words). "A bit" is a guess; "20% faster" is not.
- **Ask it to say what it did**: "Tell me which files you changed." You review a list instead of a project.
- **Play after every round**, before asking for the next one: a bug found now costs one message; found five rounds later it
  costs five.
- **Name the file or the thing**: click an entity in the viewport (it is outlined) and say "make this one bigger": the editor
  tells the AI what is selected.
- **Ask for a plan first** when a request is big: "How would you do a second level? Do not change anything yet." Then say "Go."
- **When it is stuck**, do not repeat the same words. Say what you saw, attach a picture, or start a new chat with the
  **+** tab and a short summary of the state.

## Keeping the cost down

Every message re-reads part of the conversation, so long chats cost more per message. Start a **new chat** (**+**) for each
new feature, keep requests small and focused, and pick cheaper models for small work. [AI_COSTS.md](AI_COSTS.md) explains
what costs what and how to set limits (**Roles...** in the panel, and `maxTurns` / `maxCostUsd` in `~/.factoria/ai.json`).

## Where to go from here

You can now: make a change, play it, test it, look at it, undo it and read what the engine lacks. The same loop builds a
whole game. Next:

- [MAKE_BY_HAND.md](MAKE_BY_HAND.md): write a small game yourself, to understand what the AI is doing for you.
- [FINISHING.md](FINISHING.md): menus, options, saves, languages, accessibility: the things a store expects, in order.
- [PUBLISHING.md](PUBLISHING.md): what to do, store by store, to put the game on sale.
- [EDITOR.md](EDITOR.md): everything the editor does, and [AI_PROVIDERS.md](AI_PROVIDERS.md): the AI roles and models.
