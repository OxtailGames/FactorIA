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
| `vec4 fa_history(vec2 uv)` | what **this pass** drew in the frame before, at `uv` (same `uv` as `fa_scene_color`, bilinear, clamped): a trail, a feedback, an accumulation. Calling it is what asks the renderer to keep the output; where there is none yet it returns the picture (see "History" below) |
| `fa_history_valid` | a `bool` value (not a function): true when `fa_history(uv)` returns last frame's output, false on the first frame and after a reset |
| `vec3 fa_scene_rgb(vec3 c)` | an sRGB colour you picked (a `color` param) in the colour space of the picture |
| `fa_time` | `vec4`, `x` = seconds of game time (the engine clock, never the wall clock) |

What the picture holds depends on the position:

- **Up to `before:tonemap`** it is **scene-linear HDR colour** (values above 1 survive), before the exposure and the tonemap, so a
  tint or a glow is multiplied or added in light. In a scene with `SceneSettings.colorSpace` `"gamma"` it is the sRGB-encoded
  picture the scene was drawn in.
- **From `after:tonemap` on** (the places between the screen effects, below) it is the **display-referred picture the effects
  before it made**: tonemapped (the exposure, the lens effects, the radial blur and the tonemap are done), **sRGB-encoded**, in
  0..1 on an ordinary display. On an HDR output or a float picture format the values above 1 survive, so do not clamp them.
  Sharpen, outline, posterize and the grain are drawn by the final pass in this encoding, and so is your pass: a tint is
  multiplied in display colours, as in a gamma scene, not in light. `fa_scene_rgb` returns the colour as it is there (a gamma scene
  and these places read the same way), so write the snippet with `fa_scene_rgb` for every colour you take from a param.

The result is sanitised like the final pass: a NaN or an infinity becomes 0, a negative colour 0. A pass writes opaque colour:
the alpha channel is carried through.

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
  | `after:bloom`, `before:exposure`, `before:radialBlur`, `before:lensDistortion`, `before:chromaticAberration`, `before:tonemap` | after the bloom, right before the final pass (the exposure, the lens effects and the tonemap run fused in it): **scene-linear** |
  | `after:tonemap`, `before:colorGrading` | after the exposure, the lens effects and the tonemap, before the colour grading: **display-referred** from here on |
  | `after:colorGrading`, `before:vignette` | after the colour grading (and its LUT), before the vignette |
  | `after:vignette`, `before:sharpen` | after the vignette, before the sharpen |
  | `after:sharpen`, `before:outline` | after the sharpen, before the outline |
  | `after:outline`, `before:posterize` | after the outline, before the posterize |
  | `after:posterize`, `before:filmGrain` | after the posterize, before the film grain |
  | `after:filmGrain`, `before:colorFilter` | after the film grain, before what the frame draws last (a flash or fade overlay, the dither, the colour filter) |

  A position that names an effect but is not a place (`before:ssao`: the ambient occlusion is part of the scene's own pass;
  `after:depthOfField`; `after:exposure`; `before:pixelate` and `after:pixelate`: the pixelate is not a step of its own;
  `after:colorFilter`: the colour filter is the last thing the frame draws) is refused with the reason and the ones that work.
  Passes at the same place run in **array order**, each reading the picture the one before wrote; places run in the order of the
  table, whatever the order of the array. An effect that is off does not change where the others go.
- **The display-referred places cut the final pass.** The exposure, the lens effects, the tonemap, the grading, the vignette, the
  sharpen, the outline, the posterize and the grain are one pass of the engine (`post.glsl`). Only where an entry sits at one of
  these places, that pass is drawn in two pieces: the effects before the place into an image, your pass(es), then the effects after
  it into the frame. A frame with no entry there draws the same one pass as always, at the same cost. What runs in the last piece
  is what the frame draws last: a flash or fade overlay, the dither of one 8-bit step (not when the posterize is on) and the
  colour filter. Things to know: the **pixelate** applies to every piece, so the picture is blocky again after your pass, and the
  **sharpen** after your pass compares a pixel with its neighbours in the picture your pass left. With the pixelate on and a cut
  before the sharpen, that picture is already blocky, so the sharpen finds no difference inside a block and only works on the
  edges between blocks.
- At most **32 entries** are drawn together for a camera and its volumes (8 per `PostProcess`); the entries after those are not
  drawn and the log says so once, naming the first entry left out (its place in `customPasses` and its material) and, for every
  other one left out that cannot be read, its own pointer and what is wrong with it.
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
and written in two images), plus the prepass when it is read. A display-referred place adds the cost of the cut: the final pass
is drawn in two pieces, so the picture is written and read once more per cut (places with no effect between them share one cut).
The pieces go through images of the picture's size in the format the display picture has (a float format when the scene has one,
so 8 bytes a pixel, about 66 MB at 4K; otherwise 8 bits, with R11G11B10 and sRGB scenes holding it in plain RGBA8), and in a float
format when the window shows HDR and the GPU can render to one (RGBA16F), so a pass that writes above paper white keeps it between
the pieces: one image when the camera has one cut, two when it has two or more. They are made when a frame needs them and freed
after 120 frames in which no camera has a cut. A pass that calls `fa_history` keeps two images of its camera's rectangle in the
picture's format (see "History").
Start with one or two passes; sample the picture a few times per pixel, not dozens.

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

### History

A snippet that calls `fa_history(uv)` reads **its own output of the frame before**: the pass draws into one of two images
while it reads the other, and the roles swap every frame. Nothing else is needed: calling the function is the request (there is
no flag, no param and no texture to declare, and a material that never calls it keeps no image). It is for trails, feedback,
motion smear, temporal accumulation and a screen that fades out slowly.

```json
{ "format": "factoria.material/1", "kind": "post", "shader": "shaders/trail.post.glsl",
  "params": { "keep": { "type": "float", "default": 0.9, "min": 0, "max": 0.99, "doc": "How much of the trail survives a frame." } } }
```

```glsl
void post(in PostInput i, inout PostSurface s) {
    // The new picture, or what the trail left, whichever is brighter. Before the first frame of the trail
    // fa_history gives the picture, so the pass starts without a flash.
    vec3 trail = fa_history(i.uv).rgb * keep;
    s.color.rgb = max(s.color.rgb, trail);
}
```

Whatever the pass writes this frame (`s.color`) is what the next frame reads, so a trail that decays is `max(picture, last * keep)`, an
accumulation `mix(last, picture, 0.1)`. `fa_history_valid` tells the two cases apart when they must differ:
`if (fa_history_valid) { ... }` (it is a value, not a call; the compiler says so). The history has the same orientation as the picture
on every backend (`uv` 0..1, origin top left), so a trail is never mirrored.

**When the history starts again.** `fa_history_valid` is false, and `fa_history(uv)` returns the picture, in the first frame of a
pass; when the camera's rectangle changes size (a resize, a split-screen layout, the render scale) or the picture's format changes;
when the camera was not drawn in the frame before (a new camera, one switched off for a frame, a `primary` that was `false`); at a
**cut** the renderer sees (another scene or a reload of it, the world's clock going back or jumping by more than 8 ticks, see below); and after
`render.reset_post_history` (`{"entity": "camera"}` for one camera, nothing for all), which you call at a cut it cannot see: a
camera teleported inside one scene, or moved to another place by a script. A frame that is not one of the game's (a
`capture_world` of another world, such as a thumbnail) neither reads nor writes any history, so it never disturbs a running trail.

**A slow game starts the history again every frame.** The clock test counts simulation ticks between two drawn frames, and a jump of
more than 8 ticks is a cut. At the default 60 ticks a second, a game that draws fewer than about 7.5 frames a second (more than 8
ticks between frames) never sees a valid history: every frame is the first of its trail, `fa_history_valid` stays false and
`fa_history(uv)` gives the picture, so the effect looks as if it were off. It is deliberate (a long gap is a seek or a stall, not
a trail), and a frame that is slow once only costs one restart.

**What is kept apart.** Each camera has its own history for each pass: two cameras of a split screen never read each other's, and
two entries of the same material in a list are two histories. A pass that is not the last of its chain hands its history image to the
next pass as its picture, so a chain with a history pass costs no extra copy; the last pass of a chain draws once more into the
picture, as a single pass always does. MSAA does not change anything: the passes work on the resolved picture. In a display-referred
place (`after:tonemap` on) the history holds display-referred colour, the same encoding the pass reads.

**Cost and limits.** Two images of the camera's rectangle in the picture's format (8 bytes a pixel for a float scene: about 66 MB each pair
at 4K, per pass and camera) and one sample more per `fa_history` call. They are made in the first frame that needs them and freed 120 frames
after the last frame that planned the pass (frames, not seconds: it does not depend on the speed of the machine). The histories of a
renderer take at most 1 GiB (256 MiB on the web); a pass that does not fit, or whose images the GPU refuses, is **drawn without its
history** (`fa_history_valid` stays false) and the log says why once, with the way out (a lower render scale, fewer passes that keep
a history). A pass whose images the GPU refused is not asked again every frame: it tries again when the camera's rectangle or the
picture's format changes, and when the game target is made again; one that went over the budget tries again at once the frame
another pass has freed its images. Changing the size of the game target frees all of them.

**Errors.** `fa_history` used as a texture, `fa_history_valid(...)` called as a function, or either in a material that is not
`"kind": "post"` are refused by `factoria validate` and `shader.compile` before sokol-shdc runs, with the line and the fix. A mistyped
name gets a "did you mean".
