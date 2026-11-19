[Back to the index](../README.md)

# Commands: material

## `material.graph.generate` (modifies state)

Not released yet (on main after 0.31.0).

Generate the GLSL snippet of a material from its node graph and record its hash in the material file.

Capabilities: read, writeProject

Checks the "graph" of the material (as material.graph.validate), generates the snippet (readable GLSL, one line per node with a comment naming the node id; the same graph gives the same bytes) into the file named by "shader" and writes "graphHash" (SHA-256 of the snippet) into the material file. With `graph` the command checks, stores and generates that graph instead of the one in the file (the node editor saves through it, so the snippet and the hash have one writer). A snippet that does not match the recorded hash was edited by hand (or was written without a graph): the command refuses and changes nothing, because the edit would be lost. Then either pass force true to overwrite it, or delete "graph" from the material to keep the hand-written code. With dryRun true nothing is written. Writing the material file formats it again (2-space JSON). Returns {material, shader, state, written, hash, usedNodes, warnings}; state is the one material.graph.validate reports before the write. Run shader.compile afterwards. Example: {"material":"materials/dissolve.material.json"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `material` | string | yes | Project-relative path of the material, e.g. materials/dissolve.material.json. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `force` | boolean | no | Overwrite a snippet that was edited by hand (or never generated). Default false. |
| `graph` | object | no | A graph to store in the material and generate the snippet from, instead of the one the file holds (the node editor saves this way). |
| `dryRun` | boolean | no | Check and report what would be written, and write nothing. Default false. |

## `material.graph.nodes`

Not released yet (on main after 0.31.0).

List the node types of the material graph library, with their inputs, outputs and the kinds they work in.

Capabilities: read

Returns {format, kinds, categories, nodes: [{type, category, doc, kinds, stage, needs?, inputs: [{name, type, default?, doc}], outputs: [{name, type, doc}]}], example}. `format` says how the "graph" of a *.material.json is written; `example` is a complete material (a dissolve) whose graph passes material.graph.validate. An input type "gen" is a float or a vector; a float widens by itself. `stage` is "fragment" for nodes that sample textures or read the view direction (not allowed in the path of the output's vertexOffset). Filters: `kind` ("mesh"), `category`, `type`. Example: {"category":"noise"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `kind` | string | no | Only nodes that work in this material kind ("mesh"). |
| `category` | string | no | Only this category: constant, input, texture, math, noise, effect or output. |
| `type` | string | no | Only this node type, e.g. "noise.fbm". |

## `material.graph.validate`

Not released yet (on main after 0.31.0).

Check the node graph of a material and say whether its snippet is in sync with it.

Capabilities: read

Checks the "graph" of a *.material.json: node ids and types, constants, the params and textures nodes name, links (unknown node or port, a second link into an input, type mismatches), cycles, the output node, nodes that need the fragment stage on the path of vertexOffset and the material kind. Every error has a JSON pointer into the material file, what is wrong and how to fix it. Returns {material, ok, errors: [{pointer, message, hint}], warnings, snippet: {path, state}}. state: "in_sync", "graph_changed" (the snippet is what the previous graph made: generate updates it), "hand_edited" (the snippet no longer matches graphHash: generate refuses without force), "unmanaged" (a snippet that no generator wrote), "hash_missing", "missing" or "unchecked" (the graph has errors). With `graph` (an object like the one in the file) that graph is checked instead of the file's: the editor's canvas validates the graph it holds in memory this way, against the params, textures and kind of the saved material. Example: {"material":"materials/dissolve.material.json"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `material` | string | yes | Project-relative path of the material, e.g. materials/dissolve.material.json. Path the command reads. |
| `graph` | object | no | A graph to check instead of the one in the file (same format as "graph" of the material). Pointers still start at /graph. |

## `material.info`

Since 0.2.0.

Describe a custom material: lighting, alpha mode, params with types, defaults, ranges and docs, textures, programs and compile state.

Capabilities: read

Reads a *.material.json (schemas/material.schema.json) and returns {material, doc, kind, mode, shader, lighting, alphaMode, doubleSided, params: [{name, type, default, min?, max?, doc, implicit?, instanced?}], textures: [{name, default, sampler, doc}], vertexAttributes?, instanceLayout?, programs, compile: {state, dialect, toolFound, hint?}}. `kind` is "mesh" (default), "sprite", "sky", "post" or "compute". params are listed in the order of the uniform block (alphabetical); `implicit` marks alphaCutoff, which alphaMode "clip" adds by itself. compile.state is "compiled" when the cache holds this exact material for this machine's dialect, else "not_compiled" (run shader.compile); nothing is compiled by this command. A material file with errors returns them (JSON pointer, message, fix). Example: {"material": "materials/water.material.json"}

`lighting` is "pbr", "unlit" or "custom" (the snippet defines light(), the engine's light loop calls it once per light, or lighting(), your own loop). `programs` are the shader programs the material makes: mesh, mesh_skin, prepass and prepass_skin, plus shadow and shadow_skin when the snippet defines vertex() or the alpha mode is clip; a sprite material makes quad and quad_plain, a sky material one program, sky, a post material one, post. `mode` is "snippet" or "full". A full-shader material (the file holds your own vertex and fragment stages, docs/shaders/SHADERS_FULL.md) has no lighting, alphaMode or doubleSided; it returns shadow ("depth", "custom" or "none"), prepass and passes [{name, cull, depthTest, depthWrite, blend, program, programSkin}], and its `programs` list one program and one skinned program per pass (mesh, mesh_skin, pass1, pass1_skin, ...), then shadow and shadow_skin for "custom", then prepass and prepass_skin. A compute material also returns workgroupSize [x, y, z] and buffers [{name, binding, access, stride, doc, fields: [{name, type, offset, doc}]}] (std430 layout); `runsOn` and `notOn` list the platforms the kind has shaders for (compute: not android or web). `instanced` marks a mesh or sprite param whose value every entity (sprite: every quad) gives itself inside ONE draw (it travels in the instance data instead of the uniform block); `instanceLayout` {vec4, slots: [{name, vec4, offset, components}]} says where; `vertexAttributes` lists the extra mesh channels (uv1, color1) vertex() reads as vertex_uv1 and vertex_color1 (docs/SHADERS.md, "The material file").

| Argument | Type | Required | Description |
|---|---|---|---|
| `material` | string | yes | Project-relative path of the material, e.g. materials/water.material.json. |

