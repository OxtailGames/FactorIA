[Back to the index](../README.md)

# Commands: material

## `material.info`

Since 0.2.0.

Describe a custom material: lighting, alpha mode, params with types, defaults, ranges and docs, textures, programs and compile state.

Capabilities: read

Reads a *.material.json (schemas/material.schema.json) and returns {material, doc, kind, shader, lighting, alphaMode, doubleSided, params: [{name, type, default, min?, max?, doc, implicit?}], textures: [{name, default, sampler, doc}], programs, compile: {state, dialect, toolFound, hint?}}. `kind` is "mesh" (the default), "sprite", "sky", "post" or "compute"; mesh and sprite materials compile now, the others report programs [] and compile.state "unsupported" with the package that brings them in compile.hint. params are listed in the order of the uniform block (alphabetical); `implicit` marks alphaCutoff, which alphaMode "clip" adds by itself. `programs` are the shader programs the material makes: for a mesh material mesh and mesh_skin, plus shadow and shadow_skin when the snippet defines vertex() or the alpha mode is clip, and prepass and prepass_skin (the depth and normal prepass of the post effects that read the depth); for a sprite material quad (every mode of the 2D pipeline) and quad_plain (batches of plain textured quads). compile.state is "compiled" when the cache holds this exact material for this machine's dialect, else "not_compiled" (run shader.compile); nothing is compiled by this command. A material file with errors returns them (JSON pointer, message, fix). Example: {"material": "materials/water.material.json"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `material` | string | yes | Project-relative path of the material, e.g. materials/water.material.json. |

