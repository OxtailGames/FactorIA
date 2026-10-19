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

`MeshRenderer.material` and `MeshRenderer.materialParams` are in [COMPONENTS.md](COMPONENTS.md); the file format is
`schemas/material.schema.json`.

## The material file

`materials/<name>.material.json` (format `factoria.material/1`):

| Key | Meaning |
|---|---|
| `format` | Always `"factoria.material/1"`. Required. |
| `shader` | Project-relative path of the snippet, e.g. `"shaders/pulse.surface.glsl"`. Required. |
| `doc` | What the material looks like and is for. Shown by `material.info`. |
| `lighting` | `"pbr"` (default): the engine's lighting, fog and sky reflection. `"unlit"`: the surface albedo is drawn as it is, plus emission and fog. |
| `alphaMode` | `"opaque"` (default): alpha is ignored. `"clip"`: fragments with `alpha` below `alphaCutoff` are discarded, also in the shadow pass. `"blend"`: drawn with the blended meshes, far to near. |
| `doubleSided` | `true` draws back faces too. Default `false`. |
| `params` | Typed parameters the snippet reads (below). |
| `textures` | Textures the snippet samples (below). |

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
most **4 textures**; pack masks into the channels of one image. Textures are read in `surface()`, not in `vertex()`.

**Names.** Params and textures share one namespace. A name is a GLSL identifier, must not start with `fa_` (the engine's
prefix), must not be a GLSL keyword or one of `main`, `surface`, `vertex`, `Surface`, `SurfaceInput`, `VertexData`, and a
texture `x` also takes `x_smp`.

**`alphaCutoff`.** `"alphaMode": "clip"` adds the float param `alphaCutoff` (default 0.5, range 0..1) by itself: the
engine runs `surface()` and discards the fragment when `s.alpha < alphaCutoff`. Declare `alphaCutoff` yourself (as a
`float`) only to change its default, range or doc.

## The snippet

A plain GLSL 450 file (Vulkan style, what sokol-shdc reads), with no `@` tags and no `main`. It defines:

- `void surface(in SurfaceInput i, inout Surface s)` (**required**), run per fragment.
- `void vertex(inout VertexData v)` (optional), run per vertex.

Both may be preceded by your own helper functions (they compile in both stages). `surface()` arrives with `s` already
filled with what a plain `MeshRenderer` would draw (texture times color, normal map, metallic/roughness/occlusion maps,
emissive), so change only what you need: a pulse is two lines and keeps working with the entity's `color`, `texture`
and glTF materials.

```glsl
struct SurfaceInput {        // read-only, per fragment
    vec3 world_pos;
    vec3 world_normal;       // interpolated geometric normal, normalized, flipped on back faces
    vec4 world_tangent;      // xyz tangent, w handedness
    vec2 uv;                 // after MeshRenderer.uvScale
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
- `vertex()` runs in the vertex stage: it cannot sample textures (an error) and has no `fa_camera_pos`. A helper that
  does either can only be called from `surface()`.
- `discard` works in `surface()`, but only `"alphaMode": "clip"` also cuts the shadow: use it for holes.
- Gradients (`texture()` derivatives) inside loops or branches are fine in GLSL and refused by HLSL (Windows); use
  `textureLod(sampler2D(t, t_smp), uv, 0.0)` there. `factoria validate` compiles every platform's dialect, so it finds this.
- `vertex()` moves the vertices before lighting and also in the shadow pass, so waves cast the shadow of the waves.
  When the snippet has `vertex()` or the material is `"clip"`, the material also gets its own shadow programs.

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

## Errors you will see

Every error says where, what is wrong and how to fix it.

- **The material file:** a JSON pointer, e.g. `/params/strength/default: expected a number, got "2"`. Unknown keys and
  enum values get "did you mean". More than 4 textures, more than 16 params, a `fa_` name, a missing `doc`, a missing
  snippet file: each error states the rule and the fix.
- **The snippet:** `shaders/pulse.surface.glsl:7:12` with the line quoted, mapped from the compiler's message to your
  file, once per mistake. Frequent mistakes have a hint: `s.colour` says `did you mean albedo?` and lists the fields; a
  param written with a typo says `did you mean strength?` and lists the material's names; `texture(waves, uv)` shows the
  `sampler2D(waves, waves_smp)` form; a missing `surface()` shows the signature; a field written without its struct
  says `write s.albedo`.
- **At run time** a material that does not compile is drawn with the **error material**: unlit magenta, so a screenshot
  shows at once which mesh is wrong, and the log says why. After a hot reload with a broken edit the previous version
  stays in use and the error is logged once.

## Compiler, hot reload, validate and export

- **sokol-shdc** is the compiler (a pinned build). The factoria downloads carry it next to `factoria`, so there is
  nothing to install. It is looked up in `$SOKOL_SHDC`, next to the `factoria` executable, then in `~/.factoria/tools`,
  where `factoria setup shaders` installs it (about 11 MB) for a factoria built from source or when the copy next to
  `factoria` is gone; `factoria setup` says which one is used. On Windows, Windows Defender may quarantine
  `sokol-shdc.exe` as a false positive (`Trojan:Win32/Bearfoos.B!ml`): restore it from Windows Security > Protection
  history, run `factoria setup shaders`, or point `SOKOL_SHDC` at a copy you trust ([EXPORTING.md](EXPORTING.md#setting-up-this-computer)).
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
`textures` and use `texture(sampler2D(noise, noise_smp), i.uv).r` as `n`.

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
sway. `vertex()` reads params and `fa_time` but not textures.

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

## Not available yet

- **Full vertex and fragment shaders** (your own `main`, your own vertex layout, several passes): the snippet always
  runs inside the engine's mesh shader.
- **Custom lighting** (toon ramps, your own light loop): lighting is the engine's `pbr` or `unlit`. A look that needs it
  (a two-band toon) can be faked with `s.emission` and `lighting: "unlit"` until the engine gains it.
- Materials for `Sprite`, `Shape2D`, particles, the sky and post-processing; compute shaders; textures sampled in
  `vertex()`; one instanced draw with a different value per instance.

If a game needs one of these, write it in the game's `ENGINE_FEEDBACK.json` (see [ENGINE_FEEDBACK.md](ENGINE_FEEDBACK.md)):
that is how it gets built.
