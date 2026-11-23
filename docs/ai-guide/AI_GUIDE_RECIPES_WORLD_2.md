# AI guide: recipes for the world, part 2

Part of [AI guide](../AI_GUIDE.md): recipes 9.19 to 9.21.2: 3D ground checks and raycasts, glow and tonemap, colour-blind players, sweeps, 2D water and glass, terrain. Recipes 9.9 to 9.18 are on [recipes for the world](AI_GUIDE_RECIPES_WORLD.md).

### 9.19 3D ground checks and raycasts

```js
import { Behaviour, physics, vec3 } from "factoria";

export default class GroundProbe extends Behaviour {
  onUpdate() {
    this.grounded = this.entity.isGrounded();   // 3D tolerance is 0.05 m by default
    // Distance to the floor below, ignoring this entity's own collider.
    const down = physics.raycast3d(this.entity.worldPosition, vec3(0, -1, 0), 5, { ignore: this.entity });
    this.height = down ? down.distance : Infinity;   // down = { entity, point, normal, distance } or null
  }
}
```

A collider that contains the ray origin is always skipped, so a ray that starts at the centre of a ball does not hit the ball. Use `ignore` when the ray starts outside the caster's own collider, for example just ahead of a body. The 3D `isTouching(direction)` works like the 2D one, for any direction.

### 9.20 Neon glow, exposure and tonemap: additive blend and the PostProcess stack

Glow is a camera setting, not artwork. Draw the bright things with `"blend": "additive"` (overlapping lights add up instead of covering each other), then add a `PostProcess` to the primary `Camera`'s entity and switch bloom on: every pixel brighter than `bloomThreshold` bleeds light into its surroundings. Do not hand-draw blurred halo sprites or stack translucent copies of a shape; they cost entities and never look as good. The `bloom`, `bloomThreshold`, `bloomIntensity`, `bloomRadius`, `bloomScreenSpace` and `colorFilter` fields that the `Camera` component had in older versions were removed in 0.33.0: a scene that still has them fails to load (the error names the file and the JSON pointer); use `PostProcess.bloomEnabled`, `bloomThreshold`, `bloomIntensity`, `bloomRadius`, `bloomScreenSpace` and `colorFilterEnabled` + `colorFilterMode`. To keep the look of the old hard threshold, set `bloomKnee` to 0: the PostProcess default is 0.5 (a soft knee), the old Camera fields behaved like 0.

```json
{ "id": "camera", "components": {
    "Camera": { "projection": "orthographic", "clearColor": [0.02, 0.02, 0.05, 1] },
    "PostProcess": { "bloomEnabled": true, "bloomThreshold": 0.6, "bloomIntensity": 1.2, "bloomRadius": 20,
                     "bloomScreenSpace": false } } },
{ "id": "ship", "components": {
    "Transform": { "position": [0, 0, 0] },
    "Shape2D": { "shape": "triangle", "size": [60, 60], "color": [0.1, 0.9, 1, 1], "pivot": [0.5, 0.3333],
                 "filled": false, "thickness": 4, "blend": "additive" } } }
```

- **Fields.** `bloomEnabled` turns it on (default off, so existing games are unchanged). `bloomThreshold` (0..20, default 0.7; 0..1 is the range of an ordinary scene) is the brightness where glow starts, measured as the largest of r, g and b, so a saturated colour such as `[1, 0, 0.8]` glows as much as white. Lower it to make dim colours glow, raise it so only the brightest things do. `bloomKnee` (0..1, default 0) softens the start: with 0 nothing at or below the threshold glows, with 1 colours a little below it already glow a little. `bloomIntensity` (0..10, default 1.2) is how much glow is added. `bloomRadius` (1..128 design pixels, default 20) is how far it reaches; radii below about 5 behave like 5. `bloomLensDirt` (a texture) with `bloomLensDirtIntensity` (0..10) shows smudges in the glow where the texture is bright.
- **Exposure and tonemap, the other half of the stack.** `exposureEnabled` with `exposureEv` (stops, each +1 doubles the light) brightens or darkens the whole picture before the tonemap; `exposureMode` `"auto"` follows the measured brightness of the frame (`exposureAdaptationSpeed` per second, kept between `exposureMinEv` and `exposureMaxEv`, plus `exposureEv`), needs a float render target (`render.supports {"feature":"floatTargets"}`) and is the same on every run for the same frames. `tonemapEnabled` with `tonemapMode` (`neutral`, `aces`, `agx`, `reinhard`, `none` = clip) brings light above white to the display; it matters when something draws above 1 (additive layers, `emissiveStrength`, a linear scene). Exposure, tonemap, the colour filter and the encode for the display are one pass. `PostProcess` on an entity WITHOUT a `Camera` is a volume (`shape` `box`, `circle`, `sphere` or `global`, `blendDistance`, `priority`, `weight`): the effects blend in as the camera enters it, e.g. a cave that darkens (`exposureEv` -1) or a hurt flash. Only the camera that draws first has its stack drawn today. `render.supports {"feature":"bloom"}` (or `exposure`, `tonemap`, `colorFilter`) says whether this build draws it.
- **Grading and lens effects, the same stack.** `colorGradingEnabled` (white balance `colorGradingTemperature`/`Tint`, `Lift`/`Gamma`/`Gain`, `Contrast`, `Saturation`, `HueShift`, and a `.cube` 3D LUT in `colorGradingLut` with `colorGradingLutContribution`), `vignetteEnabled`, `chromaticAberrationEnabled`, `lensDistortionEnabled` (the picture is black where the lens reads outside it: raise `lensDistortionScale`), `sharpenEnabled` and `filmGrainEnabled` (the same grain on every run of the same frames) are drawn in the final pass, in display space, and none of them clips above white. They cost one pass together (or none extra when exposure or tonemap is on). `assets.import` takes a `.cube` into `assets/luts/`. The `colorGradingCurve*` fields are stored but not drawn yet. docs/RENDERING.md, "The effects of the final pass".
- **Outline, pixelate, posterize.** Three more looks of the same final pass, in display space. `pixelateEnabled` + `pixelateSize` (blocks of that many design pixels, each showing its centre's colour) and `posterizeEnabled` + `posterizeLevels` (2..256 levels per channel, after the grading) cost no extra pass. `outlineEnabled` draws lines of `outlineWidth` design pixels in `outlineColor` (its alpha is the opacity): `outlineMode` `depth` (3D: where depth, found with `outlineDepthThreshold`, or the surface direction, `outlineNormalThreshold`, jumps; it turns the depth and normal prepass on, so only opaque meshes get lines) or `sprite` (2D: a line outside the border of sprites, tiles, shapes, text and particles, where their alpha reaches `outlineAlphaThreshold`; the 2D world is drawn once more into a coverage image while it is on). Both outline modes need ONE camera over the whole screen: with split screen or a camera `viewport` smaller than the screen the outline is skipped (one warning in `game.logs`), so do not promise it there. A width of 0 or a colour alpha of 0 draws nothing. `render.supports {"feature": "outline"}` says whether this GPU can. docs/RENDERING.md, "The outline".
- **Looks, and why the picture is what it is.** Start from a look instead of typing twenty fields: `postprocess.presets {}` lists `neutral`, `cinematic`, `retro`, `noir`, `dreamy`, `vivid` and `horror`, and `postprocess.apply_preset {"id": "camera", "preset": "cinematic"}` applies one (one undo step in the editor; without `"keep": true` it replaces the camera's whole stack with exactly the look, `neutral` clears it). A look can name an effect this GPU cannot draw (`render.supports` says `false` and why, e.g. `ssao` or `depthOfField` on a GPU that cannot sample the scene's depth): it is still applied and the answer lists it under `notDrawn`, so tell the user that part will not show here instead of promising it. To see what a camera really draws, and which entity or field sets each value (its own PostProcess or `volume:<id>`), call `postprocess.get {"id": "camera", "resolved": true}`; change one field with `postprocess.set {"id": "camera", "fields": {"bloomIntensity": 0.6}}`. In the editor, View > Post-processing shows the same stack with a "Stack off (A/B)" check to compare with the game drawn without it.
- **Dark background.** The glow is added on top of the picture, so it only shows on dark areas. Keep `clearColor` and backgrounds dark; a light background hides it.
- **Bright sources.** Sprites, shapes and particles that glow need a bright `color` (at or above the threshold). `ParticleEmitter` with `"blend": "additive"` plus bloom gives fire, sparks and explosions for free. In 3D, bright unlit meshes (`MeshRenderer.unlit`) and `emissive` surfaces glow the same way. `emissive` is a colour (0..1, an array with a channel over 1 is read as 0..255, so `[3, 2, 1]` is almost black); to glow brighter than white keep the colour at 0..1 and raise `MeshRenderer.emissiveStrength` (0..100, default 1): `"emissive": [1, 0.7, 0.3, 1], "emissiveStrength": 4` is an amber lamp four times brighter than white. The game is drawn into a float (HDR) target when the GPU can (`Renderer::hdr_scene()`; otherwise an 8-bit one, where everything clamps at white, also when the GPU refuses a float target with the requested multisampling), so the excess above white gives a bigger glow; the screen and screenshots stay 8-bit. A float target also changes the look of an existing game that already uses bloom: a specular highlight above 1 and an additive sum of several lights or particles now reach the bloom with their full strength, so the glow is bigger than it was in the 8-bit target, and it differs between a GPU that renders to RGBA16F and one that does not (that one keeps the old, clamped look). Compare a screenshot with `bloom` on before you keep `bloomIntensity` or `bloomThreshold` of a game made earlier; NaN and infinite pixels never glow. Meshes that differ only in `emissiveStrength` are not drawn in one batch, exactly like a different `emissive`.
- **HUD: crisp or glowing.** By default bloom is applied to the whole finished picture, screen-space items included, so white HUD text glows too. Set `"bloomScreenSpace": false` on the `PostProcess` (the recipe above does) to draw the screen-space items (Sprite, Shape2D and Text with `"space": "screen"`, and debug text) AFTER the bloom: the world glows and the HUD stays crisp, with translucent panels blending over the glow. Leave it `true` when a screen-space title or logo should glow, as on a title screen. Particles and tilemaps are world-space only, so they always glow. When exposure, a tonemap or (in a linear scene) a colour filter is on, the HUD is drawn over the finished picture in display colours: it is never exposed or tonemapped (white stays white) and never glows, whatever `bloomScreenSpace` says; the colour filter still covers it.
- **Shapes for neon.** `Shape2D` has `rectangle`, `circle`, `line`, `triangle`, `diamond` (a rhombus touching the middles of its `size` box; a square box gives a 45-degree square), `polygon` (`sides`) and `star` (`points`, `innerRadius`). Outlines (`filled: false`, `thickness`) read best under bloom. `pivot` is also the point a shape rotates around: a spinning `triangle` wobbles with the default pivot because the centre of its box is not its centre of mass, so give it `"pivot": [0.5, 0.3333]` (its centroid). The recipe above does.
- **Screenshots and tests.** The glow is part of the image (`factoria run --headless --screenshot-at`, MCP screenshots), and it is deterministic. Look at a screenshot after tuning; compare with `bloomEnabled: false` to see what it adds.
- **Animating it.** `this.entity.get("PostProcess").bloomIntensity = 1 + Math.sin(time.elapsed * 4) * 0.5;` pulses the glow from a script.
- **Cost.** A frame with no `PostProcess` adds no pass and no render target: the stack is free when it is off. Bloom reads the finished frame once, blurs a reduced-resolution copy and adds it back (4 to 7 extra passes, the number grows with the radius). Manual exposure, tonemap, colour filter and the display encode together are one full-screen pass; auto exposure adds two tiny ones (32x32 and 1x1). That is cheap on a GPU; the software renderer used for headless runs spends about 5 ms per drawn frame at 1280x720 on bloom. Headless tests and `factoria call` only draw when they take a screenshot, so the stack costs them nothing otherwise. `render.frame_graph` with `profileFrames` shows the time of each pass.

### 9.20.1 Colour-blind players: the colour filter and the colour-blind check

Roughly one player in twelve men and one in two hundred women cannot tell some colours apart, so a hazard that is only red against a green floor is invisible to them. Two separate tools:

- **Check it yourself (no change for the player).** `game_screenshot {"simulate":"deuteranopia"}` (also `protanopia`, `tritanopia`, `greyscale`), `game.screenshot(path, { simulate: "protanopia" })` in a test, or `factoria run --headless --screenshot-at 60 --screenshot-simulate deuteranopia`. The saved PNG shows what that viewer sees: look at it and ask whether every hazard, pickup, enemy and button is still found, by shape, outline, brightness or an icon, not only by hue. Take one normal screenshot and the `greyscale` one at least; add `deuteranopia` (the commonest) for red/green designs. The method: the pixels are taken as sRGB, decoded to linear light, multiplied by the Machado, Oliveira and Fernandes 2009 matrix of severity 1.0 (the cone is missing completely, the worst case) and encoded again; `greyscale` is Rec. 709 luminance in linear light. The check is done on the CPU on the saved file, so what the game draws is untouched.
- **Give it to the player.** The colour filter of the camera's `PostProcess` (`colorFilterEnabled: true`, `colorFilterMode`) is the last post-process of the frame (after bloom, HUD included), so screenshots, `--screenshot-at` and `--record-video` show it: `none` (default, no cost), `greyscale`, `highContrast` (contrast x1.8 around mid grey) and `protanopia`, `deuteranopia`, `tritanopia`, which are daltonize corrections for a player who lacks that cone: the loss is estimated with the same Machado matrix and the lost information is shifted into the channels the player still sees (Fidaner's method), so red and green end up differing in brightness and blue. The engine never saves the choice: put an option in the game's options screen that sets `colorFilterEnabled = true` and `colorFilterMode = "deuteranopia"` on the camera's `PostProcess` and keeps it in `storage` (the menu kit in [MENUS.md](../MENUS.md) has the button), and set it again in every scene, as every scene has its own camera.

Prefer designs that work without any filter (shapes, outlines, patterns); the filter is the safety net, the check is how you know.

### 9.21 Sweep a shape instead of a ray: will it fit, how far can it go

A ray is a line. When the thing that has to fit has a size (a character stepping into a gap, a crate being pushed, a dash, a placement preview), sweep its shape with `physics.shapeCast(shape, from, to, opts)`. It returns the same `{ entity, point, normal, distance } | null` as `raycast`; `distance` is how far the centre of the shape travels before it touches something.

```js
// scripts/dash.js: dash right as far as the player's own box fits, never into a wall (needs a "dash" input action).
import { Behaviour, input, physics, vec2 } from "factoria";

export default class Dash extends Behaviour {
  size = [28, 44];     // the same size as the player's Collider2D
  length = 120;

  onFixedUpdate() {
    if (!input.pressed("dash")) return;
    const p = this.entity.position;
    const from = vec2(p.x, p.y), to = vec2(p.x + this.length, p.y);
    // Skips the player's own collider (ignore) and anything it already overlaps at `from`.
    const hit = physics.shapeCast({ shape: "box", size: this.size }, from, to, { ignore: this.entity });
    const travel = hit ? hit.distance : this.length;     // hit.normal is the wall's surface normal
    this.entity.position = [p.x + travel, p.y];
  }
}
```

- **Shapes.** 2D: `{ shape: "circle", radius: 8 }` or `{ shape: "box", size: [w, h] }` (pixels). 3D (pass 3D `from`/`to`): `{ shape: "sphere", radius: 0.5 }` or `{ shape: "box", size: [x, y, z] }` (meters). Full sizes, like the colliders; the shape is centred on the cast position and never rotates. Sweep a capsule collider with a box or circle of similar size.
- **Where it stops.** At contact: in 2D, to a fraction of a pixel, so moving the centre by `distance` puts the shape against the surface, not into it.
- **Touching is not overlapping.** A body standing on the ground touches it: a cast down hits at once (`distance` about 0, `normal` up) and a cast up or sideways ignores the ground. A collider the shape is deeper inside than 1 cm (1 pixel at the default 100 pixels per meter) is skipped, as a ray starting inside a collider is. Put `ignore: this.entity` for the caster's own collider.
- **Not for** testing a spot (`from === to` returns `null`; use `overlapBox` / `overlapCircle`), ground checks (`isGrounded`) or walls (`isTouching`).
- From outside a script, the command `physics.shape_cast` does the same: `{"shape":{"shape":"box","size":[28,44]},"from":[0,100],"to":[120,100],"ignore":"player"}`.
- A wrong shape throws an Error that names the problem and shows an example, for instance `"sphere"` in a 2D cast (`"circle"` is the 2D name) or a misspelt `"circel"` (did you mean `circle`).

### 9.21.1 Water, heat haze and glass in 2D: the picture drawn so far

`Water2D` is a pool that refracts what is under its surface and mirrors what is above it; `DistortionZone2D` bends the picture inside a rectangle (heat over a brazier); a sprite material that calls `fa_scene_color(uv)` reads the picture too (frosted glass, a lens). Nothing is on until you add one, and a frame without one pays nothing.

```json
{ "id": "pool", "components": {
    "Transform": { "position": [640, 190, 0] },
    "Water2D": { "size": [760, 220], "tint": [0.08, 0.3, 0.42, 0.5], "reflection": 0.7, "refraction": 5, "waveAmplitude": 2.5, "waveLength": 70, "waveSpeed": 0.6 } } },
{ "id": "haze", "components": {
    "Transform": { "position": [1100, 470, 0] },
    "DistortionZone2D": { "size": [130, 170], "strength": 3 } } }
```

- **The top edge of the area is the surface**, so put the entity half the height under the line you want (a pool 220 high with its surface at y 300 is at y 190). The reflection only shows what is on screen: put the lanterns where the mirror image falls inside the picture.
- **Layers decide what is under the water.** `Water2D.layer` is 10 and `DistortionZone2D.layer` 20: sprites on lower layers are refracted and reflected, sprites on higher layers (the player in front of the pool, a log floating on it) are drawn over it untouched. Two readers one after the other share one copy of the picture and do not see each other; a sprite on a layer between them separates them.
- **Cost.** Each run of readers costs one copy of the camera's rectangle, at most 8 per camera and frame (the log says so once past that; `game.render_stats` has `sceneCopies`). `render.supports {"feature":"2dWater"}` is true on every backend.
- **Your own look.** `Water2D.material` / `DistortionZone2D.material` take a sprite material that reads `fa_scene_color(i.screen_uv + ...)` and `fa_world_to_uv(vec3(x, y, 0))`; the component's fields arrive as the params of the same names that the material declares. A material that does not build draws the area magenta (`materialFallbacks` names it). The waves follow the engine clock, so a replay shows the same water.
- Full reference: `docs.read rendering-2d-water`; the material API: `docs.read shaders-sprites`, "The scene colour". A scene to copy: `examples/lantern-keep/scenes/cellar_pool.scene.json` (if you got it with `project.create {example: "lantern-keep"}`).

### 9.21.2 A terrain: a heightmap as ground you can see and walk on

Use a `Terrain` for ground wider than a few hundred metres, where a mesh of the whole landscape would be too heavy: the renderer draws a quadtree of tiles that coarsen with distance, so the cost follows what the camera sees, not the size of the map. For a small level a MeshRenderer ground is cheaper to author. It is off until an entity has the component, and then costs nothing else.

```json
{ "id": "ground", "components": {
    "Transform": { "position": [0, 0, 0] },
    "Terrain": { "heightmap": "assets/terrain/height.png", "size": [2048, 2048], "heightScale": 180,
                 "layers": [ { "albedo": "assets/terrain/grass.png", "tileSize": 6 } ] } } }
```

- **The heightmap** is a 16-bit greyscale PNG or `.r16` file, square, a side of 2^n + 1 (33 to 4097) samples; an 8-bit PNG works but steps show as terraces. Resolution and `size` are independent.
- **Layers, splat maps and holes.** Up to 8 `layers` (albedo and normal map tiled every `tileSize` metres, `roughness`, `metallic`, `normalScale`) are blended by two RGBA `splatMaps` (channel c of map m weights layer 4m+c; no map = layer 0 everywhere). All the albedo textures must be ONE size (at most 4096), and so the normals: a layer of another size is an error naming `/layers/3/albedo` and both sizes. A missing texture leaves its layer neutral grey. `holes` (a pixel of 128 or more) is cut out of the surface, its shadow and its collider; `terrain_sample` and a ray see no ground there.
- **Make it with commands, not by hand.** `terrain.create {"name":"ground","size":[1024,1024],"resolution":513}` writes a flat 16-bit heightmap and the entity; `terrain.generate {"entity":"ground","seed":7,"erosion":50000}` fills it with seeded noise and erosion (same arguments, same terrain); `terrain.sculpt {"entity":"ground","tool":"raise","center":[100,50],"radius":20,"amount":5}` shapes it; `terrain.holes` cuts a cave mouth; `terrain.paint` weights a layer. Each is live and ONE undo step (`terrain.undo`); the files are written by `save: true`, `terrain.save` or `scene.save`.
- **Collision** (`collision`, default true) is automatic: a ray or a falling body meets the surface that is drawn, with no Collider3D. To know the ground height under a point, cast a ray down at it (see 9.19). A sculpt moves the collider with the picture.
- **Cost.** `game.render_stats` has `terrainTiles` and `terrainTriangles` (2048 per tile). A 4097 x 4097 map holds 33.5 MB of GPU texture, 33.5 MB for the CPU copy and 67 MB for the collider, 16.8 MB for a holes mask, up to 128 MB for two splat maps of 4096 x 4096, and a sculpt or a paint stroke sends only the rectangle it changed. The layer pictures are decoded off the main thread: a terrain with new layers is grey for a few frames. A GPU whose largest texture is below the map's side draws nothing and says so once (`render.supports {"feature":"terrain"}` is true on every backend; its `limits` give `maxTextureSize`, `maxArrayLayers` and `maxArrayTextureSize`). `lodQuality` trades distance for tiles: 0.5 draws a coarser terrain, 2 a finer one.
- Full reference: `docs.read big-worlds`, section "Terrain".
