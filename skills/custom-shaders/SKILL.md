---
name: custom-shaders
description: Write and compile a custom material shader. Read when a look needs one.
---

# Custom shaders

`MeshRenderer.material` names a `materials/*.material.json` (a GLSL `surface()` snippet that changes
what the standard material computed, optional `vertex()`, typed params). Write the two files, call `shader.compile`
(MCP `shader_compile`) until `ok`, then look at a screenshot. Full guide with five worked examples: `factoria docs read shaders`.

The full guide is `factoria docs read shaders` (MCP `docs_read {"name":"shaders"}`).
