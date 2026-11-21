Part of [SHADERS.md](../SHADERS.md): materials on sprites, shapes, tiles, text and particles (`"kind": "sprite"`), with a worked example. The material file, the params and the compiler are the ones that page describes.

# Materials on sprites, shapes, tiles, text and particles

`"kind": "sprite"` makes a material for the 2D quad pipeline: everything the engine draws as textured or shaded quads
(`Sprite`, `Shape2D`, `Tilemap`, `Text` glyphs, particles and trails, UI images). The file, the params, the textures, the
compiler, the cache, `factoria validate` and `factoria export` are the ones described on [SHADERS.md](../SHADERS.md); the snippet and what it
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

An emitter of a `*.vfx.json` accepts `material` and `materialParams` like any `ParticleEmitter`.

Check a material on any of these with `shader.compile` and `factoria validate`; `material.info` lists its params.

**What the renderer does with a sprite material.** Sprites with the same material and equal param values share a draw call;
a different value of a param that is not `"instanced"`, another material or a sprite without one starts a new batch (the
draw order is the same as without materials). Params marked `"instanced": true` ("Per-instance params and vertex
channels") travel with each quad instead, so sprites, shapes, tiles, glyphs and particles of one material with a hundred
different instanced values are still one batch. `fa_time` is the engine clock and `fa_target` the size of the render
target (the image the pass draws into, which is the camera's rectangle, not the whole screen, in the coverage pass of
the sprite outline effect), in both programs. The 2D quads of a frame look their material up once per distinct
material and set of `materialParams` values, not once per component, quad or particle (`materialResolves` in the
render stats and in `game.render_stats` counts the lookups). A material whose params name a render target
(`"mask": "target:page"`) is looked up again for the camera that renders into that target, which gets the
missing-texture checker instead of the image it is writing, and its items are not copied between cameras. A material
that did not build, or that is not of kind `"sprite"`, draws the sprite in magenta (its alpha stays) with the
engine's own shader and logs the compile error once; the error log (`game.logs`) says why, `materialFallbacks` in
the render stats names it, and the previous version of a material stays in use when a hot reload of its shader
fails.

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
    vec4 custom;                // reserved: zero (per-sprite values are the material's instanced params, read by name)
    float life;                 // particles: 0 at birth to 1 at the end of the life; 0 for everything else
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

What `fragment()` leaves in `s.color` goes through the engine's last steps: the `flash` of [GAME_FEEL.md](../GAME_FEEL.md),
the conversion of a `multiply` blend and the fog. `fa_sample_main(uv)` samples the item's main texture in the colour space
of the scene (fragment stage only: not in `vertex()`; to look the picture up somewhere else); `fa_scene_rgb(c)` takes an
sRGB colour of yours (a param of type `color`) to the scene's colour space, in both stages. `fa_time` and the names of the engine's own 2D program are the
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
to 7 and samplers 3 to 6 (at most 4 textures, as for a mesh; the vertex stage reads them at views 8 to 11 and samplers 7
to 10), the params block is binding 5 (4 in the vertex stage). A
mesh material starts at view 6 and sampler 2: the numbers are not interchangeable, but `kind` decides them and you never
write them. The slots are listed in `engine/render/src/render_internal.h` (`kMaterialSpriteFirstView`).

**What is different from a mesh material.**

- `alphaMode: "clip"` is an error: a sprite is always blended by the engine. Write `if (s.color.a < 0.5) discard;` where
  you want a cut-out. `lighting` `"pbr"` and `"unlit"` and `doubleSided` mean nothing here and are ignored; `"custom"` is an
  error (there is no `light()` hook in the 2D pipeline).
- `vertexAttributes` does not apply (a quad has no second UV or colour set): refused.
- A sprite material admits a `graph` (kind `sprite`, "Node graphs" on [SHADERS.md](../SHADERS.md#node-graphs)).
- `vertex()` samples the material's textures as a mesh material's does ("Textures in `vertex()`": mip 0, the same names).
- An `instanced` param is a per-quad value (at most 3 vec4, same rules as a mesh); the snippet reads it by name in
  `fragment()` and `vertex()`. A particle's instanced values are its emitter's `materialParams`, and `i.life` is the
  particle's age over its lifetime (0 in a trail). Each quad carries its own copy (up to 192 bytes at 3 vec4) in a second vertex buffer.
- The compiled twin carries `programs.quad` and `programs.quad_plain` and the key `"kind": "sprite"`; its `template` is
  the hash of the sprite template (a change of the template recompiles sprite materials only).
- Errors name `fragment()` and `QuadInput`: `i.colour` says `did you mean color?` and lists the fields.

## 10. Dissolve and hit flash on a sprite

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

