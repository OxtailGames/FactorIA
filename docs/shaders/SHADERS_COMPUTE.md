Part of [SHADERS.md](../SHADERS.md): the compute materials (`"kind": "compute"`). The material file, the params, the compiler
and the cache are the ones that page describes.

# Compute materials

A material with `"kind": "compute"` is a program that runs on the GPU over **storage buffers** and draws nothing: particle
simulations, flocking, flow fields, anything that updates many elements at once. Its snippet defines one function, called
once per thread:

```glsl
void compute(in ComputeInput i) {
    uint k = i.global_id.x;
    items.data[k].value = items.data[k].value * factor;
}
```

`ComputeInput` is read-only: `global_id` (the thread's index over the whole dispatch), `local_id` (inside its workgroup),
`group_id` (the workgroup's index) and `local_index` (`local_id` flattened). All but the last are `uvec3`.

The file (`materials/<name>.material.json`) takes these keys besides `format`, `kind`, `doc` and `shader` (which names the
snippet, e.g. `shaders/boids.compute.glsl`); `lighting`, `alphaMode` and `doubleSided` do not apply to a compute material (it draws nothing) and are refused with an error:

| Key | Meaning |
|---|---|
| `workgroupSize` | The threads of one workgroup, `[x, y, z]` (y and z default to 1; default `[64, 1, 1]`). The product must be a multiple of 32 and at most 256: `[64]`, `[128]`, `[8, 8]`, `[16, 16]`; z is at most 64 (Direct3D 11 and OpenGL limit it). A dispatch counts workgroups, not threads. |
| `buffers` | The storage buffers: `{"name": {"doc": "...", "access": "readWrite" or "read", "fields": [{"name": "pos", "type": "vec2", "doc": "..."}]}}`. At most 4 buffers of at most 16 fields each. A field is `float`, `vec2`, `vec3`, `vec4`, `int` or `uint`. The buffer is an array of elements made of the fields, laid out as std430 (a `vec3` takes 12 bytes but aligns to 16: prefer `vec4`); the snippet reads and writes `<name>.data[index].<field>`. |
| `params` | As for a mesh material (at most 16, each a variable of the snippet). A dispatch gives their values. |
| `textures` | As for a mesh material: read in the snippet like in a mesh snippet. A dispatch gives the path of each texture in `params`. |
| `images` | The storage images: `{"name": {"doc": "...", "format": "rgba8", "access": "write", "size": [256, 256]}}` ([Storage images](#storage-images)). At most 4. |

A buffer in the file only describes the element; the buffer itself is created at run time with `compute.create_buffer`. A
storage image is the same: the file declares it, `compute.create_image` makes it.

Errors point at the place: `/workgroupSize: 8 threads (8 x 1 x 1), which is not a multiple of 32`, `/buffers/items/fields/0/type:
unknown field type "flaot" (did you mean "float"?)`, a snippet without `compute(in ComputeInput i)` says so with the file and
line.

### Running one

The `compute.*` commands (also `fa.call("compute.dispatch", ...)` in a script, and MCP/CLI) work on buffers by id:

| Command | What it does |
|---|---|
| `compute.create_buffer` | `{material, buffer, count, initial?}`: a buffer of `count` elements shaped like the material's `buffer`; `initial` is an array of `{field: value}` objects for the first elements, the rest is zero. Returns `{id, count, stride, bytes}`. |
| `compute.write_buffer` | `{buffer, elements, first?}`: overwrites elements from `first` with `{field: value}` objects (a field left out is written as 0). |
| `compute.dispatch` | `{material, buffers, params?, groups?}`: runs the material once. `buffers` maps each buffer name of the material to an id; `params` gives values and texture paths; `groups` is `[x, y, z]` workgroups (default `[1, 1, 1]`). Dispatches run in the order they are made. |
| `compute.read_buffer` | `{buffer, first?, count?}`: the current contents as `{field: value}` objects (a `vecN` is an array, floats have 7 significant digits, a NaN or infinity is `null`). It waits for the GPU, so use it to check a result, not every frame. |
| `compute.destroy_buffer` | `{buffer}`: frees it. |
| `compute.list_buffers` | The live buffers, and `available` / `status`. |
| `compute.create_image`, `compute.resize_image`, `compute.read_image`, `compute.destroy_image`, `compute.list_images` | The storage images ([below](#storage-images)). `compute.dispatch` takes `images` next to `buffers`. |

From C++ the same is `Renderer::compute()` (`fa/render/compute.h`: `create_buffer`, `write_buffer`, `dispatch`, `read_buffer`,
`create_image`, `resize_image`, `read_image`, `destroy_image`).

Limits, all counts and never time: 64 buffers, 256 MiB each and 1 GiB in all, at most 65535 workgroups per dimension and
1048576 elements and 4194304 numbers (elements times the components of their fields, so the JSON of one call stays small)
converted per write or read call. A request over one is refused with the number it hit and, for a read or write, the
largest count that fits: go on in chunks with `first` and `count`. A read without `count` stops at that largest count.
Floats come back rounded to 7 digits, so integers above 2^24 stored in a float field do not return exact.

### Storage images

A compute shader can write (and read) the pixels of a **2D image**, and the image is then a texture for a mesh, sprite or post
material, a `Sprite.texture` or a `MeshRenderer.texture`: a noise field, a heat map, a flow field, a water height map, all
made on the GPU and never copied to the CPU. The file declares each image:

```json
"images": {
  "field": { "doc": "The pattern.", "format": "rgba8", "access": "write", "size": [256, 256] },
  "heat":  { "doc": "Heat, grows by 1 a dispatch.", "format": "r32f", "access": "readWrite", "size": [256] }
}
```

| Key | Meaning |
|---|---|
| `format` | `rgba8` (default; 8 bits a channel, `vec4` in 0..1), `rgba16f`, `r32f` (one float, `imageLoad(heat, p).x`) or `rgba32f`. |
| `access` | `"write"` (default: `imageStore`) or `"readWrite"` (`imageStore` and `imageLoad`). `readWrite` is guaranteed for `r32f` only: whether another format can be loaded depends on the GPU (the table below), and `compute.create_image` refuses the image with `/images/<name>/access` when it cannot. A read-only image is refused: declare a texture of the material instead and sample it. |
| `size` | The size `compute.create_image` gives when it is not asked another: `[width, height]`, or one number for a square. Default `[256, 256]`, each side 1 to 8192. |

At most 4 images in a material (the number of storage images every GPU with compute guarantees one shader). The snippet uses
the image by its name:

```glsl
void compute(in ComputeInput i) {
    ivec2 p = ivec2(i.global_id.xy);
    ivec2 size = imageSize(field);
    if (p.x >= size.x || p.y >= size.y) return;           // the dispatch may be a bit larger than the image
    imageStore(field, p, vec4(float(p.x) / float(size.x), float(p.y) / float(size.y), 0.5, 1.0));
    imageStore(heat, p, vec4(imageLoad(heat, p).x + 1.0, 0.0, 0.0, 0.0));
}
```

**A complete run** (a script; `workgroupSize` is `[8, 8]`, so 32 x 32 workgroups cover 256 x 256 pixels):

```js
const field = fa.call("compute.create_image", { material: "materials/field.material.json", image: "field" });
const heat = fa.call("compute.create_image", { material: "materials/field.material.json", image: "heat" });
fa.call("compute.dispatch", { material: "materials/field.material.json",
                              images: { field: field.id, heat: heat.id }, groups: [32, 32, 1] });
// field.textureId is "compute:1": write it into the `texture` of any Sprite (or the texture param of a material)
// to check a result: the top-left 2 x 2 pixels, [r, g, b, a] each, row by row
const px = fa.call("compute.read_image", { image: field.id, x: 0, y: 0, width: 2, height: 2 }).data;
```

How an image behaves:

- **Texture id.** `textureId` is `"compute:<id>"`. Put it wherever a texture path goes (`Sprite.texture`, `MeshRenderer.texture`,
  a `Shape2D`, a UI image, or the value of a texture param in `materialParams`). It stays valid when the image is resized.
  After `compute.destroy_image` the material draws the missing-texture checker and the log names the id, so a stale id is
  seen at once. An id is never used for another image.
- **A new image is zero** (transparent black), not whatever the GPU memory held, and so is a resized one: its pixels are lost.
- **Order.** Commands run in the order they are made. A dispatch recorded before a draw of the same frame is finished when the
  draw reads the image (the graphics API orders it: Metal and Direct3D 11 track it, OpenGL gets a memory barrier). Reading
  an image back (`compute.read_image`) waits for every dispatch before it.
- **Not both at once.** One image is not a storage image and a texture of the same dispatch (the graphics APIs refuse it):
  `compute.dispatch` says which texture param names the image it writes. Sample it in the NEXT dispatch, or read it with
  `imageLoad` (`"readWrite"`).
- **Filtering.** `rgba8` and `rgba16f` filter (linear sampling) everywhere. `r32f` and `rgba32f` do not on some GPUs; there the
  image can still be written and read back, but a material that samples it shows the checker and the log says that the
  format cannot be filtered: use `rgba16f` for a picture.
- **Reading.** `compute.read_image {image, x?, y?, width?, height?}` returns `{x, y, width, height, format, channels, data}`
  with `data` flat, row by row from the top, `channels` numbers a pixel (`rgba8`: integers 0..255; floats with 7 significant
  digits, a NaN or infinity `null`). It waits for the GPU: use it to test a result, never every frame. A call converts at most
  4194304 numbers; without `width` and `height` the command returns the rows that fit.
- **Deterministic.** The same dispatches over the same images give the same pixels; nothing depends on the time or the CPU.

Limits, all counts and sizes: 32 live images, 8192 pixels a side (or what the GPU allows), 256 MiB for one image and 512 MiB in
all. A request over one is refused with the number it hit; a format the GPU cannot write as a storage image is refused with
the list that works on it ("storage image format not supported"), and a material that declares one is refused the same way
when the image is made. An image declared `readWrite` in a format this GPU cannot `imageLoad` is refused too (`/images/<name>/access`):
make it `r32f`, or split it into two images, write one and read the other as a texture, swapping them each frame. A refused
request changes nothing.

| Where | Storage images |
|---|---|
| Windows, Direct3D 11 | Yes (typed UAVs). All four formats can be written. `readWrite` works for `r32f` on every GPU; for `rgba8`, `rgba16f` and `rgba32f` only where the device reports a typed UAV load for the format (D3D11.0 hardware does not: an `imageLoad` there would return garbage, so the engine refuses the image). |
| macOS and iOS, Metal | Yes, all four formats written; `r32f` and `rgba32f` are filtered when sampled on macOS only. `readWrite` works for every format on a GPU with read-write texture Tier 2 (Apple silicon, recent AMD and Nvidia), and for `r32f` only on Tier 1 (older Intel Macs, iOS A9-A10): the other formats are refused there. |
| Linux, OpenGL 4.3 or newer | Yes (`imageLoad`/`imageStore`; the engine inserts the memory barriers). `readWrite` works for all four formats (the shader declares the format, so every one can be loaded). |
| macOS on OpenGL 4.1 | No compute at all. |
| Android (OpenGL ES 3.0), the web (WebGL2) | No: the GPU has no compute shaders and no storage images, so `compute.read_image` is not available either. `compute.create_image` fails with `unavailable`, naming the backend and the CPU path. |
| Vulkan and Direct3D 12 | With the M77 backends. |

**The CPU path** for a computer without compute (and for a game that ships to Android or the web): fill the picture in the
script. `render.textureFromPNG` makes a texture at run time and returns its `id` ("runtime:3"; docs/SCRIPTING.md, "Render"),
or compute the same effect per pixel in a mesh, sprite or post material, which runs everywhere a material does. A game
decides with `render.supports computeShaders`.

### Drawing from a compute buffer

A **mesh** material can read the buffers a compute material writes, and one entity then draws that mesh many times, once per
element, with no copy to the CPU. Declare `buffers` in the mesh material exactly as above, with `"access": "read"` (the default
here; `readWrite` is refused at `/buffers/<name>/access`), and read `<name>.data[i].<field>` in `vertex()`, in a helper and in
`surface()` (a `mode: "full"` shader reads it in `@vertex` and `@fragment`). `vertex()` gets the instance number as
`fa_instance_index` (an `int`, 0 to `instances` - 1; in a mesh material without buffers it is only the position of the entity in
its automatic batch, which is no stable id) and moves each instance itself; `v.world_pos` starts as the mesh vertex
placed by the entity's Transform, which is the base all instances share.

On the entity: `MeshRenderer.instances` = N (0 is a normal draw of one mesh; vertex() still runs once, with index 0), and
`materialParams` gives the id of a compute buffer for each declared buffer: `{"particles": 3}`. The buffer must come from a
compute material that declares the same buffer (same field names, types and order, so the same stride) and every one
of the buffers it reads must hold at least N elements (a smaller one would be read past its end: the entity is not drawn and
the log names `/instances` and the short buffer). A missing, destroyed or differently shaped buffer is reported once with the JSON pointer (`/materialParams/particles`) and the
entity is not drawn; nothing crashes. `instanceBounds` is the half-extent in the entity's local metres of the box holding every
instance: the camera culls the entity (and its shadow) by it, and 0 never culls. The CPU cannot know where the GPU put the
instances, so there is no per-instance culling there.

Limits and rules: at most 4 buffers; N up to 16777216; an entity with buffers is a draw of its own (never batched, no `lods`,
and `"instanced": true` params are refused with `buffers`, as they would be a second source of per-instance data). In a snippet
material the instances cast shadows and enter the depth prepass like the mesh. A full shader must write `"shadow": "custom"`
(its first pass is compiled again for the shadow map, so its `@vertex` places the instances there too) or `"shadow": "none"`;
the prepass is left out for it (`"prepass": false`, which is then the default). A skinned mesh (an `Animator`) with buffers is not covered by the tests.

**Particles on the GPU.** A compute material moves them, a mesh material draws them as quads. Both declare the same buffer
(`"buffers": {"sparks": {"fields": [{"name": "pos", "type": "vec4"}]}}`, xyz = position, w = life left); the compute material has
`"workgroupSize": [64]` and the float params `count` and `dt`; the mesh material has `"shader": "shaders/sparks.surface.glsl"`.

```glsl
// shaders/sparks_sim.compute.glsl
void compute(in ComputeInput i) {
    uint k = i.global_id.x;
    if (float(k) >= count) return;
    vec4 p = sparks.data[k].pos;
    sparks.data[k].pos = vec4(p.xyz + vec3(0.0, dt, 0.0), p.w - dt);
}
// shaders/sparks.surface.glsl: a quad per spark, facing +Z, the entity at the origin with no scale
void vertex(inout VertexData v) {
    vec4 p = sparks.data[fa_instance_index].pos;
    v.world_pos = p.xyz + v.object_pos * 0.2;
}
void surface(in SurfaceInput i, inout Surface s) { s.emission = vec3(1.0, 0.6, 0.2); }
```

```js
// scripts/sparks.js, on an entity whose MeshRenderer mesh is "quad"
import { Behaviour } from "factoria";

export default class Sparks extends Behaviour {
  onStart() {
    const buf = fa.call("compute.create_buffer", { material: "materials/sparks_sim.material.json", buffer: "sparks", count: 1000 });
    this.buf = buf.id;
    this.entity.set("MeshRenderer", { material: "materials/sparks.material.json", instances: 1000, instanceBounds: 20,
                                      materialParams: { sparks: buf.id } });
  }
  onUpdate(dt) {  // the dispatch is queued before the frame that draws
    fa.call("compute.dispatch", { material: "materials/sparks_sim.material.json", buffers: { sparks: this.buf },
                                  params: { count: 1000, dt }, groups: [16, 1, 1] });
  }
}
```

**GPU culling without an indirect draw.** The engine sets the instance count on the CPU (sokol_gfx has no indirect draw), so a
compute pass cannot shorten the draw; it makes the extra instances cost nothing to look at instead. Write a flag or a size per
element, and let `vertex()` collapse an instance by putting it outside the clip volume (or scaling it to 0):

```glsl
// compute: p.w = 1 when the point is within `radius` of `center`, else 0
points.data[k].pos.w = distance(points.data[k].pos.xyz, center) < radius ? 1.0 : 0.0;
// vertex(): a hidden instance is placed far outside the view, so nothing of it is rasterized
vec4 p = points.data[fa_instance_index].pos;
if (p.w < 0.5) { v.world_pos = vec3(1.0e9); return; }
v.world_pos += p.xyz;
```

A collapsed instance still costs its vertex stage; keep `instances` as small as the buffer's live part when you can. Tests
`mesh buffers: ... (GPU culling by a flag)` run exactly this.

**Where it runs.** Metal, Direct3D 11 and OpenGL 4.3 or newer (a storage buffer in the vertex stage). On Android (GLES3), the web
(WebGL2) and macOS OpenGL 4.1 the material is refused when it loads: the entities draw magenta and the log names the backend,
the rule and the CPU path (write the instances as entities, or as `"instanced"` params of a material without buffers, from a
script). Ask `render.supports computeShaders` first. A dispatch made before a frame is drawn is finished when that frame reads
it (commands run in order). Each buffer is declared once in the vertex and once in the fragment stage, so a program takes two
storage-buffer bindings per buffer (at most 8 with 4 buffers, which every OpenGL 4.3 driver has: GL guarantees 8). A driver
that reports fewer (`GL_MAX_SHADER_STORAGE_BUFFER_BINDINGS`) refuses a material with more buffers when it loads, naming the
number it offers and how many buffers fit; pack several arrays into the fields of one buffer then. The tests here ran on
Metal only; the OpenGL and Direct3D 11 draws were not run.

### Sprites from a compute buffer

The 2D side of the same idea: a **sprite** material (`"kind": "sprite"`) declares read-only `buffers` exactly as a mesh material
does (`"access": "read"` is the default, `readWrite` is refused at `/buffers/<name>/access`), and reads `<name>.data[i].<field>`
in `vertex()`, in a helper and in `fragment()`. Both stages get the instance number as `fa_instance_index` (an `int`, 0 to
`instances` - 1; in a sprite material without buffers it is always 0, and `factoria validate` warns when the snippet reads it). `v.world_pos` in `vertex()` starts as the corner of the sprite's
own quad, placed by its Transform and `size`: that quad is the template every instance starts from, and `vertex()` moves each
instance itself.

On the entity: `Sprite.instances` = N (0 is a normal sprite: one quad, and `vertex()` still runs once with index 0), and
`materialParams` gives the id of a compute buffer for each declared buffer: `{"particles": 3}`. The buffers must come from a
compute material that declares the same buffer (same field names, types and order) and every one of them must hold at least N
elements. Anything else (a missing, non-integer or destroyed id, another stride, a buffer shorter than N, N outside 0 to
16777216, `instances` on a material without buffers) is reported once with the JSON pointer (`/materialParams/particles`,
`/instances`) and the sprite is not drawn; nothing crashes. There is no `instanceBounds`: the CPU culls no sprite, so nothing
needs a box that the GPU data would not keep.

Rules: at most 4 buffers; `"instanced": true` params are refused together with `buffers` (error at `/params/<name>/instanced`);
the sprite is **one draw** (`stats.drawCalls` 1, `stats.sprites` 1, however many instances) and one item of its layer, ordered
by `layer` and `orderInLayer` like any sprite; a sprite whose material has buffers is never batched with another sprite, not even
one with the same material and buffers. `meshColumns`, `slice`, `SpriteSkin` and a Parallax repeat are ignored for it. Only a
`Sprite` can draw from buffers: a Shape2D, Tilemap, Text, ParticleEmitter or UiBox that uses such a material is not drawn, and the
log says so once.

**Particles on the GPU in 2D.** A compute material moves them, a sprite material draws them. Both declare the same buffer; the
compute material has `"workgroupSize": [64]` and the float params `count` and `dt`.

```json
{ "format": "factoria.material/1", "kind": "sprite", "shader": "shaders/sparks2d.fragment.glsl",
  "buffers": { "sparks": { "fields": [ { "name": "pos", "type": "vec4" }, { "name": "tint", "type": "vec4" } ] } } }
```

```glsl
// shaders/sparks2d_sim.compute.glsl: pos.xy = the offset from the sprite, pos.w = 1 visible, 0 hidden
void compute(in ComputeInput i) {
    uint k = i.global_id.x;
    if (float(k) >= count) return;
    vec4 p = sparks.data[k].pos;
    sparks.data[k].pos = vec4(p.x, p.y + 30.0 * dt, p.z, p.w);
}
// shaders/sparks2d.fragment.glsl: the sprite's own quad (all four corners), moved per instance
void vertex(inout QuadVertex v) {
    vec4 p = sparks.data[fa_instance_index].pos;
    v.world_pos.xy = p.w < 0.5 ? vec2(1.0e9) : v.world_pos.xy + p.xy;
}
void fragment(in QuadInput i, inout QuadSurface s) {
    s.color.rgb *= sparks.data[fa_instance_index].tint.rgb;
}
```

A hidden instance is put far outside the view, so nothing of it is rasterized (the same GPU culling by a flag as for meshes: the
CPU still draws N instances, so keep `instances` as small as the live part of the buffer). To scale an instance too, multiply
the corner's distance from the sprite's centre. The script is the one of the mesh example with `Sprite` in place of
`MeshRenderer`:
`this.entity.set("Sprite", { material: "materials/sparks2d.material.json", size: [8, 8], instances: 1000, materialParams: { sparks: buf.id } })`.
The tests `sprite buffers: ...` (`engine/render/tests/sprite_buffer_tests.cpp`) run the placement, the hiding flag and every
error above.

**Where it runs** is the same as for meshes: Metal, Direct3D 11 and OpenGL 4.3 or newer. On Android (GLES3), the web (WebGL2) and
macOS OpenGL 4.1 the material is refused when it loads (error material, one log line naming the backend and the CPU path: write
the quads as entities, or as `"instanced"` params of a material without buffers). A driver with fewer than 2 storage-buffer
bindings per buffer refuses it too, naming the number it offers. The tests here ran on Metal only; the OpenGL and Direct3D 11
draws were not run.

### Where it runs

Compute needs a graphics API with compute shaders: **Windows** (D3D11), **Linux** (OpenGL 4.3 or newer), **macOS**
(Metal) and **iOS** (Metal). It does not exist on **Android** (OpenGL ES 3.0) or the **web** (WebGL2), nor on a macOS
that falls back to OpenGL 4.1. `render.supports computeShaders` says it for the running computer; there, every
`compute.*` command that needs the GPU fails with the code `unavailable`, naming the backend, so a game can check first and
use a CPU path instead. Nothing crashes and nothing is skipped silently. A compute material put on a `MeshRenderer` is
drawn with the error material and the log says why.

`factoria export` writes a twin for each platform that runs compute (`*.material.json.hlsl5.shader`, `.glsl430.shader`,
`.metal_macos.shader`, `.metal_ios.shader`) and a warning for each platform that does not, which the Android and Web
exports show. `material.info` lists `runsOn`.
