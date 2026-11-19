Part of [SHADERS.md](../SHADERS.md): the post-process materials (`"kind": "post"`). The material file, the params, the compiler
and the cache are the ones that page describes.

# Post-process materials

`"kind": "post"` makes a material that is one **full-screen pass of a camera's post-processing stack**: a vignette of your own,
an underwater tint, a heat haze, a depth-based fog, an outline from the normals. It is listed in `PostProcess.customPasses`
(the field of the `PostProcess` component, `docs.components`), next to the built-in effects. The file, the params, the textures,
the compiler, the cache, `factoria validate` and `factoria export` are the ones [SHADERS.md](../SHADERS.md) describes (the program is named `post`);
the snippet differs.

**The file.** `{"format": "factoria.material/1", "kind": "post", "shader": "shaders/<name>.post.glsl", "params": {...},
"textures": {...}}`. `lighting`, `alphaMode` and `doubleSided` do not apply (the pass is not lit and has no geometry): the
compiler refuses them with the reason. A graph (`graph`) is not available for post materials.

**The snippet** has one entry point, `void post(in PostInput i, inout PostSurface s)` (**required**), run for every pixel of the
camera's rectangle of the picture:

```glsl
struct PostInput {              // read-only, per pixel
    vec2 uv;                    // 0..1 over the camera's rectangle, origin top left, y down on every backend
    vec2 texel;                 // the size of one pixel in uv units (1 / size)
    vec2 size;                  // the camera's rectangle in pixels
    float time;                 // seconds of game time since the scene started (the same as fa_time.x)
};
struct PostSurface {
    vec4 color;                 // linear RGBA; arrives holding the picture at this pixel: change it, or replace it
};
```

and these helpers (every engine name starts with `fa_`, so a param may take any name that is not a GLSL keyword):

| Helper | What it gives |
|---|---|
| `vec4 fa_scene_color(vec2 uv)` | the picture at `uv` (0..1 over the rectangle, y down), bilinear, clamped to the rectangle: sample it around the pixel for a blur, a distortion or an outline |
| `float fa_depth(vec2 uv)` | the linear view depth in world units (along the camera's forward axis); 60000 where no mesh was drawn (the sky, sprites) |
| `vec3 fa_normal(vec2 uv)` | the view-space normal of the surface (x right, y up, z towards the camera); `vec3(0)` where no mesh was drawn |
| `vec3 fa_scene_rgb(vec3 c)` | an sRGB colour you picked (a `color` param) in the colour space of the picture |
| `fa_time` | `vec4`, `x` = seconds of game time (the engine clock, never the wall clock) |

The picture is **scene-linear HDR colour** (values above 1 survive) at the position you choose, before the exposure and the
tonemap unless you put the pass after them, so a tint or a glow is multiplied or added in light. In a scene with
`SceneSettings.colorSpace` `"gamma"` it is the sRGB-encoded picture the scene was drawn in (`fa_scene_rgb` returns the colour as it
is), so write the snippet with `fa_scene_rgb` for every colour you take from a param. The result is sanitised like the final pass:
a NaN or an infinity becomes 0, a negative colour 0. A pass writes opaque colour: the alpha channel is carried through.

**Depth and normals** come from the depth and normal prepass the SSAO, reflections and depth of field already use. The renderer
draws that prepass for a camera **only when a pass of it calls `fa_depth` or `fa_normal`**; a material that calls neither costs no
prepass. A scene with no mesh in view gives 60000 and `vec3(0)` everywhere. A GPU that cannot sample the depth
(`render.supports {"feature": "sampledDepth"}`) skips a pass that reads it (see "Errors" below).

**The list: `PostProcess.customPasses`** is an array (at most 8 entries) of
`{"material": "materials/vignette.material.json", "materialParams": {"amount": 0.6}, "enabled": true, "position": "after:bloom",
"name": "My vignette"}`:

- `material` (required) is the project path of a kind `"post"` material. `materialParams` overrides its params by name, as
  `MeshRenderer.materialParams` does (`material.info` lists them). `enabled` `false` keeps the entry in the list and draws
  nothing. `name` is only a label (logs, the editor).
- `position` puts the pass before or after a built-in effect, as `"before:<effect>"` or `"after:<effect>"`. The default is
  `"before:tonemap"`. The places the renderer has (the effects between two of them are the same place):

  | Position | Where the pass runs |
  |---|---|
  | `after:ssao`, `after:fog`, `before:ssr` | after the scene is drawn with its ambient occlusion and fog, before the reflections |
  | `after:ssr`, `before:sunShafts` | after the reflections, before the sun shafts |
  | `after:sunShafts`, `before:depthOfField` | after the sun shafts, before the depth of field |
  | `after:motionBlur`, `before:bloom` | after the depth of field and the motion blur, before the bloom |
  | `after:bloom`, `before:exposure`, `before:radialBlur`, `before:lensDistortion`, `before:chromaticAberration`, `before:tonemap`, `before:colorGrading` | after the bloom, right before the final pass (the exposure, the lens effects, the tonemap and the grading run fused in it) |

  A position that names an effect but is not a place (`before:ssao`: the ambient occlusion is part of the scene's own pass;
  `after:depthOfField`; `after:tonemap`: the picture is already in display colours there, not supported in this version) is
  refused with the reason and the ones that work. Passes at the same place run in **array order**, each reading the picture the
  one before wrote. An effect that is off does not change where the others go.
- A volume (a `PostProcess` that is not on a camera) adds its entries after the camera's own when its strength (weight times
  influence) is at least 0.5, the rule of every switch of a volume.
- A split screen draws each camera's list over its own rectangle of the picture.

**What goes wrong, and what you see.** A pass whose material is missing, did not build, is not a `"post"` material or needs
the depth on a GPU without it is **skipped**: the picture is drawn without that pass, the log says why once (with the compile
error), the render stats list the material in `materialFallbacks`, and `postprocess.get {"resolved": true}` lists the passes
the camera draws with `customPassProblems` for an entry that could not even be read. `postprocess.set` refuses a bad entry
(unknown key, unknown position, more than 8) before it writes anything, with the JSON pointer (`/fields/customPasses/1/position`).
The previous version of a material stays in use when a hot reload of its shader fails; saving a good one swaps it in a frame.
`render.supports {"feature": "postMaterials"}` says whether this renderer draws them.

**Cost.** Every enabled pass is one full-screen draw of the rectangle (and a copy when it is the only one: the picture is read
and written in two images), plus the prepass when it is read. Start with one or two passes; sample the picture a few times
per pixel, not dozens.

**Editor.** View > Post-processing has a "Custom passes" section: add a material from the project, switch a pass on or off,
move it up or down, change its position and material, edit its params with widgets, remove it. Each change is one
`postprocess.set` and one undo step.

### Vignette with a param

```json
{ "format": "factoria.material/1", "kind": "post", "shader": "shaders/vignette.post.glsl",
  "params": { "amount": { "type": "float", "default": 0.5, "min": 0, "max": 1, "doc": "How dark the corners get." } } }
```

```glsl
void post(in PostInput i, inout PostSurface s) {
    float d = distance(i.uv, vec2(0.5));
    s.color.rgb *= 1.0 - amount * smoothstep(0.35, 0.85, d);
}
```

Add it: `postprocess.set {"id": "camera", "fields": {"customPasses": [{"material": "materials/vignette.material.json",
"materialParams": {"amount": 0.7}, "position": "before:tonemap"}]}}`.

### Outline from the normals (reads the prepass)

```glsl
void post(in PostInput i, inout PostSurface s) {
    vec3 n = fa_normal(i.uv);
    float edge = 0.0;
    edge += 1.0 - dot(n, fa_normal(i.uv + vec2(i.texel.x, 0.0)));
    edge += 1.0 - dot(n, fa_normal(i.uv + vec2(0.0, i.texel.y)));
    s.color.rgb = mix(s.color.rgb, vec3(0.0), clamp(edge * 4.0, 0.0, 1.0) * step(0.5, length(n)));
}
```

Because it calls `fa_normal`, the renderer draws the prepass for the camera; remove the call and the prepass goes away.
