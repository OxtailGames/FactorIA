Part of [RENDERING.md](../RENDERING.md): the emission, light layers, cookies, rim light and generated normal maps of the 2D renderer (M74.2).

# Rendering: 2D emission and light masks

What a 2D visual can add to the picture the lights make of it, and which lights reach it. Every field here has a default that leaves a
scene exactly as it was: a scene that sets none of them draws the same pixels at the same cost. `render.supports` has one row for each
(`2dEmission`, `2dLightLayers`, `2dLightCookies`, `2dRimLight`, `2dGeneratedNormals`; `render.supports {"feature": "2dEmission"}`).

## Emission

`Sprite.emissive` (a colour, black = none), `emissiveIntensity` (an HDR multiplier, default 1) and `emissiveMap` (a texture laid out like
the sprite's own: where the sprite glows; empty = the whole sprite) make a sprite give out light. `Tilemap.emissive` and
`Tilemap.emissiveIntensity` do the same for every tile of a map. (`Shape2D` has no emission: draw it with a bright `color`, or an
additive blend.)

- The emission is added AFTER the lighting, to lit and unlit visuals alike, so it needs no light and no ambient light to show: a sprite
  that glows in a pitch-black room is `emissive` and nothing else. The alpha of the colour is ignored; the sprite's own alpha and the blend
  mode shape it like they shape its picture.
- The colour is picked as sRGB, like every colour, and multiplied by `emissiveIntensity` in the scene's linear HDR range, so a value over 1
  feeds the bloom: a camera with `PostProcess.bloomEnabled` makes a halo around an `emissiveIntensity` 4 sprite, while the sprite itself
  stays at white on the screen. A lamp shade that must glow without a halo stays at 1 and under the bloom threshold.
- `emissiveMap` multiplies the colour by the texture, decoded the way the engine decodes any texture. A texture that cannot be read is
  logged once with suggestions and then shows the engine's checker.
- It costs nothing for a visual whose `emissive` is black (the batch draws as it did). A visual with emission is drawn by the full 2D
  program instead of the lean one for plain sprites (a little more work per pixel, and it does not batch with the plain sprites around it),
  plus one texture read per pixel when it has an `emissiveMap`.

## Light layers

Every `Light2D` has `lightLayers` (a bit mask, default -1 = every layer) and every `Sprite`, `Shape2D` and `Tilemap` has `lightLayers` (default
1 = layer 0). **A light lights a visual only when `light.lightLayers & visual.lightLayers` is not 0**, for point and directional lights, in the
light buffer and in the per-pixel path of a normal-mapped visual. The default pair (-1 and 1) always meets, so a scene that sets nothing is
unchanged. Visuals without `lit` ignore every light and every mask.

Use the layers to keep a torch from lighting the background, a flashlight from lighting a HUD tile map, or a room's lamps from lighting the
next room's props: give the lamps bit 2 and the props of that room bit 2 too.

### How it is drawn

Light layers are decided per batch, so the picture never depends on how the quads were sorted:

- Lit visuals WITHOUT a normal map read one buffer of the point lights (the light buffer, a sum of every light drawn as a soft disc).
  A scene whose lights and visuals all share the default mask has ONE buffer holding every point light: the cost is the cost it had before
  light layers existed.
- With masks, the renderer finds the distinct receiver masks in view and, for each, the set of point lights that reach it. Masks that
  reach the same set share a buffer, so a scene where two layers see the same lights still has one buffer; a mask that reaches no point
  light needs none (the visual gets the ambient light and the directional lights only).
- **At most 4 buffers per frame** (an RGBA16F target the size of the game image, scaled by `SceneSettings.lightScale`, each). When the visuals in view
  need more distinct sets, the extra masks fall back to the per-pixel loop over the first 16 lights of the frame (the same
  rule, applied per light), and the engine warns once per scene with a hint: use fewer distinct masks in view, or give the lights that
  must stay apart distinct bits. A mask that falls back reads at most 16 lights, so beyond them the lights do not reach it.
- A normal-mapped visual always reads the per-pixel loop (the direction of each light matters), which zeroes the lights that do not
  reach its mask. Directional lights that do not reach a batch are left out of its flat ambient light.
- The number of masks is counted from the visuals in view, so a layer nothing on screen uses costs nothing.

The shadow casters of M74 (`ShadowCaster2D.lightLayers`, and the solid tiles of a `Tilemap` with `occludesLight`) use the same bits to say
which lights they block; this page is about which lights a visual receives.

## Cookies

`Light2D.cookie` is a texture the light shines through: where it is black or transparent no light arrives, where it is white and opaque the
light is as bright as without a cookie (the light's multiplier is the picture's brightness times its alpha, so a grey picture or a white
shape on a transparent one both work; the picture's colours do not tint the light, use `Light2D.color`). `cookieRotationDeg` turns the
picture around the light, `cookieScale` sizes it: the picture covers a square of side `2 * radius * cookieScale` world units centred on the
light (1 = the light's whole diameter) with its top towards world +y, and the light is cut off beyond that square, so a cookie scaled
below 1 also narrows the lit area to the square. The picture does not turn with the light's entity: only `cookieRotationDeg` turns it.
Only point lights have cookies.

- The cookie multiplies the attenuation of the light in both paths (the buffer and the per-pixel loop), so several lights can have cookies
  at once, each with its own picture, turn and scale.
- The pictures are copied into one atlas (4x4 cells of 256 pixels, RGBA8) once per frame, **one cell per distinct texture**: ten lights that
  use the same file cost one cell. A picture of any size is stretched into its square cell, so make cookies square (a 2:1 picture is squashed).
  At most 16 distinct cookie textures are used in a frame: a light past them shines without its cookie and the engine warns once per scene
  with a hint to share files or to pack several shapes in one picture. A cookie packed in an export's texture atlas works.
- The atlas is copied again only when the cookies of the frame (or one of their files) change. A cookie can be a live texture, a camera's
  `target:<name>` or a compute image: those change every frame, so a frame with one copies the atlas every frame.
- A cookie texture that does not exist is logged once, with the closest file names (`Did you mean assets/cookie_window.png?`), and the light
  shines without it.
- The atlas costs nothing in a scene where no light has a cookie.

## Rim light

`Sprite.rimIntensity` above 0 (default 0 = none) draws a rim of `rimColor` along the edge of a **lit** sprite that faces a light:
`rimColor * rimIntensity` times that light's contribution (its colour, intensity, attenuation, shadow and cookie), brighter where the edge's
normal points at the light and nothing where it faces away. `rimWidth` is the width of the rim as a fraction of the sprite's smaller side.

- The edge comes from the alpha gradient of the sprite's texture: the picture is looked up a little to the left, right, above and below
  of each pixel, and the pixel is on the rim where one of those lookups is transparent. So **a rim needs a texture** (a sprite with no
  texture has no edge) **and a transparent margin around the drawing**: a frame of a sprite sheet needs transparent padding, or the
  edge of the frame is not an edge. A sprite whose picture touches its own border has no rim there.
- The rim reads the first 16 lights of the frame, as the per-pixel path does, and obeys the light layers.
- It is shaded by the light, not by the sprite's own normal map: it works with or without `normalMap`.
- A sprite with `rimIntensity` 0 draws as before.

## Generated normals

`Sprite.normalFrom` says where a lit sprite's normals come from:

| Value | Normals |
|---|---|
| `file` (default) | `Sprite.normalMap`, as before |
| `sprite` | made from the sprite's own texture: a bevel from the distance to the transparent edge plus the luminance times the alpha (brighter and more opaque reads as higher) |
| `height` | made from the grey image `Sprite.heightMap` (white = high; the luminance, the alpha is ignored) |

`normalStrength` (default 1) is the relief. The map is made once, when the sprite is first drawn, with the same kernel that
`assets.generate_texture` uses to write a normal map file (`normal_map_from_height` in `fa/core/image_tools.h`), so the bytes are the same ones:
a generated map and the file `assets.generate_texture` would write look the same. It is cached per texture and strength and made again, in place,
when the texture file is reloaded. A source that cannot be read is logged once (what is wrong and how to fix it) and the sprite is lit flat.
The same maps can be made, edited (paint a slope, smooth, flip a channel, change the strength) and previewed under a moving light as a
layer of an image document, byte for byte the map above: [Normal maps](../images/IMAGES_EFFECTS_COMMANDS.md#normal-maps).
`normalFrom` `sprite` and `height` ignore `normalMap`. A generated map is a normal-mapped sprite for the layers and the cost
(the per-pixel path).

## Limits in one place

| What | Limit | When it is passed |
|---|---|---|
| Light buffers | 4 per frame | the extra masks use the loop over the first 16 lights, one warning per scene |
| Cookie textures | 16 distinct per frame | those lights shine without their cookie, one warning per scene |
| Lights read per pixel | 16 (the loop, the rim) | the rest are in the buffer only |
| Cookie cell | 256 x 256 pixels | a larger picture is scaled down into its cell |

See also: [Rendering](../RENDERING.md), [PERFORMANCE.md](../PERFORMANCE.md) ("2D lights"), [SHADERS_SPRITES.md](../shaders/SHADERS_SPRITES.md).
Design: docs/design/ARCHITECTURE_RENDERING.md ("2D emission, light layers and cookies (M74.2)"; repository only, not in the binary).
