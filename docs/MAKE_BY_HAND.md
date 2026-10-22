# Make a small game by hand

In [Your first game with an AI](FIRST_GAME_WITH_AI.md) the AI wrote the files. Here you write them yourself, so you know
what it does for you and can read, fix and steer what it makes. The game is small: a blue square that you move with the
keyboard, four gems to collect, a score on screen, a "You win!" screen, one test, and then a copy of the game you can
send to a friend. It takes about 30 minutes, and every step ends with a command that checks it.

You need FactorIA installed and the first sections of [GETTING_STARTED.md](GETTING_STARTED.md) read (`factoria new`,
`factoria run`, `factoria validate`, `factoria test`). You need a text editor that saves plain files (Notepad, VS Code,
anything but a word processor). Paths are relative to the game's folder. This tutorial is the checked project
`tools/cli/tests/fixtures/gem-grab` of the FactorIA repository: ctest runs `factoria validate` and `factoria test` on it
and compares every file below with it, so if a block here does not work, it is a bug: please open an issue.

## What you will make

| Piece | File | What it is |
|---|---|---|
| The level | `scenes/main.scene.json` | A list of things (entities): camera, player, four gems, the score text. |
| Moving and collecting | `scripts/player.js` | JavaScript that runs on the player every frame. |
| The score | `scripts/score.js` | Counts gems, writes the text, opens the win screen at the last one. |
| The win screen | `scenes/win.scene.json`, `scripts/win.js` | A second scene with a message; Space goes back to the game. |
| The test | `tests/game.test.js` | Checks the three things above without opening a window. |

## 1. Start from an empty game

```bash
factoria new gem-grab --template 2d-empty
cd gem-grab
factoria validate
```

You should see `OK: 0 error(s), 0 warning(s)` (`2d-empty` is the default template, so `--template` is only there to be
clear). The folder has `factoria.json` (window size, the keys), `scenes/main.scene.json` with just a camera, empty
`scripts/` and `tests/` folders, and the files for AIs (`AGENTS.md`, `.mcp.json`) that you can ignore here.

`factoria.json` already has the keys we need under `input.actions`: `move_left`, `move_right`, `move_up`, `move_down`
(A, D, W, S or the arrows) and `action` (Space, mouse, touch). An *action* is a name for "something the player can
press": the code asks for `move_left`, never for the letter A, so you can change the keys later without touching code.
Do not change this file.

## 2. The player script

A script is a JavaScript class that extends `Behaviour`. The engine calls its `onStart` once and its `onUpdate` every
frame, and `onTriggerEnter` when the thing it is attached to overlaps a *trigger* (an area that detects but does not
push). Create `scripts/player.js`:

```js scripts/player.js
import { Behaviour, input } from "factoria";

export default class Player extends Behaviour {
  /** Speed in pixels per second. */
  speed = 300;

  onStart() {
    this.body = this.entity.get("RigidBody2D");
  }

  onUpdate(dt) {
    // vector() gives (x, y) from -1 to 1: A/D or the arrows left and right, W/S or up and down.
    const move = input.vector("move_left", "move_right", "move_down", "move_up");
    this.body.velocity.x = move.x * this.speed;
    this.body.velocity.y = move.y * this.speed;
  }

  onTriggerEnter(other) {
    if (other.hasTag("gem")) {
      other.destroy();
      this.world.emit("gem_collected", {});
    }
  }
}
```

What it says:

- `speed = 300` is a field. Fields are the settings of the script; a scene can override them with `Script.props`.
- `this.entity` is the thing the script is on (the player). `get("RigidBody2D")` returns its physics body, and
  writing to `velocity` moves it. The engine does the moving and the collisions.
- Pixels per second: 300 crosses a 1280 pixel wide window in about four seconds. The y axis points **up**.
- When the player overlaps something tagged `gem`, the gem is destroyed and the script *emits an event*,
  `gem_collected`. It does not count anything itself: whoever is interested listens. That is the next script.

Nothing to run yet: a script alone is not in the game until a scene uses it.

## 3. The score

Create `scripts/score.js`. It sits on the text that shows the score:

```js scripts/score.js
import { Behaviour, scene } from "factoria";

export default class Score extends Behaviour {
  gems = 0;

  onStart() {
    this.total = this.world.findByTag("gem").length;
    this.world.on("gem_collected", () => {
      this.gems += 1;
      this.entity.get("Text").text = `Gems: ${this.gems} / ${this.total}`;
      if (this.gems === this.total) scene.load("scenes/win.scene.json");
    });
  }
}
```

- `onStart` counts how many entities have the tag `gem`, so you can add or remove gems in the scene and the text
  stays right.
- `this.world.on("gem_collected", ...)` runs the function each time the player emits that event. It changes the
  `text` of its own `Text` component, which is all it takes to change what is on screen.
- At the last gem it loads another scene. `scene.load` happens at the end of the frame.

## 4. The win screen

A second scene with a message, and a script that restarts the game on Space. Create `scripts/win.js`:

```js scripts/win.js
import { Behaviour, input, scene } from "factoria";

export default class Win extends Behaviour {
  onUpdate(dt) {
    if (input.pressed("action")) scene.load("scenes/main.scene.json");
  }
}
```

And `scenes/win.scene.json`:

```json scenes/win.scene.json
{
  "format": "factoria.scene/1",
  "entities": [
    {
      "id": "camera",
      "name": "Main Camera",
      "components": {
        "Camera": { "projection": "orthographic", "clearColor": [0.08, 0.09, 0.14, 1], "primary": true }
      }
    },
    {
      "id": "win_text",
      "name": "Win text",
      "components": {
        "Text": { "text": "You win!\nPress Space to play again", "fontSize": 48, "align": "center", "pivot": [0.5, 0.5], "space": "screen", "anchor": [0.5, 0.5] },
        "Script": { "path": "scripts/win.js" }
      }
    }
  ]
}
```

A scene is a list of entities, and an entity is a bag of components: `Camera` makes it the view, `Text` draws words,
`Script` attaches your class. `"space": "screen"` pins the text to the window instead of the world, and `anchor`
`[0.5, 0.5]` is the middle of the window. A scene needs its own camera: without a primary camera the picture is black.

Check it. `--scene` starts the game on that scene instead of the main one:

```bash
factoria validate
factoria screenshot --scene scenes/win.scene.json --frames 5 --out win.png
```

`validate` should say `OK`, and `win.png` shows "You win!" with "Press Space to play again" under it, in the middle, white
on dark blue. If `validate` says something is wrong, read it: it names the file, the place inside it and how to fix it.
For example, a typo in a script path gives

```
error: scenes/win.scene.json#/entities/1/components/Script/path: Asset 'scripts/wim.js' (script) does not exist. (hint: Did you mean 'scripts/win.js'?)
```

and a method called `onUpdat` instead of `onUpdate` gives a warning with the same "did you mean": a misspelled hook is
never called, and this is the way to find it.

## 5. The level

Now the level. Replace the contents of `scenes/main.scene.json` with:

```json scenes/main.scene.json
{
  "format": "factoria.scene/1",
  "settings": { "gravity2D": [0, 0] },
  "entities": [
    {
      "id": "camera",
      "name": "Main Camera",
      "components": {
        "Camera": { "projection": "orthographic", "clearColor": [0.08, 0.09, 0.14, 1], "primary": true }
      }
    },
    {
      "id": "player",
      "name": "Player",
      "tags": ["player"],
      "components": {
        "Transform": { "position": [-200, 0, 0] },
        "Shape2D": { "shape": "rectangle", "size": [40, 40], "color": [0.3, 0.7, 1, 1], "layer": 2 },
        "RigidBody2D": { "type": "dynamic", "fixedRotation": true },
        "Collider2D": { "shape": "box", "size": [40, 40] },
        "Script": { "path": "scripts/player.js" }
      }
    },
    {
      "id": "gem1",
      "tags": ["gem"],
      "components": {
        "Transform": { "position": [100, 0, 0] },
        "Shape2D": { "shape": "diamond", "size": [28, 28], "color": [1, 0.85, 0.2, 1], "layer": 1 },
        "RigidBody2D": { "type": "static" },
        "Collider2D": { "shape": "circle", "radius": 14, "isTrigger": true }
      }
    },
    {
      "id": "gem2",
      "tags": ["gem"],
      "components": {
        "Transform": { "position": [200, 150, 0] },
        "Shape2D": { "shape": "diamond", "size": [28, 28], "color": [1, 0.85, 0.2, 1], "layer": 1 },
        "RigidBody2D": { "type": "static" },
        "Collider2D": { "shape": "circle", "radius": 14, "isTrigger": true }
      }
    },
    {
      "id": "gem3",
      "tags": ["gem"],
      "components": {
        "Transform": { "position": [-100, 150, 0] },
        "Shape2D": { "shape": "diamond", "size": [28, 28], "color": [1, 0.85, 0.2, 1], "layer": 1 },
        "RigidBody2D": { "type": "static" },
        "Collider2D": { "shape": "circle", "radius": 14, "isTrigger": true }
      }
    },
    {
      "id": "gem4",
      "tags": ["gem"],
      "components": {
        "Transform": { "position": [200, -150, 0] },
        "Shape2D": { "shape": "diamond", "size": [28, 28], "color": [1, 0.85, 0.2, 1], "layer": 1 },
        "RigidBody2D": { "type": "static" },
        "Collider2D": { "shape": "circle", "radius": 14, "isTrigger": true }
      }
    },
    {
      "id": "score",
      "name": "Score",
      "components": {
        "Transform": { "position": [24, 24, 0] },
        "Text": { "text": "Gems: 0 / 4", "fontSize": 32, "pivot": [0, 1], "space": "screen", "anchor": [0, 0] },
        "Script": { "path": "scripts/score.js" }
      }
    }
  ]
}
```

The new ideas:

- `settings.gravity2D` `[0, 0]`: nothing falls. This game is seen from above. A platformer would keep the default.
- The world has no ground: `[0, 0]` is the middle of the window, x grows to the right and y **up**. The player starts at
  `[-200, 0]`, left of the middle.
- `Shape2D` draws a plain shape (rectangle, circle, diamond...) so you need no image files. `layer` says what is drawn on
  top: bigger on top.
- The player is a `dynamic` body with a `Collider2D`: physics moves it. The gems are `static` and their collider is a
  trigger (`isTrigger`): the player passes through them and `onTriggerEnter` fires. The tag `"gem"` is how the
  scripts find them.
- The score text is in `space: "screen"` with `anchor` `[0, 0]` (the top-left corner of the window) and a `pivot` of
  `[0, 1]` (its own top-left corner sits on that point), 24 pixels in.

`validate` may now print a `note:` that the two scene files "are formatted by hand": they are valid (it is a note, not a
warning), only the spacing differs from what the engine writes. Running `scene.format` is optional; it rewrites whitespace
only, so later diffs stay small:

```bash
factoria call scene.format
factoria validate
```

Now look at it without opening a window, then play it:

```bash
factoria run --headless --frames 120 --screenshot-at 119
factoria run
```

The screenshot (`.factoria/screenshots/frame_119.png`) shows the blue square at the left of the middle, three gems on
the right half and one on the left half (they are `[100, 0]`, `[200, 150]`, `[-100, 150]` and `[200, -150]`), and
`Gems: 0 / 4` in the top-left corner. In the window, move with A, D, W, S or the arrows. Each gem disappears when you
touch it and the counter goes up; at the fourth the screen changes to "You win!"; Space starts again. Close the window to
stop.

If the square does not move, the window may not have the keyboard: click on it once. If `factoria run` says a script has
an error, it names the file and line; fix it and run again.

## 6. A test

You have just played the game; a test plays it for you every time, in a fraction of a second and without a window. Create
`tests/game.test.js`:

```js tests/game.test.js
import { test, expect, game } from "factoria:test";
import { scene } from "factoria";

test("the player walks right", () => {
  game.load("scenes/main.scene.json");
  const player = game.find("player");
  const x0 = player.position.x;
  game.press("move_right");
  game.step(30); // half a second
  game.release("move_right");
  expect(player.position.x).toBeGreaterThan(x0 + 100);
});

test("touching a gem collects it and counts it", () => {
  game.load("scenes/main.scene.json");
  game.press("move_right");
  game.step(60); // the first gem is 300 pixels to the right of the start
  game.release("move_right");
  expect(game.world.findByTag("gem").length).toBe(3);
  expect(game.find("score").get("Text").text).toBe("Gems: 1 / 4");
});

test("the last gem opens the win screen, and Space plays again", () => {
  game.load("scenes/main.scene.json");
  const player = game.find("player");
  for (const gem of game.world.findByTag("gem")) {
    player.position = gem.position; // jump onto the gem
    game.step(2);
  }
  expect(scene.current).toBe("scenes/win.scene.json");
  game.tap("action");
  game.step(2);
  expect(scene.current).toBe("scenes/main.scene.json");
});
```

```bash
factoria test
```

You should see three lines starting with `PASS` and `3 passed, 0 failed`.

How to read it: `game.load` loads a scene, `game.step(n)` runs `n` frames (60 frames are one second: the test is
deterministic, so the same steps always give the same result), `game.press` and `game.release` hold and let go of an
action, `game.find("player")` gets the entity with that `id`. The last test teleports the player onto each gem
(`position` can be assigned) instead of steering it, and checks `scene.current`.

Make it fail once, to see how: in `scripts/player.js` change `speed = 300` to `speed = 30` and run `factoria test`. Two
tests fail, and each prints what it expected, what it got and the line of the `expect`, like
`expected: > -100`, `received: -185.5`, `at tests/game.test.js:11:50`. Put the 300 back.

## 7. Give it to someone

```bash
factoria export
```

It writes the game for this computer into `build/export/gem-grab-<system>/` (for example `gem-grab-windows`), with the
program (`gem-grab.exe` on Windows) and a `game/` folder next to it. Zip the whole folder and send it: nobody needs
FactorIA to play it. Keep `FACTORIA_NOTICES.txt` in it (the licenses of the engine inside the game). A warning says the
game has no icon: that is for later. Other systems, phones, the web and the details: [EXPORTING.md](EXPORTING.md).

## What the AI did for you

Count what you did by hand: six files, in the right format, with every path and id spelled the same in three places.
An AI writes the same files, but it also validates, tests and screenshots as it goes (that is why it works in loops), and it
reads these docs through the same commands you used: `factoria validate`, `factoria test`, `factoria call ...`. The reverse
holds: anything it makes is plain JSON and JavaScript like the above, so you can open, read and change any of it.

Things this game does not have yet, good practice for either way of working:

- Walls: the square can leave the window. Ask for (or write) four static walls, or clamp the position in `player.js`.
- A sound when a gem is collected (`audio.play`, [SCRIPTING.md](SCRIPTING.md)) and a test with `game.audioLog()`.
- Gems that appear at random places (`world.rng()`, never `Math.random`: runs must repeat exactly).

## Next steps

- [Your first game with an AI](FIRST_GAME_WITH_AI.md): the same kind of game, built by talking to the editor.
- [FINISHING.md](FINISHING.md): a menu, options, saves, languages and the other things a store expects.
- [PUBLISHING.md](PUBLISHING.md): what to do, store by store, to put it on sale.
- [SCRIPTING.md](SCRIPTING.md): everything scripts and tests can do.

*Maintainers:* this project is `tools/cli/tests/fixtures/gem-grab`. When you change a file here, change it there (and the
other way round); a `cli` test fails when a block with a file name differs from the fixture.
