Part of [SHADERS.md](../SHADERS.md): full shaders and passes for mesh materials (`"mode": "full"`). The material file, the
params, the compiler and the cache are the ones that page describes.

# Full shaders and passes

A mesh material normally gives the engine a small `surface()` snippet ([SHADERS.md](../SHADERS.md)). A **full shader** is the
escape hatch for what a snippet cannot say: your own `main` for the vertex stage and for the fragment stage, your own
light loop, your own vertex displacement for every pass, and **several passes** per draw (an inked outline, an x-ray,
a shell). You pay for it: you write the shading yourself, so you get none of the engine's PBR, image-based lighting or
`light()` plumbing unless you call the helpers below.

Use a snippet when you can; use a full shader when you need your own `main`, or more than one pass. Everything else of the
material system works the same: the params and textures, the inspector, `MeshRenderer.materialParams`, per-instance
params, hot reload, `shader.compile`, `material.info`, `factoria validate` and export.

## The material file

A full material is a mesh material with `"mode": "full"` (the default mode is `"snippet"`). Besides `format`, `doc`,
`shader`, `params`, `textures` and `vertexAttributes` (all as in [SHADERS.md](../SHADERS.md)) it takes:

| Key | Meaning |
|---|---|
| `mode` | `"full"`: `shader` is a file with your vertex and fragment stages (below), not a `surface()` snippet. Mesh materials only (`kind` `"mesh"`, the default). |
| `passes` | 1 to 4 passes, drawn in array order for every part of the mesh. Default: one pass named `"main"`. Each pass: `name` (a GLSL identifier, unique ignoring case), `cull` (`"back"` default, `"front"`, `"none"`), `depthTest` (default `true`: compare with the depth buffer, less or equal; `false` draws over what is there), `depthWrite` (default `true`, `false` when the pass blends), `blend` (`"none"` default, `"alpha"`, `"additive"`, `"multiply"`). |
| `shadow` | What the material does in the shadow map: `"depth"` (default), `"custom"` or `"none"` (see "Shadows"). |
| `prepass` | `true` (default) or `false` (see "SSAO and the prepass"). |

`lighting`, `alphaMode`, `doubleSided` and `graph` are refused in a full material, with an error on their pointer that
says what to write instead: you write the light loop, `blend` and `cull` belong to each pass, and the node graph only
generates snippets. `passes`, `shadow` and `prepass` are refused in a snippet material.

Blend formulas (source = your `fa_frag_color`): `"alpha"` mixes by the source alpha, `"additive"` adds the colour times its
alpha, `"multiply"` multiplies the target by the source colour.

Params, textures and per-instance params (`"instanced": true`) are declared as for a snippet: each is a global of your
shader with the same name, in both stages. A texture `t` is read as `texture(sampler2D(t, t_smp), uv)` in the fragment
stage and, as `textureLod(...)` at level 0 (the vertex stage has no derivatives; `texture` is accepted and means that), in
the vertex stage. At most 16 params, 4 textures and 3 vec4 of instanced params, as in a snippet material.

## The shader file

The file has up to three sections, each started by a line with only `@common`, `@vertex` or `@fragment`:

- `@common`: code both stages share: constants, structs, helper functions, and the `varying` declarations.
- `@vertex`: the vertex stage; it defines `void main()` and writes `gl_Position`.
- `@fragment`: the fragment stage; it defines `void main()` and writes `fa_frag_color`.

Your `@vertex` stage runs in the passes of the material (`passes`) and, with `"shadow": "custom"`, in the shadow map. It is
not seen by the depth and normal prepass (the engine's own program draws the mesh as the `MeshRenderer` has it; `"prepass":
false` keeps the material out of it) nor by the `"depth"` shadow (the default). A vertex your shader moves is moved in the
picture but not there: SSAO, fog and the other screen effects see the mesh at its original place. See "Shadows" and "SSAO
and the prepass".

`@vertex` and `@fragment` are both required, and code before the first section is an error. Code in `@common` is
compiled in both stages (use `#ifdef FA_PASS_...` for what differs). A `main()` in `@common` is refused.

A **varying** carries a value from the vertex stage to the fragment stage: write `varying vec3 v_normal;` (optionally
`flat`, `smooth` or `noperspective` first) in `@common`; it is an `out` in the vertex stage and an `in` in the fragment
stage. The two stages must declare the same list, in the same order, with the same types (declaring each once in
`@common` makes it true by construction); a mismatch is an error naming both lines. At most **12 vec4 slots** of
varyings (a `mat4` takes four): OpenGL ES 3 and WebGL 2 guarantee only 15, and the engine's three flat instance varyings
take the other three, so 12 + 3 fits exactly.

### What the engine gives you

Every engine name starts with `fa_` (`FA_` for macros); you may use only the ones listed here, and declaring or using any
other `fa_` name is an error with a "did you mean" hint. Your own names must not start with `fa_` or `FA_`.

**Vertex stage**

| Name | Meaning |
|---|---|
| `fa_position`, `fa_normal`, `fa_texcoord0`, `fa_tangent`, `fa_color` | The mesh vertex: `vec3`, `vec3`, `vec2`, `vec4`, `vec4`, in model space (the bind pose of a skinned mesh). |
| `vertex_uv1`, `vertex_color1` | The second UV set (`vec2`) and second vertex colour (`vec4`) of a glTF mesh, only when `vertexAttributes` lists `"uv1"` or `"color1"`. |
| `fa_model` | The `mat4` of this vertex: the entity's model matrix (the instance's, with instancing), times the joint blend of a skinned mesh. |
| `fa_world_position(p)` | `fa_model * vec4(p, 1)`, as a `vec3`: use it for every position you move, so skinning and instancing apply. |
| `fa_world_direction(n)` | A model-space direction to the world, normalized and right for non-uniform scale. |
| `fa_view_proj` | The `mat4` from world to clip space of the camera. |
| `fa_light_vp`, `fa_shadow_coord(world)` | The matrix of the shadow pass being drawn (what the shadow program of your material places the mesh with), and the shadow coordinate of a world position: pass it in a varying to `fa_shadow()` and `fa_light()`. It holds the world position itself (the fragment stage picks the cascade of the sun's shadow and projects it), so do not read its `xyz` as a light-space position. |
| `fa_uv_scale` | `vec4`, `xy` is `MeshRenderer.uvScale`. |
| `fa_instance_index` | `int`, 0 to `MeshRenderer.instances` - 1: the instance of a material with `buffers`, which also reads them in both stages as `<name>.data[i].<field>` and needs `"shadow": "custom"` (or `"none"`); [Drawing from a compute buffer](SHADERS_COMPUTE.md#drawing-from-a-compute-buffer). |
| `FA_TIME`, `FA_CAMERA` | Seconds of game time (`float`) and the camera's world position (`vec3`); also in the fragment stage. |

**Fragment stage**

| Name | Meaning |
|---|---|
| `fa_frag_color` | The output, a `vec4`, in the scene's colour space (`SceneSettings.colorSpace`); the pass's `blend` uses its alpha. Write it. |
| `fa_base_sample(uv)` | The `MeshRenderer`'s base colour texture at `uv`, in the scene's colour space, times `MeshRenderer.color`, read with `fa_mip_bias`. |
| `fa_mip_bias` | `float`: the frame's texture level-of-detail bias, 0 or negative (below 0 only while the temporal upscaler or the temporal antialiasing accumulates frames, docs/UPSCALING.md "Texture mip bias"). `fa_base_sample` adds it; add it to your other reads, `texture(sampler2D(t, t_smp), uv, fa_mip_bias)`. Fragment stage only. |
| `fa_base_color` | `MeshRenderer.color` as a `vec4`. `fa_emissive.rgb` is `MeshRenderer.emissive`. |
| `fa_camera_pos`, `fa_ambient`, `fa_env_sky`, `fa_env_horizon` | `vec4`s: camera position, the ambient light, the sky and horizon colours (`.rgb` or `.xyz`). |
| `fa_light_count()` | How many of the first lights of the engine's table (the directional lights first, at most 32), in its own order. With hundreds of lights in the scene, loop over `fa_cluster_light_count(world_pos)` instead. |
| `fa_cluster_light_count(world_pos)`, `fa_cluster_light_index(n, world_pos)` | The lights that reach the cluster of a world position (clustered lighting, M73.1a): how many, and the table index of the n-th, to give to `fa_light`. Look the cluster up once per fragment: both calls do it again. |
| `fa_light(i, world_pos, geometric_normal, shadow_coord)` | A `LightSample` for light `i` seen from that point: `direction` (to the light), `color` (colour times intensity times attenuation times shadow), `attenuation`, `shadow`, `distance` and `type` (0 directional, 1 point, 2 spot). Only the first directional light has a shadow; it is `1.0` when the mesh does not receive shadows. |
| `fa_environment(dir, roughness)`, `fa_env_brdf(roughness, ndv)`, `fa_sky_reflection(n, v, f0, roughness)` | The sky light of the engine's own meshes: the sky colour in a direction (from `fa_env_sky` and `fa_env_horizon`), the environment BRDF `vec2`, and the reflection of the sky in a surface with normal `n` seen from direction `v` (to the eye), `f0` its reflectance at normal incidence. [Your own light loop and the sky light](SHADERS_LIGHTING.md) explains them. |
| `fa_apply_decals(world_pos, geometric_normal, inout albedo, inout normal)` | Paints the `Decal` components of the position's cluster over an albedo and a shading normal (M73.5b). The engine's meshes get it for free; a full shader calls it once, in uniform control flow, before it lights (it takes derivatives), or it ignores decals. See [Your own light loop and the sky light](SHADERS_LIGHTING.md), "Decals". |
| `fa_shadow(coord, n, l)` | The fraction of light that reaches a point from the directional shadow map (1 = lit), for your own use. |
| `fa_apply_fog(color, world_pos)` | The scene's fog applied to a colour. A full shader is **not fogged** unless it calls this. |
| `fa_srgb_to_linear(c)`, `fa_linear_to_srgb(c)` | The colour space conversions of the engine. |

The glTF's other textures (normal, metallic-roughness, occlusion, emissive) are not available: a
full shader that wants them declares its own `textures`. The sky reflection is the `fa_sky_reflection()` above. Macros: `FA_PASS` (the index of the pass being compiled, `0..3`),
`FA_PASS_<NAME>` (defined, as `1`, only in the pass called `name`, upper case), `FA_SKIN` (defined in the programs for
skinned meshes) and `FA_SHADOW_PASS` (see "Shadows"). You never branch on `FA_SKIN`: `fa_world_position()` and
`fa_world_direction()` already include the skin.

## Passes

Each pass is compiled to its own program (the same source with that pass's `FA_PASS` macros) and has its own render state.
The engine draws, for every part of the mesh, **pass 0, then pass 1, and so on, in array order**, before the next part. There
is no per-pass sort key: the order of the array is the order of the draws.

Culling is the pass's own `cull`: a glTF material's `doubleSided` is ignored in a full material, so a pass that must show
both faces says `"cull": "none"`.

Each pass is its own draw call, and `render.stats` counts it as one in `drawCalls` and its triangles in `triangles`: a part drawn
in three passes is three draw calls and three times its triangles (the glTF part is not counted once).

A material with at least one `blend` pass is drawn with the other blended meshes, far to near by the entity's distance to
the camera, and all its passes draw there, in array order. A material whose passes do not blend is opaque: it is batched
and instanced like any opaque mesh of the same material (see "Skinning and instancing").

## Shadows

`shadow` says what the material does when the directional light renders the shadow map:

- `"depth"` (default): the engine's own depth-only program draws the mesh **as the `MeshRenderer` has it**. Your vertex
  stage is not applied: a vertex that your shader moves casts its shadow at the original place, and `discard` does not cut
  holes. Use it when the shader does not change the silhouette.
- `"custom"`: the first pass is compiled again with `FA_SHADOW_PASS` defined, and `fa_view_proj` is the light's matrix in it.
  So `gl_Position = fa_view_proj * ...` is the position in the shadow map, your vertex displacement shapes the shadow, and a
  `discard` in `@fragment` cuts holes in it. Your whole fragment `main` runs in that program (the colour you write is
  thrown away and the program stores the depth), so wrap what is useless or costly there, such as light loops and texture
  reads that only feed `fa_frag_color`, in `#ifndef FA_SHADOW_PASS`, and keep the `discard` outside it. Skinned and instanced
  meshes work.
- `"none"`: the material casts no shadow.

The template also holds the engine's own helpers of the light loop and the shadow lookups (and the macros `FA_SHADOW_TEX` and `FA_SHADOW_SMP`),
because it includes the shared files, but only the names this page lists are for you: the others are internal, and their signatures and the
data behind them change between versions.

A mesh with a full material **receives** shadows only as far as your fragment stage reads `fa_shadow()` or `fa_light()`.

## SSAO and the prepass

The depth and normal prepass is what ambient occlusion, depth fog and the other screen effects read. With `"prepass":
true` (default) the engine's own prepass program draws the mesh as the `MeshRenderer` has it, so the effects see it, but
**not what your vertex stage moves** (the same limit as `"depth"` shadows). With `"prepass": false` the mesh stays out of
the prepass: the effects ignore it, and it is neither darkened by SSAO nor does it occlude others. Set it to `false` for
an effect the screen passes must not see (a hologram, a ghost, a shell); a material with a blend pass is out of the prepass
anyway, because the prepass holds only opaque meshes.

## Skinning and instancing

**Both are supported.** A skinned mesh (an `Animator` with a glTF skin) draws with a skinned program of every pass: you
write nothing for it, `fa_world_position()` and `fa_world_direction()` include the joints. Entities with the same material,
textures and params share one instanced draw per pass; instanced params (`"instanced": true`) give each entity its own value
inside it, and both stages read them by name.

## Mesh channels

`vertexAttributes` is declared as in a snippet material and only `"uv1"` and `"color1"` exist: the vertex stage reads them as
`vertex_uv1` and `vertex_color1`. Pass them on in a varying to use them in the fragment stage. A mesh that has not the
channel (the built-in primitives never have them) is drawn with the magenta error material for that part, the log says
which material and mesh once, and `render.stats` lists the material in `materialFallbacks`. Naming a channel that does not
exist (`"uv2"`) is an error on `/vertexAttributes/0` with a "did you mean".

## Errors

`shader.compile` and `factoria validate` report the problems in your file with its line and column, before the compiler
starts when they can: a missing section or `main`, a `gl_Position` or `fa_frag_color` that is never written, varyings that
differ between the stages, more than 12 varying slots, an engine `fa_` name that does not exist. The compiler's own errors
are mapped to the line of your file, in whichever stage and pass they are, and reported once. Problems of the file
itself carry a JSON pointer and a fix, such as `/passes/1/cull` with a "did you mean" for a misspelt value, or `/lighting`:
`"lighting" has no effect in a full-shader material`.

A material whose build fails at run time is drawn with the magenta error material and the log names the file.
A hot reload that fails keeps the last good program and logs the error once.

## Where it runs

Everything compiles to every dialect (HLSL for Windows, GLSL 4.3 for Linux, GLSL ES 3.0 for Android and the web, Metal for
macOS and iOS) like a snippet material; export writes the same twin files (`<material>.json.<slang>.shader`), which now
carry `"full": true`, `shadow`, `prepass` and the passes. `material.info` returns `mode`, `shadow`, `prepass`, `passes`
(each with its `program` and `programSkin`) and the list of `programs`: `mesh`, `mesh_skin`, `pass1`, `pass1_skin`, ... one
pair per pass, `shadow` and `shadow_skin` for `"custom"`, `prepass` and `prepass_skin` unless `"prepass": false`.

Limits: 4 passes, 12 programs per material, 12 varying slots. OpenGL ES 3 and WebGL 2 give a vertex stage 16 inputs: the
engine's mesh layout takes 9 (11 when skinned), the instance data up to 3 and the declared channels up to 2, so a full
shader cannot add inputs of its own.

## Examples

A custom light loop: the surface colour times a diffuse term of every light the engine selected, with the scene's fog.

File `materials/lamp_lit.material.json`:

```json
{
  "format": "factoria.material/1",
  "doc": "A flat colour lit by a loop over the scene's lights (diffuse only), then fogged.",
  "mode": "full",
  "shader": "shaders/lamp_lit.full.glsl",
  "params": {
    "base": { "type": "color", "default": [0.9, 0.8, 0.5, 1.0], "doc": "The surface colour the lights are multiplied with." },
    "wrap": { "type": "float", "default": 0.0, "min": 0.0, "max": 1.0, "doc": "How far the light wraps around the terminator: 0 is plain Lambert, 1 lights the whole mesh." }
  }
}
```

File `shaders/lamp_lit.full.glsl`:

```glsl
@common
varying vec3 v_pos;
varying vec3 v_normal;
varying vec4 v_shadow;

@vertex
void main() {
    vec3 world = fa_world_position(fa_position);
    v_pos = world;
    v_normal = fa_world_direction(fa_normal);
    v_shadow = fa_shadow_coord(world);
    gl_Position = fa_view_proj * vec4(world, 1.0);
}

@fragment
void main() {
    vec3 n = normalize(v_normal);
    vec3 lit = fa_ambient.rgb * base.rgb;
    for (int i = 0; i < fa_light_count(); ++i) {
        LightSample l = fa_light(i, v_pos, n, v_shadow);
        float d = clamp((dot(n, l.direction) + wrap) / (1.0 + wrap), 0.0, 1.0);
        lit += base.rgb * l.color * d;
    }
    fa_frag_color = vec4(fa_apply_fog(lit, v_pos), 1.0);
}
```

An x-ray: the mesh drawn normally, then once more without the depth test, so it shows through what hides it.

File `materials/see_through.material.json`:

```json
{
  "format": "factoria.material/1",
  "doc": "The mesh in its own colour, and a translucent copy of it that shows through walls.",
  "mode": "full",
  "shader": "shaders/see_through.full.glsl",
  "prepass": false,
  "passes": [
    { "name": "body" },
    { "name": "xray", "depthTest": false, "blend": "alpha" }
  ],
  "params": {
    "bodyColor": { "type": "color", "default": [0.2, 0.5, 0.9, 1.0], "doc": "The colour of the visible mesh." },
    "glow": { "type": "color", "default": [1.0, 0.9, 0.2, 0.35], "doc": "The colour and opacity of the part seen through other objects." }
  }
}
```

File `shaders/see_through.full.glsl`:

```glsl
@vertex
void main() {
    gl_Position = fa_view_proj * vec4(fa_world_position(fa_position), 1.0);
}

@fragment
void main() {
#ifdef FA_PASS_XRAY
    fa_frag_color = glow;
#else
    fa_frag_color = vec4(bodyColor.rgb, 1.0);
#endif
}
```

An inked outline: a two-band toon body over the scene's lights, and a second pass that draws the back faces pushed out
along their normals, in the ink colour.

File `materials/ink_outline.material.json`:

```json
{
  "format": "factoria.material/1",
  "doc": "A two-band toon body with an ink outline made of the inflated back faces.",
  "mode": "full",
  "shader": "shaders/ink_outline.full.glsl",
  "passes": [
    { "name": "body", "cull": "back" },
    { "name": "outline", "cull": "front" }
  ],
  "params": {
    "bodyColor": { "type": "color", "default": [0.3, 0.7, 0.4, 1.0], "doc": "The colour of the lit band of the body." },
    "inkColor": { "type": "color", "default": [0.05, 0.05, 0.08, 1.0], "doc": "The colour of the outline." },
    "inkWidth": { "type": "float", "default": 0.03, "min": 0.0, "max": 0.5, "doc": "How far the outline pass pushes each vertex along its normal, in model units." }
  }
}
```

File `shaders/ink_outline.full.glsl`:

```glsl
@common
varying vec3 v_pos;
varying vec3 v_normal;
varying vec4 v_shadow;

@vertex
void main() {
    vec3 p = fa_position;
#ifdef FA_PASS_OUTLINE
    p += normalize(fa_normal) * inkWidth;  // the back faces, a little bigger than the body
#endif
    vec3 world = fa_world_position(p);
    v_pos = world;
    v_normal = fa_world_direction(fa_normal);
    v_shadow = fa_shadow_coord(world);
    gl_Position = fa_view_proj * vec4(world, 1.0);
}

@fragment
void main() {
#ifdef FA_PASS_OUTLINE
    fa_frag_color = vec4(inkColor.rgb, 1.0);
#else
    vec3 n = normalize(v_normal);
    float light = 0.0;
    for (int i = 0; i < fa_light_count(); ++i) {
        LightSample l = fa_light(i, v_pos, n, v_shadow);
        light += max(dot(n, l.direction), 0.0) * dot(l.color, vec3(0.3333));
    }
    float band = light > 0.5 ? 1.0 : 0.45;
    fa_frag_color = vec4(fa_apply_fog(bodyColor.rgb * (fa_ambient.rgb + vec3(band)), v_pos), 1.0);
#endif
}
```

Pass 0 (`body`) draws the front faces, pass 1 (`outline`) the back faces of the same mesh; the back faces pushed out show as a
rim around the silhouette. Both write depth, so the outline never covers the body. The material casts the shadow of the
original mesh (`"shadow": "depth"`, the default), and the engine's prepass sees the original mesh too. A skinned mesh draws
both passes with its skin.
