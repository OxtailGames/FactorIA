Part of [RENDERING.md](../RENDERING.md) and [Lighting (M73)](RENDERING_LIGHTING.md): transmission and volume, the glass and liquids of the standard mesh shading,
and the material cost view that says which features of a material cost an extra pass.

# Rendering: transmission, volume and the material cost

## Glass and liquids (M73-P6b)

A mesh with `MeshRenderer.transmission` above 0 lets light through instead of reflecting all of it: windows, bottles, water, gems. It shows what is
behind it, refracted, blurred by its roughness and tinted by its volume.

| Field | Values | Default | What it does |
|---|---|---|---|
| `transmission` | 0..1 | 0 | Share of the light that goes through the surface (the part the specular reflection does not take). 0 = opaque. Multiplied by `1 - metallic`. |
| `thickness` | metres, 0 and up | 0 | How far the light travels inside the volume: it offsets where the picture behind is read (the bigger, the stronger the refraction) and sets how much `attenuationColor` tints it. 0 = a thin sheet: no offset and no tint. |
| `attenuationColor` | colour | white | The colour the light has after `attenuationDistance` metres inside. White = no tint. |
| `attenuationDistance` | metres, 0 and up | 0 | 0 = the light is not tinted inside (glTF's infinite distance reads as 0). |
| `ior`, `roughness`, `color` | see [Lighting](RENDERING_LIGHTING.md) | 1.5, 0.5, white | The index of refraction sets how much the surface reflects (and how far the roughness blurs: `ior` 1 does not blur); `roughness` blurs what is seen through; `color` tints it (the glass' own colour). |

glTF models bring the fields with them: `KHR_materials_transmission` (`transmissionFactor`), `KHR_materials_volume` (`thicknessFactor`,
`attenuationColor`, `attenuationDistance`) and `KHR_materials_ior` read into the material layers of each part of the model, and the exporter writes them
back. `transmissionTexture` and `thicknessTexture` are not used: the factor applies to the whole surface, and the import warns once per material with
the file, the material and what is used instead. A material that sets no `transmission` of its own takes the model's, as with the other layers.

### What is drawn

- The transmitted light of a point is the picture of the opaque scene at the place the light came from, times what the surface lets through
  `(1 - reflectance) * color * transmission`, times the Beer-Lambert attenuation of the volume,
  `exp(-(-ln(attenuationColor) / attenuationDistance) * thickness)`. The surface's reflections (sun, lights, environment) are drawn on top as for any
  other mesh.
- **Refraction offset.** With `thickness` above 0 the point is moved along the refracted view ray (`refract(view, normal, 1 / ior)`) by `thickness`
  metres and projected back to the screen: a ball shows the scene flipped and magnified, a flat pane shifts it. With `thickness` 0 the scene is seen straight
  through (a thin sheet).
- **Roughness.** The scene is read from a chain of half-size copies; the level is `roughness * clamp(2 * ior - 2, 0, 1) * (levels - 1)`, blended between the two
  nearest levels with a bilinear tap each (the filtering is done in the shader, by hand: the picture's image is declared unfilterable because it is
  also the contact shadows' depth image of the opaque phase). A smooth glass (roughness 0) reads the full-size picture.
- **Faces.** A glass mesh draws only the faces that look at the camera (back faces are culled), unless the entity is `doubleSided`: the inner wall of a
  closed ball would otherwise refract over its front.
- **Order.** A transmissive mesh is drawn in the blended phase (with the meshes whose alpha is below 1 and the `blend` materials), far to near, after
  the opaque ones.

### How it costs

The blended phase cannot read the image it draws into, so when a visible draw is transmissive the main pass is split: the opaque meshes, the sky, the
ambient occlusion and the fog are drawn, the picture is copied into a "refraction atlas" (level 0 is the camera's rectangle, levels 1 to 4 are halves of it,
one draw each), and the pass goes on with the blended draws, which read the atlas at texture view 28 (`fa_screen_tex`; the contact shadows' depth image takes
its place only in the opaque phase). Cost: one split of the main pass, one copy draw, up to four reduction draws and one atlas draw, and the atlas image
(1.5 times the picture at most, in the colour format of the picture). The material cost view below counts them.

- A frame with no visible transmissive draw (none exist, or all are culled) makes no copy and draws exactly the pixels it drew without the feature.
- Many glass meshes in one frame cost one copy, not one each. Each camera of a split screen copies its own rectangle.
- The render scale, the MSAA resolve, the render graph and the partial rectangles of split screens are respected: the copy reads the resolved picture of the
  camera's rectangle, in the scale it is drawn at.
- `RenderStats` (`render.stats`): `transmissiveMeshes` (visible transmissive instances), `transmissionCopies` (copies made this frame) and
  `transmissionPlain` (cameras that blended their glass plainly, see below).

### What it does not do

- **Glass does not see glass.** The copy is made before the blended draws: a transmissive mesh behind another transmissive one is not in the picture the front one
  refracts (it is still drawn, and the front glass shows what the opaque scene holds there). The same for particles and other blended meshes.
- **Opaque objects in front of the glass can leak.** The refracted read is a screen-space lookup: where it lands on an object that is nearer than the glass
  (a hand holding a bottle), that object's colour shows through the glass. A thin `thickness` keeps the offset small.
- **Thickness is in world metres.** It is not scaled by the entity's `Transform.scale`, and there is no thickness texture.
- **Full shaders and a custom lighting get no transmission**: a mesh with a `full` material (docs/shaders/SHADERS_FULL.md) or whose material replaces the
  lighting draws as an ordinary mesh (the `transmission` field is read only by the standard shading, the `fa_surface` hook can set the new `Surface` fields:
  [SHADERS_LIGHTING.md](../shaders/SHADERS_LIGHTING.md)).
- Fog is applied again to the result (a glass in thick fog is as foggy as the wall behind it).

### When the copy cannot be made

If the shader of the copy or one of its images cannot be created (a GPU that refuses the atlas), the camera's transmissive draws are blended plainly: the mesh keeps
its reflections and darkens what is behind it by what it lets through (tinted by the attenuation), with no refraction and no blur. `transmissionPlain` counts those
cameras, the log says so once per picture size, and the frame is otherwise the normal one. `render.supports {"feature":"transmission"}` answers true on every GPU
(the glass is always drawn, plainly in the worst case); `render.stats` tells which of the two happened.

## The material cost view

`render.material_cost {id}` answers what the material of one entity's `MeshRenderer` costs the renderer, in the words of the renderer's own decision (the
same code that plans the frame answers, so the view cannot disagree with what is drawn):

```json
{ "id": "window", "extraPasses": 6, "phase": "blended",
  "summary": "transmission (+6 passes); 6 extra passes in all",
  "features": [
    { "name": "transmission", "field": "transmission", "active": true, "cost": "extraPass", "extraPasses": 6, "note": "Copies the opaque picture once per camera (…)" },
    { "name": "blended", "field": "color", "active": false, "cost": "phase", "extraPasses": 0, "note": "Off (opaque, or transmissive: see transmission)." },
    { "name": "subsurface", "field": "subsurface", "active": false, "cost": "extraPass", "extraPasses": 0, "note": "Off (…)" } ] }
```
(Shortened: the real answer lists every feature below.)

- `features` lists every feature the material can use: `transmission` (the copy and its reductions, shared by every glass mesh of the frame, so the number is
  what the first glass costs), `blended` (the phase, no pass), `multiPass` (a full shader's extra passes), `clearCoat`, `sheen`, `anisotropy` (a longer shader, no
  pass) and `subsurface` (the sss draw, two blurs and the add: [Subsurface scattering](RENDERING_LIGHTING.md)). `cost` is `extraPass`, `phase` or `shader`;
  `active` says whether this entity uses it; `note` says why, in a sentence.
- `extraPasses` sums the active ones. `summary` is one line the editor shows as it is: each active feature (with its passes), then the total.
- The editor's inspector shows the same report under the MeshRenderer fields ("Render cost"), refreshed about twice a second; the editor does not compute the
  cost itself.
- A project without a renderer (the command line without a window) answers `unavailable`.
