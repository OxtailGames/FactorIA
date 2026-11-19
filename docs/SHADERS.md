# Custom shaders (materials)

A **material** gives some meshes their own look: a pulsing gem, dissolving armor, water, grass in the wind, a rim glow.
You write a small GLSL **snippet** and a **material file** that names it and declares its parameters. The engine injects
the snippet into its own mesh shader, so instancing, skinning, lights, shadows, fog and sky reflections keep working.
You never write a vertex shader, a fragment shader or a `main`.

The loop for an AI (or a person):

1. Write `materials/<name>.material.json` and `shaders/<name>.surface.glsl`.
2. `shader.compile` (MCP `shader_compile`) with `{"material": "materials/<name>.material.json"}`; fix every error it
   lists and call it again until `ok` is `true`. `material.info` describes a material (params, textures, ranges, docs).
3. Put `"material": "materials/<name>.material.json"` on a `MeshRenderer` and look at the result with
   `factoria run --headless --frames 60 --screenshot-at 59` (MCP `game_screenshot`).
4. `factoria validate` checks and compiles every material for every platform.

`MeshRenderer.material` and `MeshRenderer.materialParams` are in `docs.components`; the file format is
`schemas/material.schema.json`.

## The material file

`materials/<name>.material.json` (format `factoria.material/1`):

| Key | Meaning |
|---|---|
| `format` | Always `"factoria.material/1"`. Required. |
| `shader` | Project-relative path of the snippet, e.g. `"shaders/pulse.surface.glsl"`. Required. |
| `doc` | What the material looks like and is for. Shown by `material.info`. |
| `kind` | What the material is for: `"mesh"` (default; the surface of a `MeshRenderer`, what this page describes), or `"sprite"` (a 2D item: `Sprite`, `Shape2D`, `Tilemap`, `Text`, particles; [below](#materials-on-sprites-shapes-tiles-text-and-particles)), or the reserved `"sky"`, `"post"` and `"compute"`. `"mesh"` and `"sprite"` compile: `shader.compile` refuses the others with an error on `/kind` that names the engine milestone package that will bring them (sky: M72.1, post: M72.2, compute: M72.4). |
| `lighting` | `"pbr"` (default): the engine's lighting, fog and sky reflection. `"unlit"`: the surface albedo is drawn as it is, plus emission and fog. `"custom"` (mesh materials only): your snippet defines `light()` (and optionally `ambient()`), which the engine's light loop calls once per light instead of its own shading (see "Custom lighting" below); shadows, attenuation, emission and fog stay the engine's. |
| `alphaMode` | `"opaque"` (default): alpha is ignored. `"clip"`: fragments with `alpha` below `alphaCutoff` are discarded, also in the shadow pass. `"blend"`: drawn with the blended meshes, far to near. |
| `doubleSided` | `true` draws back faces too. Default `false`. |
| `params` | Typed parameters the snippet reads (below). |
| `textures` | Textures the snippet samples (below). |
| `graph` | Optional [node graph](#node-graphs) the snippet is generated from. |
| `graphHash` | Written by `material.graph.generate`: the hash of the snippet it generated. Do not write it by hand. |

**Params.** Each key is a variable of your snippet (`"strength"` becomes `strength`). Every param needs `type`, `default`
and a `doc` saying what it does and its unit (AIs read these through `material.info`).

| `type` | `default` | In GLSL |
|---|---|---|
| `float` | `1.5` | `float` |
| `vec2`, `vec3`, `vec4` | `[0.1, 0.2]` (2, 3 or 4 numbers) | `vec2`, `vec3`, `vec4` |
| `color` | `[1, 0.5, 0, 1]` (always 4 numbers) | `vec4` |

`min` and `max` are optional; they document the range (`material.info` lists them) and are checked against the default. At most **16
params** (each takes a `vec4` of a 256-byte block), counting the implicit `alphaCutoff`.

**Textures.** Each key `waves` gives you the GLSL names `waves` (the texture) and `waves_smp` (its sampler). Fields:
`default` (project-relative image used when an entity gives none), `sampler` (`linear` default, `linearRepeat`,
`nearest`, `nearestRepeat`; use a `Repeat` one when you scroll or tile) and a required `doc` (channels, color space). At
most **4 textures**; pack masks into the channels of one image. A texture can be read in `surface()`, in `light()`
and in `vertex()` (see "Textures in `vertex()`" below).

**Names.** Params and textures share one namespace. A name is a GLSL identifier, must not start with `fa_` (the engine's
prefix), must not be a GLSL keyword or one of `main`, `surface`, `vertex`, `Surface`, `SurfaceInput`, `VertexData`,
`LightSample` (and, in a `"custom"` material, `light` and `ambient`), and a texture `x` also takes `x_smp`.

**`alphaCutoff`.** `"alphaMode": "clip"` adds the float param `alphaCutoff` (default 0.5, range 0..1) by itself: the
engine runs `surface()` and discards the fragment when `s.alpha < alphaCutoff`. Declare `alphaCutoff` yourself (as a
`float`) only to change its default, range or doc.

## The snippet

A plain GLSL 450 file (Vulkan style, what sokol-shdc reads), with no `@` tags and no `main`. It defines:

- `void surface(in SurfaceInput i, inout Surface s)` (**required**), run per fragment.
- `void vertex(inout VertexData v)` (optional), run per vertex.

Both may be preceded by your own helper functions (they compile in both stages). `surface()` arrives with `s` already
filled with what a plain `MeshRenderer` would draw (texture times color times vertex color, normal map, metallic/roughness/occlusion maps,
emissive), so change only what you need: a pulse is two lines and keeps working with the entity's `color`, `texture`
and glTF materials.

```glsl
struct SurfaceInput {        // read-only, per fragment
    vec3 world_pos;
    vec3 world_normal;       // interpolated geometric normal, normalized, flipped on back faces
    vec4 world_tangent;      // xyz tangent, w handedness
    vec2 uv;                 // after MeshRenderer.uvScale
    vec4 vertex_color;       // the interpolated vertex color (glTF COLOR_0 or the `colors` of a procedural mesh); white without.
                             // Already multiplied into the s.albedo and s.alpha that surface() starts from
    vec3 view_dir;           // surface -> camera, normalized
    bool front_facing;
};
struct Surface {             // what the lighting reads
    vec3 albedo;
    float alpha;
    vec3 normal;             // world space; the engine normalizes it after surface()
    float metallic;
    float roughness;         // the engine clamps it to 0.05..1
    float occlusion;
    vec3 emission;
};
struct VertexData {          // vertex(): world space, after instancing and skinning
    vec3 world_pos;
    vec3 world_normal;
    vec4 world_tangent;
    vec2 uv;
    vec4 color;              // the vertex color (white without); what you write here is what `surface()` reads as i.vertex_color
    vec3 object_pos;         // the model-space position; read it, do not write it
};
```

**Engine values.** Everything the engine owns starts with `fa_`; you may read these and nothing else of that prefix:

| Name | Where | Meaning |
|---|---|---|
| `fa_time` | `surface()` and `vertex()` | `vec4`; `fa_time.x` is the seconds of simulated time since the scene started, the engine clock that also steps `SpriteAnimator` and particles. It is deterministic: headless runs and screenshots repeat. A `float` loses sub-millisecond precision after hours of play, so prefer periodic functions (`sin(fa_time.x * 6.2831853 * cyclesPerSecond)`). |
| `fa_camera_pos` | `surface()` only | `vec4`; `.xyz` is the camera position in world space. |
| `fa_tangent_normal(i, n)` | `surface()` | A tangent-space normal `n` (-1..1, e.g. a normal-map texel times 2 minus 1) turned into a world-space normal. Assign it to `s.normal`. |

Params are globals named like the JSON keys (`strength`, `tint.rgb`). Textures are sampled with the **separate** texture
and sampler form: `texture(sampler2D(waves, waves_smp), uv)`; `texture(waves, uv)` is an error with that hint.

**Rules to know before you write:**

- Do not declare a name that starts with `fa_`, define `main`, or write `@` tags: the compile error names the rule.
- `vertex()` runs in the vertex stage: it has no `fa_camera_pos` (a helper that reads it can only be called from
  `surface()` and `light()`) and `texture()` there always reads mip 0 (below).
- `discard` works in `surface()`, but only `"alphaMode": "clip"` also cuts the shadow: use it for holes.
- Gradients (`texture()` derivatives) inside loops or branches are fine in GLSL and refused by HLSL (Windows); use
  `textureLod(sampler2D(t, t_smp), uv, 0.0)` there. `factoria validate` compiles every platform's dialect, so it finds this.
- `vertex()` moves the vertices before lighting and also in the shadow pass, so waves cast the shadow of the waves.
  When the snippet has `vertex()` or the material is `"clip"`, the material also gets its own shadow programs.
- `vertex()` and `surface()` also run in the depth and normal prepass of the effects that read the depth (docs/RENDERING.md, "Depth and
  normals"): a displaced vertex is displaced there, `s.normal` is the normal it stores and, for `"clip"`, the holes are the same.
  Nothing to write for it; the material gets its `prepass` programs when it is compiled.

## Textures in `vertex()`

A texture the material declares can be sampled in `vertex()` as well as in `surface()`: a height map that displaces the
vertices, a flow map that bends grass. Write it the same way, `texture(sampler2D(height, height_smp), v.uv)`; the
engine declares the texture once for each stage and the snippet uses one name for both. Two things differ from the
fragment stage:

- The vertex stage has no derivatives, so `texture()` there reads **mip level 0** (the engine rewrites it to
  `textureLod(..., 0.0)`). Textures with mips (`linear`, `linearRepeat` samplers) still show their sharpest level; use
  `nearest` or `nearestRepeat` when you want exact texels.
- The same `vertex()` runs in the main pass, the shadow pass and the depth and normal prepass, with the same textures, so
  a displaced mesh casts the shadow of its displaced shape and the depth effects see it where it is.

The normal is not recomputed: `v.world_normal` stays the mesh's own. Displace along it and lighting keeps the old
facing, or recompute it from neighbouring samples when the relief is steep. The four-texture limit counts a texture once
even when both stages read it. Example 9 below displaces a plane with a height map.

## Custom lighting

`"lighting": "custom"` hands the shading of every light to your snippet. The engine still chooses the lights, applies
their attenuation and the shadow (the shadow map of the first directional light), adds `s.emission` and the fog; it
calls your function once for each light that reaches the fragment and adds the results:

```glsl
vec3 light(in SurfaceInput i, in Surface s, in LightSample l);        // required: the light that reaches the surface
vec3 ambient(in SurfaceInput i, in Surface s, vec3 ambientColor);     // optional: the ambient term, added once
```

`surface()` runs first, as always, and fills `s` (`s.normal` is the normalized world-space normal it left). Then, per light,
`light()` gets that `s` and a `LightSample`:

```glsl
struct LightSample {
    vec3 direction;     // surface -> light, normalized (for a directional light, the direction its light comes from)
    vec3 color;         // the light's color times intensity times attenuation times shadow: what reaches the surface
    float attenuation;  // 1 for a directional light; for a point or spot light the range falloff (times the spot cone)
    float shadow;       // 1 lit, 0 in shadow (a shadow map of the first directional light only; 1 for every other light)
    float distance;     // surface -> light distance in world units; 0 for a directional light
    int type;           // 0 directional, 1 point, 2 spot
};
```

`l.color` already holds attenuation and shadow, so `s.albedo * l.color * ndl` is a complete Lambert light that is
correctly dark in shadow; `l.attenuation` and `l.shadow` are there for a look that treats them apart (a shadow drawn
as a flat band whatever the light's color). Without `ambient()` the ambient term is the scene's `ambientLight` times
`s.albedo * s.occlusion`; with it, whatever you return (`ambientColor` is `SceneSettings.ambientLight`).

What changes against `"pbr"`: the Cook-Torrance term and the sky reflection are gone (`s.metallic` and `s.roughness`
are still filled, for you to use or ignore), and so is the engine's specular. What stays: `s.emission`, fog,
`"clip"`, `"blend"`, instancing, skinning, shadows and the depth and normal prepass. A `light()` that returns `vec3(0.0)`
leaves only the ambient term.

- The material needs `light()`; without it `shader.compile` stops before the compiler runs, with an error that names the
  material file, shows the signature and says how to go back to `"pbr"`. `light` and `ambient` are entry points only in a
  `"custom"` material (in any other they are ordinary names), and `LightSample` is reserved in all of them.
- `light()` runs once for each light, in the fragment stage, inside a loop. A texture read there needs
  `textureLod(sampler2D(t, t_smp), uv, 0.0)`: a gradient (`texture()`) inside a loop is refused by HLSL (Windows).
  `factoria validate` compiles every platform, so it finds it.
- `gl_FragCoord` is available in `light()` (example 8 uses it). Where its y axis starts (top or bottom of the
  picture) is the graphics API's choice, so a pattern built from it may be mirrored from one platform to another: use
  patterns that look the same mirrored (hatching strokes at 45 degrees in both directions) when that matters.

## Putting a material on an entity

```json
{
  "id": "gem",
  "components": {
    "Transform": { "position": [0, 1, 0] },
    "MeshRenderer": {
      "mesh": "sphere",
      "material": "materials/pulse.material.json",
      "materialParams": { "glow": [1, 0.4, 0.1, 1], "strength": 2.0 }
    }
  }
}
```

`materialParams` overrides the material's defaults for this entity only: a number for a `float`, an array for vectors
and colors, a project-relative image path for a texture. A name the material does not declare, or a value of the wrong
type, logs a warning that lists the right names and the default stays. Edit it like any field: `scene.set_component`
(saved with the scene, undoable in the editor) or, from a script, `entity.get("MeshRenderer").materialParams =
{ strength: 3 }` (a JSON field: assign a whole object, changing a key of the copy you read does nothing).

`color`, `texture`, `normalMap`, `metallic`, `roughness`, `emissive` and `uvScale` still feed the standard surface the
snippet starts from. `unlit: true` forces the unlit lighting. The material's `alphaMode` wins over `color.a < 1`.

**Cost.** Entities with the same mesh and the same material and no overrides are drawn with one instanced draw call. Every
**distinct** `materialParams` value is a batch of its own, so 100 gems that each get a different `strength` are 100 draw
calls; vary the Transform instead, or give a few groups the same value. `play.report` (`factoria run --json`) shows
`materials` (custom materials drawn) and `materialFallbacks` (materials that failed and are drawn magenta; the error log,
`game.logs`, says why). A test checks the same with `game.screenshot(path)` (tests draw nothing until asked) and then
`game.state().renderStats`; `material.info` says in `compile.toolFound` whether this computer can compile materials.

## Color space

With `SceneSettings.colorSpace` `"linear"` ([RENDERING.md](RENDERING.md), "Color space") the shader works in linear light:
the colour `surface()` starts from (`albedo`: the tint and the texture) arrives already converted, and what `surface()`
returns (`albedo`, `emission`) is taken as linear light, so a number you type in the snippet is not an sRGB value. A colour
**param** is passed as you wrote it in the material file or in `materialParams` (sRGB, like every colour you pick): convert it
in the snippet when the scene may be linear (`pow(c, vec3(2.2))` is close enough). A texture you sample yourself gives what the GPU
holds: linear light when it was first loaded in a linear scene, the file's own numbers otherwise. In a gamma scene nothing changes.

## Node graphs

A material can be built from nodes instead of GLSL. Add a `"graph"` to the `.material.json` and `material.graph.generate`
writes the snippet named by `shader` from it, so a graph and the code stay one document: the generated GLSL is plain, readable
text (one line per node, with a comment naming the node id) that compiles through the same path as a hand-written snippet
(`shader.compile`, `factoria validate`, hot reload, export). A graph needs no editor: an AI or a person writes the JSON, and
the editor's Graph panel (View > Graph, [EDITOR.md](EDITOR.md)) edits the same JSON and runs the same commands, so both can take turns on one file.

```json
"graph": {
  "nodes": [
    { "id": "noise",  "type": "noise.fbm", "pos": [0, 0],     "inputs": { "scale": 6.0 } },
    { "id": "amount", "type": "param",     "pos": [0, 120],   "param": "dissolve" },
    { "id": "burn",   "type": "dissolve",  "pos": [220, 60],  "inputs": { "edgeWidth": 0.06, "edgeColor": [1.0, 0.4, 0.1] } },
    { "id": "out",    "type": "output",    "pos": [440, 60],  "inputs": { "albedo": [0.6, 0.6, 0.65], "roughness": 0.7 } }
  ],
  "links": [
    { "from": "noise.value", "to": "burn.noise" },
    { "from": "amount.value", "to": "burn.threshold" },
    { "from": "burn.alpha", "to": "out.alpha" },
    { "from": "burn.emission", "to": "out.emission" }
  ]
}
```

(with `"alphaMode": "clip"` and a float param `dissolve` in the same material; `material.graph.nodes` returns a complete example.)

- **Nodes.** `id` (unique; a letter, then letters, digits and single `_`), `type`, `pos` (`[x, y]`, where the editor draws
  it; the snippet does not depend on it), `inputs` (constants for inputs without a link: a number, or an array of 2 to 4
  numbers) and, for the nodes that need one, `param` or `texture` (the name of one of the material's own `params` or
  `textures`: they stay normal params and textures, so `material.info`, `MeshRenderer.materialParams` and the inspector
  work as for any material). An input with neither a link nor a constant reads its default (`material.graph.nodes` lists
  it; `$uv` means the mesh's uv). One node of type `output` sets the fields of the surface: `albedo`, `alpha`, `emission`,
  `metallic`, `roughness`, `occlusion`, `normal` or `tangentNormal` (a normal map; not both) and `vertexOffset` (world-space
  offset written into `vertex()`). A field that is neither linked nor set keeps what the MeshRenderer gave.
- **Links.** `"from": "nodeId.output"`, `"to": "nodeId.input"`; an input takes one link. Types are `float`, `vec2`, `vec3`,
  `vec4`: a float widens to any size by itself, anything else needs `math.split` and `math.combine`. Math nodes take a float or
  a vector (the size their linked inputs agree on).
- **`editor` and `version`.** The graph takes an optional `"version"` (the format; 1 today, anything else is refused) and the
  graph and each node an optional `"editor"` object, where the Graph panel keeps what only it needs (the view's zoom and
  pan, comments), which only has to be an object. The generator never reads `editor`, so it does not change the snippet or the
  hash, and the commands keep it as written.
- **Library** (`material.graph.nodes` has every input, output and doc): constants (`const.float`, `const.vec2`, `const.vec3`,
  `const.vec4`, `const.color`), `param`, `uv`, `time`, `vertex.color`, `position.world`, `position.view`, `normal.world`,
  `view.dir`, `texture`, `texture.normal`, `triplanar`, `parallax` (occlusion mapping), math (`add`, `sub`, `mul`, `div`, `min`,
  `max`, `pow`, `lerp`, `clamp`, `saturate`, `smoothstep`, `step`, `abs`, `fract`, `sin`, `oneminus`, `dot`, `length`,
  `normalize`, `split`, `combine`), noise (`noise.value`, `noise.gradient`, `noise.voronoi`, `noise.fbm`), effects (`dissolve`,
  `flow`, `fresnel`) and `output`. Noise helpers are plain GLSL functions named `gn_...`, pasted into the snippet only when a
  node uses them.
- **Where a node can go.** Nodes that sample a texture or read the view direction (`texture`, `texture.normal`, `triplanar`,
  `parallax`, `view.dir`, `position.view`, `fresnel`) run in `surface()` only: they may not feed `vertexOffset` (the vertex
  stage has no textures; see "Not available yet"). Each node lists the material kinds it works in; graphs are generated for
  materials of kind `mesh` (today's only kind).
- **Commands.** `material.graph.nodes` (the library), `material.graph.validate {material}` (every problem with its JSON
  pointer, what is wrong and the fix: unknown node type with a "did you mean", a link to a node or port that does not exist,
  a type mismatch, a cycle, a missing output, a node used in the vertex path that needs the fragment stage), and
  `material.graph.generate {material, force?, dryRun?}`, which writes the snippet and `graphHash`. Run `shader.compile`
  afterwards. Both also take `graph` (a graph object) in place of the one the file holds, to check a graph that is not saved yet, or to
  store it in the material and generate from it in one call (the Graph panel's problems list and Save work this way). A param or texture name that starts with `gn_`
  is refused: the generator keeps that prefix for its GLSL helper functions.

**The hand-edit rule.** `graphHash` is the SHA-256 of the snippet the generator wrote (line endings ignored). When you
generate again, the command first compares the snippet on disk with it: if they differ, someone edited the generated code
by hand (or the file was never generated), and the command refuses and changes nothing, because the edit would be lost. Then
either pass `force: true` to overwrite the snippet with the graph's code, or delete `graph` and `graphHash` from the
material to keep the hand-written code as a normal snippet. A snippet that is still what the previous graph made is simply
updated. The generator also rewrites the material file (2-space JSON) to store the hash; the graph itself is kept as written.

## Errors you will see

Every error says where, what is wrong and how to fix it.

- **The material file:** a JSON pointer, e.g. `/params/strength/default: expected a number, got "2"`. Unknown keys and
  enum values get "did you mean". More than 4 textures, more than 16 params, a `fa_` name, a missing `doc`, a missing
  snippet file: each error states the rule and the fix.
- **The snippet:** `shaders/pulse.surface.glsl:7:12` with the line quoted, mapped from the compiler's message to your
  file, once per mistake. Frequent mistakes have a hint: `s.colour` says `did you mean albedo?` and lists the fields; a
  param written with a typo says `did you mean strength?` and lists the material's names; `texture(waves, uv)` shows the
  `sampler2D(waves, waves_smp)` form; a missing `surface()` shows the signature, and so does a missing `light()` in a
  `"custom"` material (the error names the material file); a field written without its struct says `write s.albedo`
  (`l.colour` in `light()` says `did you mean color?` and lists the fields of `LightSample`).
- **At run time** a material that does not compile is drawn with the **error material**: unlit magenta, so a screenshot
  shows at once which mesh is wrong, and the log says why. After a hot reload with a broken edit the previous version
  stays in use and the error is logged once.

## Compiler, hot reload, validate and export

- **sokol-shdc** is the compiler (a pinned build). The factoria downloads carry it next to `factoria`, so there is
  nothing to install. It is looked up in `$SOKOL_SHDC`, next to the `factoria` executable, then in `~/.factoria/tools`,
  where `factoria setup shaders` installs it (about 11 MB) for a factoria built from source or when the copy next to
  `factoria` is gone; `factoria setup` says which one is used. On Windows, Windows Defender may quarantine
  `sokol-shdc.exe` as a false positive (`Trojan:Win32/Bearfoos.B!ml`): restore it from Windows Security > Protection
  history, run `factoria setup shaders`, or point `SOKOL_SHDC` at a copy you trust ([EXPORTING.md](exporting/EXPORTING_SETUP.md#setting-up-this-computer)).
  Without it, `factoria validate` checks the material files and warns that snippets were not compiled.
- **Running** (`factoria run`, MCP sessions) compiles the material for this computer's graphics API the first time it is
  drawn and caches the result in `.factoria/shader-cache`, so an unchanged material starts no process.
- **Hot reload:** saving the material, its snippet or a texture gives the new look in a moment, in `factoria run`, MCP
  sessions and the editor (while editing and while playing, [EDITOR.md](EDITOR.md)).
- **`factoria validate`** compiles every material for every platform (Windows, Linux, macOS, iOS, Android, web): some
  mistakes exist in one platform's dialect only.
- **`factoria export`** compiles the platform's dialects and ships them next to the material as
  `materials/<name>.material.json.<dialect>.shader`; the `.glsl` snippet is not shipped and the game contains no compiler.
  A material that does not compile stops the export with the same errors. See [EXPORTING.md](EXPORTING.md).

## Worked examples

Each example is a material file plus a snippet; the test suite compiles them all, so they are known to work. Put the
snippet's path in the material's `shader` and the material's path on an entity as shown above.

### 1. Pulsing emission (`fa_time`)

File `materials/pulse.material.json`:

```json
{
  "format": "factoria.material/1",
  "doc": "A glow that breathes: emission scaled by a sine of the game time.",
  "shader": "shaders/pulse.surface.glsl",
  "params": {
    "glow": { "type": "color", "default": [1.0, 0.45, 0.1, 1.0], "doc": "Color of the glow." },
    "strength": { "type": "float", "default": 1.5, "min": 0.0, "max": 8.0, "doc": "Peak emission brightness." },
    "speed": { "type": "float", "default": 0.5, "min": 0.0, "max": 5.0, "doc": "Pulses per second." }
  }
}
```

File `shaders/pulse.surface.glsl`:

```glsl
void surface(in SurfaceInput i, inout Surface s) {
    float wave = 0.5 + 0.5 * sin(fa_time.x * speed * 6.2831853);
    s.emission += glow.rgb * (strength * wave);
}
```

### 2. Dissolve with `"clip"` (procedural noise)

`"clip"` discards fragments whose `s.alpha` is below `alphaCutoff` (0.5), in the shadow too, so the holes cast no
shadow. Animate `amount` from a script from 0 (whole) to 1 (gone). With a noise texture instead of the hash, declare it in
`textures` (name it `mask`, not `noise`: sokol-shdc cannot compile a texture called `noise`, and the material is refused) and
use `texture(sampler2D(mask, mask_smp), i.uv).r` as `n`.

File `materials/dissolve.material.json`:

```json
{
  "format": "factoria.material/1",
  "doc": "Burns away along a noise pattern; the edge of the hole glows.",
  "shader": "shaders/dissolve.surface.glsl",
  "alphaMode": "clip",
  "doubleSided": true,
  "params": {
    "amount": { "type": "float", "default": 0.0, "min": 0.0, "max": 1.0, "doc": "How much is gone: 0 whole, 1 nothing left." },
    "edgeColor": { "type": "color", "default": [1.0, 0.5, 0.1, 1.0], "doc": "Color of the glowing edge." },
    "edgeWidth": { "type": "float", "default": 0.08, "min": 0.0, "max": 0.5, "doc": "Width of the glowing edge, in noise units (0..1)." },
    "scale": { "type": "float", "default": 6.0, "min": 1.0, "max": 40.0, "doc": "Size of the noise: noise cells per UV unit." }
  }
}
```

File `shaders/dissolve.surface.glsl`:

```glsl
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

float value_noise(vec2 p) {
    vec2 c = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(c), hash(c + vec2(1.0, 0.0)), f.x),
               mix(hash(c + vec2(0.0, 1.0)), hash(c + vec2(1.0, 1.0)), f.x), f.y);
}

void surface(in SurfaceInput i, inout Surface s) {
    float n = value_noise(i.uv * scale);
    s.alpha = n < amount ? 0.0 : 1.0;                       // below alphaCutoff (0.5): discarded
    float edge = 1.0 - smoothstep(0.0, max(edgeWidth, 0.001), n - amount);
    s.emission += edgeColor.rgb * edge * 3.0;
}
```

### 3. Scrolling water (UV scroll)

A tileable tangent-space normal map scrolls with `fa_time`. Supply your own image at the default path (or override
`ripples` per entity). Use a `plane` mesh.

File `materials/water.material.json`:

```json
{
  "format": "factoria.material/1",
  "doc": "Translucent water: a normal map scrolls over a tinted, glossy surface.",
  "shader": "shaders/water.surface.glsl",
  "alphaMode": "blend",
  "params": {
    "tint": { "type": "color", "default": [0.05, 0.3, 0.45, 0.8], "doc": "Water color; alpha is its opacity." },
    "flow": { "type": "vec2", "default": [0.04, 0.02], "doc": "Scroll speed of the ripples, UV per second." },
    "tiling": { "type": "float", "default": 4.0, "min": 0.1, "max": 50.0, "doc": "How many times the ripples repeat across the mesh." }
  },
  "textures": {
    "ripples": { "default": "textures/water_ripples.png", "sampler": "linearRepeat", "doc": "Tileable tangent-space normal map (rgb)." }
  }
}
```

File `shaders/water.surface.glsl`:

```glsl
void surface(in SurfaceInput i, inout Surface s) {
    vec2 uv = i.uv * tiling + flow * fa_time.x;
    vec3 n = texture(sampler2D(ripples, ripples_smp), uv).xyz * 2.0 - 1.0;
    s.normal = fa_tangent_normal(i, n);
    s.albedo = tint.rgb;
    s.alpha = tint.a;
    s.metallic = 0.0;
    s.roughness = 0.08;
}
```

### 4. Wind on grass (`vertex()`)

`vertex()` moves the vertices in world space; the tip sways, the root stays. For a `quad` mesh (1 x 1 in XY, centered) the
root is at `object_pos.y = -0.5`, hence the `+ 0.5`. Scale the entity to a blade (`[0.3, 1, 1]`). The shadow follows the
sway. This `vertex()` reads params and `fa_time`; example 9 reads a texture.

File `materials/grass.material.json`:

```json
{
  "format": "factoria.material/1",
  "doc": "Grass blades that sway in the wind: the tips move, the roots stay.",
  "shader": "shaders/grass.surface.glsl",
  "doubleSided": true,
  "params": {
    "root": { "type": "color", "default": [0.08, 0.25, 0.05, 1.0], "doc": "Color at the root of the blade." },
    "tip": { "type": "color", "default": [0.45, 0.75, 0.2, 1.0], "doc": "Color at the tip of the blade." },
    "sway": { "type": "float", "default": 0.25, "min": 0.0, "max": 2.0, "doc": "How far the tips move, in meters." },
    "windSpeed": { "type": "float", "default": 1.6, "min": 0.0, "max": 10.0, "doc": "Radians per second of the sway." }
  }
}
```

File `shaders/grass.surface.glsl`:

```glsl
void vertex(inout VertexData v) {
    float h = clamp(v.object_pos.y + 0.5, 0.0, 1.0);              // 0 at the root of the blade, 1 at its tip
    float phase = v.world_pos.x * 0.7 + v.world_pos.z * 0.5;      // neighbours sway out of step
    v.world_pos.x += sin(fa_time.x * windSpeed + phase) * sway * h * h;
}

void surface(in SurfaceInput i, inout Surface s) {
    s.albedo = mix(root.rgb, tip.rgb, 1.0 - i.uv.y);
}
```

(On a `quad`, `uv.y` is 1 at the bottom edge and 0 at the top, hence `1.0 - i.uv.y`; `surface()` has no `object_pos`, so
with another mesh derive the blade height from its UVs.)

### 5. Rim light

Brightens the silhouette: the more a surface faces away from the camera, the more it glows.

File `materials/rim.material.json`:

```json
{
  "format": "factoria.material/1",
  "doc": "Adds a colored glow on the edges of the mesh, seen from the camera.",
  "shader": "shaders/rim.surface.glsl",
  "params": {
    "rimColor": { "type": "color", "default": [0.3, 0.7, 1.0, 1.0], "doc": "Color of the edge glow." },
    "rimPower": { "type": "float", "default": 3.0, "min": 0.5, "max": 8.0, "doc": "Sharpness: higher keeps the glow thinner." },
    "rimStrength": { "type": "float", "default": 1.2, "min": 0.0, "max": 5.0, "doc": "Brightness of the glow." }
  }
}
```

File `shaders/rim.surface.glsl`:

```glsl
void surface(in SurfaceInput i, inout Surface s) {
    float facing = clamp(dot(normalize(s.normal), i.view_dir), 0.0, 1.0);
    float rim = pow(1.0 - facing, rimPower);
    s.emission += rimColor.rgb * (rim * rimStrength);
}
```

### 6. Two-band toon (`"custom"` lighting)

`light()` is called once for each light; the engine has already put the light's color, attenuation and shadow into
`l.color`. Here a surface facing the light more than `threshold` gets the full light and the rest gets `shade` of it, so
the sphere shows exactly two tones, and a shadow falls as a flat dark band.

File `materials/toon.material.json`:

```json
{
  "format": "factoria.material/1",
  "doc": "Cel shading with two bands: lit and shaded, with a hard edge between them.",
  "shader": "shaders/toon.surface.glsl",
  "lighting": "custom",
  "params": {
    "threshold": { "type": "float", "default": 0.5, "min": 0.0, "max": 1.0, "doc": "Dot product of normal and light direction above which the surface is lit." },
    "shade": { "type": "float", "default": 0.35, "min": 0.0, "max": 1.0, "doc": "Brightness of the shaded band, as a fraction of the lit one." }
  }
}
```

File `shaders/toon.surface.glsl`:

```glsl
void surface(in SurfaceInput i, inout Surface s) {}

vec3 light(in SurfaceInput i, in Surface s, in LightSample l) {
    float band = dot(s.normal, l.direction) > threshold ? 1.0 : shade;
    return s.albedo * l.color * band;
}
```

### 7. Cel bands from a ramp texture (`ambient()`)

The band is a texel of a ramp image: paint the ramp (one row, left = facing away, right = facing the light, `nearest`
sampler for hard steps) and the lighting follows it. `ambient()` keeps the shaded side from going black. Read the ramp
with `textureLod`, because `light()` runs in a loop.

File `materials/ramp.material.json`:

```json
{
  "format": "factoria.material/1",
  "doc": "Cel shading whose bands come from a ramp image.",
  "shader": "shaders/ramp.surface.glsl",
  "lighting": "custom",
  "params": {
    "ambientAmount": { "type": "float", "default": 0.6, "min": 0.0, "max": 2.0, "doc": "How much of the scene's ambient light the surface keeps." }
  },
  "textures": {
    "ramp": { "default": "textures/ramp.png", "sampler": "nearest", "doc": "Light ramp: the red channel is the brightness, left = facing away from the light, right = facing it." }
  }
}
```

File `shaders/ramp.surface.glsl`:

```glsl
void surface(in SurfaceInput i, inout Surface s) {}

vec3 light(in SurfaceInput i, in Surface s, in LightSample l) {
    float ndl = dot(s.normal, l.direction) * 0.5 + 0.5;     // -1..1 -> 0..1
    float band = textureLod(sampler2D(ramp, ramp_smp), vec2(ndl, 0.5), 0.0).r;
    return s.albedo * l.color * band;
}

vec3 ambient(in SurfaceInput i, in Surface s, vec3 ambientColor) {
    return ambientColor * s.albedo * (s.occlusion * ambientAmount);
}
```

### 8. Screen-space hatching

Strokes drawn on the picture, not on the mesh: the less a surface faces the light, the more strokes cross it (none
when it is lit, one set in the half shade, two crossing sets in the full shade). The strokes are 45 degrees in both directions, so a platform that puts the origin of `gl_FragCoord` at
the other corner draws the same picture mirrored.

File `materials/hatch.material.json`:

```json
{
  "format": "factoria.material/1",
  "doc": "Ink hatching: one set of strokes in the half shade, a crossing set in the full shade.",
  "shader": "shaders/hatch.surface.glsl",
  "lighting": "custom",
  "params": {
    "spacing": { "type": "float", "default": 8.0, "min": 2.0, "max": 40.0, "doc": "Distance between strokes, in pixels of the picture." }
  }
}
```

File `shaders/hatch.surface.glsl`:

```glsl
void surface(in SurfaceInput i, inout Surface s) {}

vec3 light(in SurfaceInput i, in Surface s, in LightSample l) {
    float ndl = clamp(dot(s.normal, l.direction), 0.0, 1.0);
    vec2 p = gl_FragCoord.xy / spacing;
    float paper = 1.0;
    if (ndl < 0.6) paper = min(paper, step(0.3, fract(p.x + p.y)));    // first set of strokes
    if (ndl < 0.3) paper = min(paper, step(0.3, fract(p.x - p.y)));    // crossing set
    return s.albedo * l.color * paper;
}
```

### 9. Height map displacement (a texture in `vertex()`)

A grayscale image lifts a mesh into relief. `vertex()` and `surface()` read the same texture; the shadow follows the
displaced shape. The mesh needs enough vertices to show the relief: a grid made with `mesh.create()` or an imported
model works, the built-in `plane` has only four vertices and just lifts its corners.

File `materials/relief.material.json`:

```json
{
  "format": "factoria.material/1",
  "doc": "Displaces the vertices upward by a height map and darkens the low ground.",
  "shader": "shaders/relief.surface.glsl",
  "params": {
    "height": { "type": "float", "default": 1.0, "min": 0.0, "max": 10.0, "doc": "Meters a white texel lifts a vertex." }
  },
  "textures": {
    "heightMap": { "default": "textures/height.png", "sampler": "linearRepeat", "doc": "Height map: the red channel, 0 = ground level, 1 = full height." }
  }
}
```

File `shaders/relief.surface.glsl`:

```glsl
void vertex(inout VertexData v) {
    float h = texture(sampler2D(heightMap, heightMap_smp), v.uv).r;      // always mip 0 in vertex()
    v.world_pos.y += h * height;
}

void surface(in SurfaceInput i, inout Surface s) {
    float h = texture(sampler2D(heightMap, heightMap_smp), i.uv).r;
    s.albedo *= mix(0.5, 1.0, h);
}
```

## Materials on sprites, shapes, tiles, text and particles

`"kind": "sprite"` makes a material for the 2D quad pipeline: everything the engine draws as textured or shaded quads
(`Sprite`, `Shape2D`, `Tilemap`, `Text` glyphs, particles and trails, UI images). The file, the params, the textures, the
compiler, the cache, `factoria validate` and `factoria export` are the ones described above; the snippet and what it
starts from differ.

**Which components take a material.** `Sprite`, `Shape2D`, `Tilemap`, `Text`, `ParticleEmitter` and every UI widget
(`UiBox`: Panel, Button, Toggle, Slider, TextField, ScrollList, TouchStick, TouchButton, Captions, Chart, CameraView, Video)
have the fields `material` and `materialParams`. What each one covers:

| Component | The material draws | One material per | Stays on the built-in shader |
|---|---|---|---|
| `Sprite` | the sprite's quad (a sprite mesh or a skin included) | sprite | |
| `Shape2D` | the shape (`i.mode` 7 for the rounded rectangle, circle, outline and gradient, 1 and 2 for the others) | shape | |
| `Tilemap` | every tile | Tilemap: all its tiles draw as one batch; a second layer with another material is another Tilemap | |
| `Text` | the glyph quads (`i.mode` 4); the glyph atlas is the main texture, so `fa_sample_main(uv)` returns glyph coverage | Text | the pictures of a rich text (`[icon:name]`) |
| `ParticleEmitter` | every particle and its trail (a sub-emitter group uses its own emitter's material) | emitter: all its particles batch together | |
| UI widgets | the **background** only: `texture` as a 9-slice, or the solid `color` rectangle | widget | the label of a Button, Toggle or TextField, the Button icon, the Slider knob and fill, the Toggle mark, the caret and focus ring, the bars and lines of a Chart, the picture of a Video or CameraView, the Captions text, a TouchStick or TouchButton disc and knob (its background only when it has a `texture`), the tooltip |

UI text is drawn through the same glyph quads as `Text`, but only the `Text` component has `material` for them.

Check a material on any of these with `shader.compile` and `factoria validate`; `material.info` lists its params.

**What the renderer does with a sprite material.** Sprites with the same material and equal param values share a draw call;
a different value, another material or a sprite without one starts a new batch (the draw order is the same as without
materials). `fa_time` is the engine clock and `fa_target` the size of the render target (the image the pass draws into, which is the
camera's rectangle, not the whole screen, in the coverage pass of the sprite outline effect), in both programs. The 2D quads of a frame look their material up once
per distinct material and set of `materialParams` values, not once per component, quad or particle (`materialResolves` in the render stats and in `game.render_stats` counts the lookups). A material whose params name a render target (`"mask": "target:page"`) is looked up again for the camera that renders into that target, which gets the missing-texture checker instead of the image it is writing, and its items are not copied between cameras. A material that
did not build, or that is not of kind `"sprite"`, draws the sprite in magenta (its alpha stays) with the engine's own shader
and logs the compile error once; the error log (`game.logs`) says why, `materialFallbacks` in the render stats names it, and the previous version of a
material stays in use when a hot reload of its shader fails.

**The snippet** is plain GLSL 450 like the mesh one, with these entry points:

- `void fragment(in QuadInput i, inout QuadSurface s)` (**required**), run per fragment.
- `void vertex(inout QuadVertex v)` (optional), run per vertex, before the transform to the screen.

```glsl
struct QuadInput {              // read-only, per fragment
    vec2 uv;                    // texture coordinates (atlas coordinates for a sprite of a sheet); modes 1, 2, 3, 7: the position in the shape's box, [-1,1] covers it
    vec4 color;                 // the tint (vertex colour: linear in a linear scene)
    vec2 world_pos;             // world position (x, y) of the fragment
    vec2 screen_uv;             // position in the render target, 0..1, y running DOWN on every backend
    float time;                 // seconds of game time (the same as fa_time.x)
    float mode;                 // what is drawn: 0 texture, 1 circle, 2 ring, 3 soft particle, 4 glyph, 5/6 lit, 7 SDF shape
    vec4 custom;                // reserved: zero for now
};
struct QuadSurface { vec4 color; };                      // straight (not premultiplied) RGBA
struct QuadVertex { vec3 world_pos; vec2 uv; vec4 color; };
```

**What `s.color` holds.** `fragment()` arrives with `s.color` already holding what the engine would draw for the item,
so an empty `fragment()` draws exactly the engine's own pixels, and a snippet changes only what it needs:

| `i.mode` | `s.color` on arrival |
|---|---|
| 0 | the main texture times the tint |
| 1, 2, 3 | the circle, the ring or the soft particle: tint colour, the alpha holding the coverage |
| 4 | a glyph: the tint, the alpha holding the glyph's coverage |
| 5, 6 (and the `+16` modes of lit items) | the picture already shaded by the 2D lights |
| 7 | the rounded rectangle, circle, outline or gradient of a `Shape2D` (its coverage, gradient and dithering included) |

What `fragment()` leaves in `s.color` goes through the engine's last steps: the `flash` of [GAME_FEEL.md](GAME_FEEL.md),
the conversion of a `multiply` blend and the fog. `fa_sample_main(uv)` samples the item's main texture in the colour space
of the scene (for a snippet that wants to look the picture up somewhere else); `fa_scene_rgb(c)` takes an sRGB colour of
yours (a param of type `color`) to the scene's colour space. `fa_time` and the names of the engine's own 2D program are the
engine's: a sprite material is refused (error at `/params/<name>` or `/textures/<name>`, with a rename suggestion) when a
param or texture takes one of them. That is every unprefixed name of `quad_common.glsl`, `color_space.glsl` and
`light_shadow.glsl`: the vertex inputs and varyings (`position`, `color`, `uv`, `params`, `xform`...), the textures and
samplers (`tex`, `smp`, `normal_tex`, `light_tex`...), the uniform blocks and their members (`lit`, `ambient`,
`light_pos`...) and the helper functions (`tex_color`, `shape_color`, `scene_rgb`, `light_shadow`...), plus `fragment`,
`QuadInput`, `QuadSurface` and `QuadVertex`. (A mesh material may have a `color` param; the sprite program already has
one.) A snippet's own variables and functions must avoid them too: the compiler's hint then says the name is taken by
the engine's 2D program.

**The lean program.** The renderer draws a batch of plain textured quads (no lights, no multiply, nothing but mode 0)
with a lean program, `quad_plain`; every other batch uses `quad`. Both compile from your snippet, so `fragment()` must
not depend on anything the lean program has not: `i.mode` is 0 in it.

**Slots.** The engine's own bindings come first, so a material's textures start after them: sampler and texture views
0 to 3 (`tex`, `normal_tex`, `light_tex`, `shadow_tex`) and samplers 0 to 2 are the engine's; your textures are views 4
to 7 and samplers 3 to 6 (at most 4 textures, as for a mesh), the params block is binding 5 (4 in the vertex stage). A
mesh material starts at view 6 and sampler 2: the numbers are not interchangeable, but `kind` decides them and you never
write them. The slots are listed in `engine/render/src/render_internal.h` (`kMaterialSpriteFirstView`).

**What is different from a mesh material.**

- `alphaMode: "clip"` is an error: a sprite is always blended by the engine. Write `if (s.color.a < 0.5) discard;` where
  you want a cut-out. `lighting` `"pbr"` and `"unlit"` and `doubleSided` mean nothing here and are ignored; `"custom"` is an
  error (there is no `light()` hook in the 2D pipeline).
- `vertex()` cannot sample a texture of the material (a mesh material's can, see "Textures in `vertex()`"): the 2D pipeline
  binds a material's textures to the fragment stage only, and the compiler says so.
- The compiled twin carries `programs.quad` and `programs.quad_plain` and the key `"kind": "sprite"`; its `template` is
  the hash of the sprite template (a change of the template recompiles sprite materials only).
- Errors name `fragment()` and `QuadInput`: `i.colour` says `did you mean color?` and lists the fields.

### 10. Dissolve and hit flash on a sprite

A noise dissolve that glows along its edge (`amount`: 0 whole, 1 gone) and a flash to white (`flash`: 0 none, 1 white),
both driven from a script as the game wants. The snippet starts from what the sprite would draw, so the picture, the
tint and the lights of the sprite keep working.

File `materials/sprite-dissolve.material.json`:

```json
{
  "format": "factoria.material/1",
  "kind": "sprite",
  "doc": "A sprite that burns away along a noise pattern, with a flash to white for hits.",
  "shader": "shaders/sprite-dissolve.fragment.glsl",
  "params": {
    "amount": { "type": "float", "default": 0.0, "min": 0.0, "max": 1.0, "doc": "How much is gone: 0 whole, 1 nothing left." },
    "edgeColor": { "type": "color", "default": [1.0, 0.5, 0.1, 1.0], "doc": "Color of the glowing edge." },
    "edgeWidth": { "type": "float", "default": 0.08, "min": 0.0, "max": 0.5, "doc": "Width of the glowing edge, in noise units (0..1)." },
    "flash": { "type": "float", "default": 0.0, "min": 0.0, "max": 1.0, "doc": "Hit flash: 0 none, 1 the whole sprite white." },
    "scale": { "type": "float", "default": 8.0, "min": 1.0, "max": 60.0, "doc": "Size of the noise: noise cells per UV unit." }
  }
}
```

File `shaders/sprite-dissolve.fragment.glsl`:

```glsl
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

float value_noise(vec2 p) {
    vec2 c = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(c), hash(c + vec2(1.0, 0.0)), f.x),
               mix(hash(c + vec2(0.0, 1.0)), hash(c + vec2(1.0, 1.0)), f.x), f.y);
}

void fragment(in QuadInput i, inout QuadSurface s) {
    float n = value_noise(i.uv * scale);
    if (n < amount) discard;
    float edge = 1.0 - smoothstep(0.0, max(edgeWidth, 0.001), n - amount);
    s.color.rgb = mix(s.color.rgb, fa_scene_rgb(edgeColor.rgb), edge * step(0.001, amount));
    s.color.rgb = mix(s.color.rgb, vec3(1.0), flash);
}
```

A texture works as for a mesh material, sampled with `texture(sampler2D(mask, mask_smp), i.uv)`; name it anything but
a name of the engine's program (`tex`, `smp`, `normal_tex`... are refused).

## Not available yet

- **Full vertex and fragment shaders** (your own `main`, your own vertex layout, several passes): the snippet always
  runs inside the engine's mesh or quad shader.
- **Your own light loop** (which lights are chosen, how many, their order, the shadow map): `"custom"` lighting only
  shades each light the engine hands over. Image-based lighting (the sky reflection) is off in a custom material and
  cannot be called from `light()`.
- Materials for the sky and post-processing; compute shaders; textures sampled in the `vertex()` of a sprite material (a mesh
  material can); one instanced draw with a different value per instance.

If a game needs one of these, write it in the game's `ENGINE_FEEDBACK.json` (see [ENGINE_FEEDBACK.md](ENGINE_FEEDBACK.md)):
that is how it gets built.
