[Back to the index](../README.md)

# Commands: material

## `material.graph.generate` (modifies state)

Not released yet (on main after 0.31.0).

Generate the GLSL snippet of a material from its node graph and record its hash in the material file.

Capabilities: read, writeProject

Checks the "graph" of the material (as material.graph.validate), generates the snippet (readable GLSL, one line per node with a comment naming the node id; the same graph gives the same bytes) into the file named by "shader" and writes "graphHash" (SHA-256 of the snippet) into the material file. A snippet that does not match the recorded hash was edited by hand (or was written without a graph): the command refuses and changes nothing, because the edit would be lost. Then either pass force true to overwrite it, or delete "graph" from the material to keep the hand-written code. With dryRun true nothing is written. Writing the material file formats it again (2-space JSON). Returns {material, shader, state, written, hash, usedNodes, warnings}; state is the one material.graph.validate reports before the write. Run shader.compile afterwards. Example: {"material":"materials/dissolve.material.json"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `material` | string | yes | Project-relative path of the material, e.g. materials/dissolve.material.json. Path the command writes; the write rules apply (docs/CLI.md, "Paths"). |
| `force` | boolean | no | Overwrite a snippet that was edited by hand (or never generated). Default false. |
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

Checks the "graph" of a *.material.json: node ids and types, constants, the params and textures nodes name, links (unknown node or port, a second link into an input, type mismatches), cycles, the output node, nodes that need the fragment stage on the path of vertexOffset and the material kind. Every error has a JSON pointer into the material file, what is wrong and how to fix it. Returns {material, ok, errors: [{pointer, message, hint}], warnings, snippet: {path, state}}. state: "in_sync", "graph_changed" (the snippet is what the previous graph made: generate updates it), "hand_edited" (the snippet no longer matches graphHash: generate refuses without force), "unmanaged" (a snippet that no generator wrote), "hash_missing", "missing" or "unchecked" (the graph has errors). Example: {"material":"materials/dissolve.material.json"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `material` | string | yes | Project-relative path of the material, e.g. materials/dissolve.material.json. Path the command reads. |

## `material.info`

Since 0.2.0.

Describe a custom material: lighting, alpha mode, params with types, defaults, ranges and docs, textures, programs and compile state.

Capabilities: read

Reads a *.material.json (schemas/material.schema.json) and returns {material, doc, kind, shader, lighting, alphaMode, doubleSided, params: [{name, type, default, min?, max?, doc, implicit?}], textures: [{name, default, sampler, doc}], programs, compile: {state, dialect, toolFound, hint?}}. `kind` is "mesh" (default), "sprite", "sky", "post" or "compute"; the last three report programs [] and compile.state "unsupported" with the package that brings them in compile.hint. params are listed in the order of the uniform block (alphabetical); `implicit` marks alphaCutoff, which alphaMode "clip" adds by itself. `lighting` is "pbr", "unlit" or "custom" (the snippet defines light(), the engine's light loop calls it once per light). `programs` are the shader programs the material makes: mesh, mesh_skin, prepass and prepass_skin, plus shadow and shadow_skin when the snippet defines vertex() or the alpha mode is clip; a sprite material makes quad and quad_plain. compile.state is "compiled" when the cache holds this exact material for this machine's dialect, else "not_compiled" (run shader.compile); nothing is compiled by this command. A material file with errors returns them (JSON pointer, message, fix). Example: {"material": "materials/water.material.json"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `material` | string | yes | Project-relative path of the material, e.g. materials/water.material.json. |

