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

A buffer in the file only describes the element; the buffer itself is created at run time with `compute.create_buffer`.
**Storage images** (a compute shader that writes a texture) are not available yet: write the result to a buffer.

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

From C++ the same is `Renderer::compute()` (`fa/render/compute.h`: `create_buffer`, `write_buffer`, `dispatch`, `read_buffer`).

Limits, all counts and never time: 64 buffers, 256 MiB each and 1 GiB in all, at most 65535 workgroups per dimension and
1048576 elements converted per write or read call. A request over one is refused with the number it hit.

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
