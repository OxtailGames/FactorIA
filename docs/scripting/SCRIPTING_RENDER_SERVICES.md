Part of [SCRIPTING.md](../SCRIPTING.md): Render textures, procedural meshes, the date, `rng`, math, plugins, platform, http, i18n and `fa` (commands).

# Scripting: render services

### Render: a picture of the running game as a texture (`render.captureTexture`, `render.textureFromPNG`)

For a save slot's thumbnail, a photo mode or a minimap snapshot. A texture's `id` is accepted by `Sprite.texture`, `Panel.texture`
and `Button.icon` (docs.components).

- `render.captureTexture({ width, height, fit })` returns a `Texture`: the picture the player sees (HUD and every camera) at
  `width` x `height` pixels, each from 1 to 2048. To photograph one entity or an area of the world instead, at a scale you pick,
  use the world form below. `fit: "cover"` (default) cuts the middle part with that aspect ratio out of the
  frame, so nothing is distorted; `"stretch"` squeezes the whole frame in.
- Which frame: called from a script during a frame (an `onUpdate`, an event handler) it is the last frame that was drawn,
  i.e. the one BEFORE the frame the script runs in; what the script changed in this frame (a spawned entity, an edited
  field) is not in it yet. An entity that was destroyed during a frame (`entity.destroy()`, children too) is not drawn in
  that frame, so a group rebuilt in one frame (the old one destroyed, the new one spawned) shows only the new one in the
  next capture. In a
  test, before any frame was drawn and in headless runs it draws the current state first, like `game.screenshot`. A capture
  the size of the game (`game.screenSize` times `window.renderScale`) has exactly the pixels of a screenshot of that frame.
  The frame is read back from the GPU (Metal, OpenGL / GLES, Direct3D 11, WebGL2) and resampled on the CPU.
- A run with `graphics` off has no renderer: the texture is a flat colour of the size asked and `texture.placeholder` is
  `true`. Check it before you store the picture if a flat square would mislead the player.
- `texture.id` (`"runtime:3"`) goes where an asset path goes: `entity.get("Sprite").texture = tex.id`, `Panel.texture`,
  `Button.icon`. A Sprite with no `size` takes the texture's pixel size. A `Panel` samples it without smoothing.
- `texture.toPNG()` returns the picture as a PNG file Base64-encoded, a string, because `storage` keeps JSON only:
  `storage.set("slot1.pic", tex.toPNG())`. `render.textureFromPNG(text)` makes a texture of it again (a `data:image/png;base64,`
  URL works too). Both are synchronous: there is no Promise and no scene change to wait for. A Base64 string is about a third
  longer than the file, so keep pictures small (a 156 x 156 town picture is a few KB).
- `render.captureTexture({ entity | rect, space: "world", scale })` is the WORLD form: it draws a part of the world off-screen
  at `scale` pixels per world unit and returns it as a `Texture`. It is not a picture of the screen, so it does not need a frame
  to have been drawn (it works in `onStart`, in a test and before the first frame), it is not capped at 2048 and it does not care
  what the player sees: the subject may be hidden (`active` off, or inside a hidden parent), covered by other things or far outside
  every camera. Give exactly one of `entity` (the entity and its children: the area is the union of their `entity.bounds()`, from world-space Sprite,
  Shape2D, Text and Tilemap; particles and meshes inside that area are drawn too) or `rect` (`[x, y, w, h]` in world units, everything active inside it). The picture is
  `ceil(w * scale)` x `ceil(h * scale)` pixels, at most 4096 on a side (a bigger one is an error that names the largest `scale`
  that fits), with a transparent background (alpha 0 where nothing was drawn) and unpremultiplied colour. `width`, `height` and
  `fit` are the screen form's options and are an error here. An `entity` with `active` off is drawn anyway (its own flag and its
  ancestors' are ignored; a descendant that is itself inactive is not). A `rect` draws only what is active. The HUD and the
  screen-space UI are never part of it. A Sprite that shows `"target:<name>"` (docs/RENDERING.md) appears with that target's last
  picture. Meshes are drawn from the front by an orthographic camera. In a run with `graphics` off the texture is a flat
  placeholder of the computed size, like the screen form. Memory is width x height x 4 bytes in the engine plus the same on the
  GPU while it is drawn: a 4096 x 4096 picture is about 64 MB, and the 32-texture limit below counts it.
  `render.textureFromPNG` accepts pictures up to 4096 x 4096 too.
- At most 32 textures are alive at once. `texture.destroy()` frees one (safe to call twice; `toPNG()` then throws). Stop
  showing a texture (destroy its entity or change the texture field) before you destroy it: a frame that still names it draws
  the missing-texture checker and logs why. Every test file starts with no textures.
- The engine keeps each texture's pixels in memory as well (width x height x 4 bytes) so `toPNG()` works in every run.

```js fragment
// Save: the picture goes into storage with the slot. Take it BEFORE a menu covers the game.
const tex = render.captureTexture({ width: 156, height: 156 });
if (!tex.placeholder) storage.set("slot1.pic", tex.toPNG());
tex.destroy();

// Show: build the texture, use its id, destroy it when the thumbnail goes away (a behaviour of the thumbnail entity).
onStart() {
  const png = storage.get("slot1.pic", null);
  if (png) {
    this.pic = render.textureFromPNG(png);          // throws a teaching Error for text that is not an image
    this.entity.get("Panel").texture = this.pic.id;
  }
}
onDestroy() { if (this.pic) this.pic.destroy(); }

// World form: a card that is hidden, photographed at 2 pixels per unit, then shown as a sprite (the card keeps its own scale).
const card = world.find("Card");                       // active: false, it is only drawn to be copied
const shot = render.captureTexture({ entity: card, space: "world", scale: 2 });
world.find("Preview").get("Sprite").texture = shot.id;  // destroy `shot` when Preview goes away
```

Nothing here awaits an answer, so there is no scene to re-check; if you capture inside a `scene.preload` or `http`
callback, compare `scene.current` with the scene you started in before you act on it (the entity you pass to the world form
must still exist, or the call throws). `scene.current` is equal after a
reload of the same scene: keep `const gen = scene.generation` and compare it instead, it changes on every load.

### Procedural meshes (`mesh.create`, `mesh.update`, `mesh.destroy`, `mesh.save`)

For geometry a script builds while the game runs: a terrain patch, a deformed body, a generated tree, a custom shape from a
voxel grid. You do not write a glTF file: `mesh.create` returns a `Mesh` whose `id` (`"mesh:3"`) goes where a model path goes.

```js
const m = mesh.create({
  positions: [0,0,0,  1,0,0,  1,0,1,  0,0,1],     // x y z per vertex (or [[0,0,0], [1,0,0], ...])
  uvs:       [0,1,  1,1,  1,0,  0,0],             // optional, u v per vertex
  indices:   [0,2,1,  0,3,2],                     // three per triangle
  submeshes: [{ material: { name: "grass", color: "#58a040", roughness: 0.9 } }],
});
this.entity.get("MeshRenderer").mesh = m.id;
// later, every frame if you like:
m.update({ positions: newPositions });            // the rest is kept
```

- **Arrays.** `positions` (3 numbers per vertex), `normals` (3), `uvs` (2), `tangents` (4: xyz and a handedness w of 1 or -1; 3 means
  w = 1), `colors` (4 rgba or 3 rgb) are flat lists, typed arrays (`Float32Array`, read without a copy through the
  language) or lists of `[x, y, z]` / `{x, y, z}`. `indices` (a flat list, a `Uint32Array` or a list of `[a, b, c]`) has three per
  triangle; left out on create it is `0, 1, 2, 3, ...` (a triangle soup).
- **Computed.** Missing `normals` are smooth and area-weighted; missing `tangents` come from the `uvs` (zero `uvs` give an
  arbitrary but valid tangent frame). A mesh without `normals` or `tangents` on update gets them computed again from the new data.
- **Conventions are glTF's:** right-handed, +Y up, counter-clockwise triangles face front, uv (0, 0) is the top-left of the
  image (v grows downwards). Meshes of a saved file and meshes made here therefore look the same.
- **Materials and submeshes.** `submeshes: [{ material, start, count }]` splits the index list into runs drawn with their own
  material; `start` and `count` count indices (multiples of 3), `start` defaults to where the previous run ended and `count`
  to the rest. A material is a name or `{ name, color, texture, metallic, roughness, emissive, doubleSided, blend }` (the fields of a
  glTF material the renderer reads); `texture` is a project image path or a `render.captureTexture` texture. Without `submeshes`
  there is one submesh with a default material over all the indices; indices outside every submesh are not drawn.
  `MeshRenderer.color` tints the base color, `materialColors` is keyed by the submesh's material `name`, and a material that gives
  `metallic` or `roughness` replaces `MeshRenderer.metallic`/`roughness` for that submesh (as a glTF material does).
- **Vertex colors** (`colors`, rgb or rgba per vertex) are drawn like glTF `COLOR_0`: they multiply the submesh material's base color
  (and so `MeshRenderer.color`), rgb and alpha, lit or `unlit`, instanced, in the shadow pass of a `clip` material and in custom
  materials (a snippet reads them as `i.vertex_color`, `v.color` in `vertex()`, docs/SHADERS.md). They are clamped to 0..1 with 8 bits
  per channel on the GPU and white when you give none, so a mesh without `colors` looks exactly as before. Alpha below 1 shows only
  with a material that has `blend: true` (or a `clip` material, which discards below its cutoff). They are also written to a saved
  `.glb` as `COLOR_0`, and `.glb`/`.gltf` models that carry `COLOR_0` are drawn the same way.
- **Pointer through a render target.** A procedural mesh can show a camera's picture (`MeshRenderer.texture: "target:book"`, or a
  submesh material whose `texture` is `"target:book"`) and the pointer reaches the page's `Interactable`s through its `uvs` at the triangle
  under the mouse, like any other mesh (docs/RENDERING.md, "Pointer input through the mesh"). The hit test uses the mesh as it is
  now: bend a page with `mesh.update` and the next click lands on the new shape.
- **Update.** `mesh.update(m, {...})` (or `m.update({...})`) replaces what you give and keeps the rest (`positions`, `uvs`,
  `colors`, `indices`, `submeshes`; the `uvs` only if the mesh was made with some). `normals` and `tangents` are computed again unless
  you pass them. Changing `indices` of a mesh with several submeshes needs `submeshes` as well. The bounds follow, so culling,
  shadows and picking stay right. The GPU buffers are reused while the new data fits (they are made 50% larger when a
  mesh outgrows them), so a per-frame update of a mesh that keeps its size creates no buffer; two changes of one mesh inside
  one frame make new buffers for the second.
- **Colliders.** `Collider3D` with `shape: "convex"` or `"mesh"` accepts the id in `Collider3D.mesh` (docs.components). Every
  update rebuilds the collider's shape, so a mesh collider on a mesh you deform each frame is expensive: update it less often
  or use a primitive collider. A box or sphere collider needs no mesh at all.
- **Limits.** 256 live meshes, 1 048 576 vertices and 6 291 456 indices per mesh. A mesh that is not shown any more should
  be destroyed.
- **Errors teach.** A wrong array length, an index outside the vertices, a submesh outside the index list, a number that is NaN
  or infinite, or a destroyed or unknown id throws an `Error` naming the field, the counts and the fix.
- **Lifetime.** A mesh belongs to the scene that was running when it was made. Loading a scene (or reloading the same one)
  releases every procedural mesh, like its entities. The ids are never reused in a run, so an old id never names another mesh.
  An entity that names a mesh that is gone (destroyed, or from the old scene) draws a placeholder box and the error log says
  why once. Meshes are NOT written to scene files: `factoria validate` rejects a `mesh:N` id in a scene or prefab; use
  `mesh.save` to get a file. In an `onUpdate` that kept a `Mesh` for a long time, `m.alive` is false once the scene changed;
  `m.update`/`m.save` then throw, and `m.destroy()` is quiet.
- **Save.** `mesh.save(m, "assets/models/tree.glb")` (or `m.save(path)`) writes a `.glb` with one primitive per submesh,
  its materials and `COLOR_0`, and returns the path; it loads back as a normal model (`MeshRenderer.mesh = path`) with
  the same submeshes and `materialColors` names. The path must end in `.glb` and be a place commands may write. A material
  without `metallic` or `roughness` is saved with the defaults (0 and 0.6). A material texture that is a run-time texture cannot be
  saved (the file would point at nothing): the error says so.
- **In the editor.** A procedural mesh in a running (play) scene is picked and outlined by its real bounds and triangles, and the inspector
  shows its vertex and triangle counts next to `MeshRenderer.mesh`.

The same operations are commands for the tools that work on a project (the `factoria` CLI, MCP and the editor's AI; the editor's Play
has them too, the exported player does not, and a game script uses the `mesh` API above, which acts on the same meshes):
`mesh.create` (the options above as JSON;
a flat list or lists of triples), `mesh.update {id, ...}`, `mesh.destroy {id}`, `mesh.save {id, path}`, `mesh.list` and
`mesh.info {id}`. They act on the scene that is loaded in the process that runs them (a mesh lives only as long as that process and scene), and you set the field with
`scene.set_component {"id": "...", "component": "MeshRenderer", "fields": {"mesh": "mesh:1"}}`.

A model written as data (`*.model.json`, docs/MODELING.md) is baked to a `.glb` by `model.bake` through the same writer as
`mesh.save`: each part of the model is one primitive of the file with the part's name in its `extras.part`.

After an `await` (`scene.preload`, `http.fetch`, a timer) the scene may have changed, and the meshes of the old one are
released: compare `scene.generation` with the value you kept before you use a mesh you made or build a new one.

```js fragment
async onStart() {
  const gen = scene.generation;                 // changes on every load, also of the same scene
  const r = await http.fetch("https://api.example.com/terrain").catch(() => null);
  if (!r || scene.generation !== gen) return;   // another scene is running: do not build for it
  const data = r.json();
  this.mesh = mesh.create({ positions: data.positions, indices: data.indices });
  this.entity.get("MeshRenderer").mesh = this.mesh.id;
}
onUpdate() { if (this.mesh && this.mesh.alive) this.mesh.update({ positions: this.nextPositions() }); }
onDestroy() { if (this.mesh) this.mesh.destroy(); }
```

### The date: `game.today()` (never `Date`)
`new Date()` and `Date.now()` read the wall clock, so a run is different every time and a test cannot pin it. Read the
calendar date with `game.today()` instead, as you use `rng` for chance:

```js
import { game, rng } from "factoria";
const t = game.today();   // { year: 2026, month: 3, day: 14, weekday: 6, hour: 23, minute: 59, second: 30, utcOffsetMinutes: -300,
                          //   iso: "2026-03-14", utc: { year: 2026, month: 3, day: 15, iso: "2026-03-15" } }
rng.seed(t.year * 10000 + t.month * 100 + t.day);   // a daily challenge: everybody plays the same seed on the same day
```

`weekday` is 0 = Sunday to 6 = Saturday; `hour`, `minute` and `second` are the local time of day; `utcOffsetMinutes` is the
local offset from UTC and `utc` is the date of the same moment in UTC (pass `utc.iso` as a leaderboard's `options.day` for one daily board
worldwide, see PLATFORM.md, "Leaderboard periods"). In a built game the date and time are the player's real local ones,
read when the game starts, about once a minute while it runs, and each time the app comes back to the foreground or the
window gets the focus (before `game.on("resume")` / `game.on("focus")` run), so `game.today()` is at most a minute behind the
clock. When the local calendar day changes meanwhile (past midnight, a clock set to another day, a game left in the
background overnight) the game event `dayChanged` goes to `game.on("dayChanged", (today) => ...)` once, with the new
`game.today()`: refresh the daily challenge, the daily reward and the daily leaderboard there. A change of time zone or
daylight saving alone is not a new day.
In `factoria test`, `factoria run --headless`, `call`, `session`, `mcp` and `screenshot` it is the fixed date
`2026-01-01` at 00:00:00 and never moves, so runs are reproducible; `--date YYYY-MM-DD[THH:MM[:SS]]` chooses another (see
CLI.md). A replay recorded in the editor stores the date, time and offset it was played on (`date`, `time`,
`utcOffsetMinutes`) and plays back with them, so a daily run replays identically even when it was recorded at 23:59 (an
older replay without a time plays at 00:00:00, one without a date on the fixed default date). The replay keeps the date it
started on: a midnight crossed during a recorded session is not replayed. In tests `game.setDate("2026-03-14")` changes
the date (reset before each test); `game.setDate("2026-03-14T23:59:30", { utcOffsetMinutes: -300 })` also sets the time and
the time zone, and moving to another local day sends `dayChanged` once, so a test crosses midnight with two calls
(`"2026-03-14T23:59:59"`, then `"2026-03-15T00:00:01"`). An impossible date or time throws an error that says which part is
wrong.

### rng (deterministic, seeded per run)
`rng.seed(n)` reseeds the world RNG (seed → level determinism from tools/tests) · `rng.float()` [0,1) · `rng.range(a, b)` · `rng.int(a, b)` (inclusive) · `rng.chance(p)` · `rng.pick(array)` · `rng.shuffle(array)` (a shuffled copy)

`rng` is the ONE random stream of the running game, and `Math.random()` draws from it too. Reseeding it changes what
the game does next, and a script cannot read its state to restore it. A generator that must be repeatable from a seed
(a level generator tool, a name or loot table) therefore uses its own generator:

```js
import { rng } from "factoria";

const r = rng.create(42);              // independent: never touches the world RNG
const width = r.int(30, 60);           // 30..60 inclusive
const hill = r.chance(0.3);
const order = r.shuffle(["a", "b", "c"]);
r.seed(42);                            // start over; same as rng.create(42)

const saved = r.state;                 // one 32-bit number: the whole stream, for a save game
r.float();
r.state = saved;                       // the stream resumes there: the next float() repeats
```

`rng.create(seed)` returns a generator with the same methods as `rng` (`float`, `range`, `int`, `chance`, `pick`,
`shuffle`, `seed`). Using it never changes `rng.float()` or `Math.random()`, and two generators never share state.

- **Algorithm (stable).** mulberry32: a 32-bit state that advances by `0x6d2b79f5` per draw, mixed to a 32-bit
  integer; `float()` is that integer divided by 2^32, so it is in [0, 1). The algorithm and the draws each method
  uses are guaranteed not to change between engine versions, so a stored seed keeps producing the same level on every
  platform. A change would be a breaking change of the engine.
- **Draws per call.** `float`, `range`, `int` and `chance` draw once. `pick` draws once (not at all for an empty
  array). `shuffle` draws `length - 1` times (Fisher-Yates from the end). A call always draws the same number of
  times whatever its arguments are (`int(5, 5)` still draws), so the sequence does not depend on the arguments.
- `int(min, max)` is `min + floor(float() * (max - min + 1))` with both ends inclusive and truncated to integers; it
  returns `min` when `max <= min`. `range(min, max)` is `min + (max - min) * float()`. `chance(p)` is `float() < p`
  (default 0.5). `pick(items)` is `items[floor(float() * items.length)]`.
- **Seed.** A finite number, reduced to 32 bits (`seed >>> 0`: the integer part, modulo 2^32). `0` is valid, `1` and
  `4294967297` give the same sequence, and so do `1` and `1.9`. A non-number or `NaN` throws an error that shows an
  example.
- **State.** `generator.state` is the 32-bit state, an integer from 0 to 4294967295: the seed advanced by `0x6d2b79f5`
  (modulo 2^32) per draw. Read it to store the stream in a save; assign it (or pass it to `rng.create`) to resume. It
  is as stable as the algorithm. Assigning something that is not such an integer throws and keeps the old state. Keep one
  generator per purpose (ships, events) so a new draw in one does not shift the others.
- 32 bits of state means a period of 2^32 draws: plenty for a level or a table, not meant for cryptography.

### math & values
- `vec2(x, y)`, `vec3(x, y, z)`, `color(r, g, b, a?)` / `color("#ffcc00")`
- `Vec2`/`Vec3` methods: `add sub mul scale div dot length lengthSq normalized distance lerp clone equals`,
  `Vec2.fromAngle(deg)`, `v.angle()`, `v.rotated(deg)`
- `math`: `clamp lerp inverseLerp remap damp moveTowards approach sign degToRad radToDeg wrapAngle`
- `console.log/warn/error` go to the engine log (category `script`).

### plugins (native code)
`plugins.<name>.<function>(...args)` calls a function of a native plugin the game declares in `factoria.json`
(`"plugins"`; [EXTENDING.md](../EXTENDING.md), section G): `plugins.example.add(1, 2)`. Arguments and the result travel as
JSON. A plugin's functions and their doc strings are in `types/factoria.d.ts` (`PluginsAPI`) once the plugin is loaded.

- On a platform the plugin is not declared for, `plugins.<name>` is `undefined`: `if (plugins.steam) ...`.
- A plugin that did not load (no build for this platform, its entry point failed) is still there, and any use throws
  with the reason: `plugins.steam.unlock: the native plugin 'steam' is not loaded: ...`.
- A function that fails throws `plugins.<name>.<function> failed: <message> (hint: <hint>)`; a name the plugin does not
  have throws with a did-you-mean and the names it has.
- A plugin's commands are ordinary commands: `fa.call("example.info", {})`.

### platform (stores: achievements, purchases, cloud saves...)
`import { platform } from "factoria"`: achievements, stats, leaderboards, cloud saves, in-app purchases, the store overlay
and rich presence behind one API that every store backend answers (the fake store in development and in all tests, a
store SDK through a native plugin). **Every call returns a Promise**; ids come from the `"platform"` catalog in
`factoria.json`, and a typo throws at once with a "did you mean". Store failures reject with `e.code` and `e.hint`.

```js
if (platform.has("achievements")) platform.achievements.unlock("first_win").catch(() => {});
const r = await platform.purchases.buy("gems_100");               // { status, productId, transactionId, receipt }
if (r.status === "purchased") { addGems(100); await platform.purchases.finish(r.transactionId); } // grant, then finish
platform.on("overlay", (e) => (game.paused = e.open));            // also "purchase" and "player"
```

Members: `backend`, `has(service)`, `player`, `signIn()`, `on(event, fn)`, `achievements` (`unlock progress list reset`),
`stats` (`get set add`), `leaderboards` (`submit entries`), `cloud` (`save load list remove`), `purchases` (`products buy
finish restore`), `overlay.open(page, id?)`, `presence.set(text, data?)`, `integrity.token(challenge)` (a signed token for the game's own
server to verify). Everything about it, the catalog, the error
codes, the fake store's test hooks (`game.platform` in `factoria:test`) and how to write a backend plugin, is in
[PLATFORM.md](../PLATFORM.md). `game.platform` of the `factoria` module is the operating system's name, a different thing.

### http (web requests)
`import { http } from "factoria"`: `http.fetch(url, { method, headers, body, timeout })` returns a Promise of the server's
answer `{ status, ok, headers, text, json() }`, on every platform (WinHTTP, `NSURLSession`, libcurl, `HttpURLConnection`,
the browser's `fetch`). The game declares the servers it may call in `factoria.json` (`"network": { "hosts": [...],
"purpose": "..." }`); `https://` only; an undeclared host throws at once. Tests get the fake: `game.platform.respond("http.fetch",
{ status: 200, json: {...} })`, no network. The answer may arrive after the scene changed: check `scene.current` before
using it. Limits, the recipe, replays, per-platform notes (CORS on the web, the Android permission) and the privacy side:
[NETWORKING.md](../NETWORKING.md). Usage events (after the player consents) and values read from your server, both on top of
`http.fetch`: `analytics.event(name, props)` and `remoteConfig.get(key, fallback)`, in [ANALYTICS.md](../ANALYTICS.md).

```js
const r = await http.fetch("https://api.example.com/daily").catch(() => null);   // rejects on a network failure
if (r && r.ok) startChallenge(r.json().seed);                                   // a 404 resolves with ok: false
```

### i18n (several languages)
`import { i18n } from "factoria"`: the strings of `locales/<language>.json` in the player's language (factoria.json
`"localization"` lists the languages; without it `t(key)` returns the key and `languages` is `[]`). A Text or widget
with a `key` is translated by the engine; `t` is for the text a script builds.

```js
label.text = i18n.t("hud.coins", { count: coins });      // "3 monedas": {placeholders} and plural forms by args.count
i18n.setLanguage("es");                                   // everything with a key changes now; the choice is not saved
const off = i18n.on("change", (e) => redraw(e.language)); // after every switch; ends with the scene, like ui.on
```

`i18n.number(1234.5)` ("1,234.5", "1234,5" in Spanish) and `i18n.duration(83.4)` ("1:23.4") write numbers and times the
way the current language does.

Members: `t(key, args?)`, `number(v, {decimals?})`, `duration(seconds, {decimals?})`, `has(key)`, `language`, `setLanguage(tag)`, `languages`, `defaultLanguage`, `systemLanguages`,
`name(tag)`, `on("change", fn)`. Every test file starts in `defaultLanguage`. All of it, the string tables and how the
start language is chosen: [LOCALIZATION.md](../LOCALIZATION.md).

### fa (commands)
`fa.call(name, args)` runs any command (same as MCP tools) and returns its result · `fa.commands()` lists them.
On failure `fa.call` throws an `Error` whose message is `<name> failed: <message> (hint: <hint>)` and which also
carries `e.code`, `e.hint` and, when the command reported structured details, `e.data`: a project tool that throws
`ToolError(message, hint, data)` gives the caller `e.code === "tool_error"` and `e.data === data`, so a test can assert
on the data instead of parsing the message.

#### What `fa.call` can do from a game
Every `fa.call` runs the command with a **capability set** (`docs/design/ARCHITECTURE_COMMANDS.md`, "Capabilities"); a command that needs
more fails with code `capability_denied`, before its arguments are looked at, and the error says who may do it.

| Who calls | Set |
|---|---|
| A game script (a behaviour's callbacks, events, timers, module top levels; see "Promise continuations" below for promises) in the player (`factoria run`, an exported game) | `{read, state}` |
| A game script in the editor's Play | `{read, state}` |
| A test (`factoria test`, `project.test`) | `{read, state}` plus the test's `capabilities` option, never more than whoever runs the tests |
| A project tool (`tools/*.js`), `script.eval` | the caller's own set: `factoria call` has all, MCP all but `writeAnywhere`, an agent all but `writeAnywhere` and `publish` |

`{read, state}` means a game can read anything and change the running game or the open scene in memory (`scene.spawn`,
`scene.set_component`, `game.state`, `game.step`, `ui.*`, `vfx.play`, `tilemap.set_tile`...), but cannot write a file
(`scene.save`, `scene.import_ascii`, `scene.format`, `fs.write`...), reach the network, start a program or spend money:
a shipped game must not be able to do to a player's machine what a tool does to a project. In the exported player (and `factoria run`) `fa.call` also sees only the commands of the runtime (`Engine::runtime_command_names`); the commands only developer tools need (`scene.import_ascii`, `scene.ascii_edit`, `scene.format`, `prefab.save`, `mesh.*`, `vfx.check`/`budget`/`filmstrip`, `anim.*`, `skin.*`, `bones.*`) are CLI, editor and MCP only, and calling one fails with `unknown_command` and a hint. A game uses the `mesh` and `vfx` script APIs, `scene.place_ascii` for an ASCII level and the Animator component for clips. Do those from the editor,
from a project tool, with `factoria call`, or from a test that asks for them. A tool a game script calls through
`fa.call("project.<name>")` runs with the **game's** set (a scope only narrows), so a script cannot widen its permissions
by going through a tool; a tool called from outside keeps the caller's set, never narrowed to the game's. The callbacks of
behaviours that a test or a tool triggers (`game.step`) still run with the game's set, and so does the top level of a module
that a test or a tool imports for the first time, including the modules a test file imports statically and what those import
(only the test file's own top level is test code).

**Promise continuations and listeners run with the set of whoever pumps the jobs.** The engine runs the pending promise jobs
(`await` continuations, `.then` callbacks, async `world.on` listeners) in one queue, after a tool, `script.eval` or a test
call, and after each `game.step`. That queue does not remember which code queued a job, so a continuation or listener of the
game that is still pending when a tool, an eval or a test pumps the queue runs with **that caller's** set (a test's
`{read, state}` plus its option; a tool's own, up to everything for `factoria call`), not with the game's. The same
continuation that runs in the player's own frame loop gets `{read, state}`. So do not rely on the game set to keep a
continuation from writing: a shipped game is bounded by the player, where nobody else pumps its jobs. A test that must prove a
game script cannot do something drives it from a behaviour callback (`game.step`), not from a promise.

The engine library asks for no more than that. `tilemap.generate` with `place` places the level with `scene.place_ascii`
(the in-memory twin of `scene.import_ascii`, `{read, state}`: no `path`, `from`, `save`, `dryRun` or `edits`), and every
other helper of `factoria` calls only `{read, state}` commands (`game.state` for `game.state()`, `tilemap.generate_start`
and its steps). `scene.import_ascii` and `scene.ascii_edit` are authoring commands: an exported game does not have them at all, and
from the editor's Play a game script that calls one to write a file is refused.

The exported player does not have every command of this table's callers: the commands only developer tools use are left out of
it, so `fa.call("scene.format")` in a game script fails there as an unknown command. `factoria validate` warns about such a
call and `factoria export` stops on it (docs/EXPORTING.md, "What is shipped"); scripts under `tools/` and `tests/` may call them.

#### A test asking for more: `capabilities`
A test that writes a project file (a level rebuilt on disk and compared, a screenshot, a scene saved to check it round-trips)
says so in its options. The names are those of the capabilities (`read`, `state`, `writeProject`, `writeAnywhere`,
`network`, `process`, `spend`, `publish`), as an array or one string:

```js
test("the level rebuilds identically", () => {
  fa.call("scene.import_ascii", { ...args, path: ".factoria/tmp/rebuilt.scene.json" });
  fa.call("fs.delete", { path: ".factoria/tmp/rebuilt.scene.json" });
}, { capabilities: ["writeProject"] });
```

The test gets `{read, state}` plus what it asks for, then **intersected with the set of whoever runs the tests**: an option
can only narrow from there, so under `factoria mcp` a test never gets `writeAnywhere`, and a read-only run grants nothing.
The set is back to `{read, state}` for the next test. A name that is not a capability is a load error of the file with
the JSON pointer (`/options/capabilities/0`) and "did you mean". Game scripts a test runs keep `{read, state}` whatever the
test asks for. A test that calls a command it was not granted fails with `capability_denied` and a hint with the option
and an example.
