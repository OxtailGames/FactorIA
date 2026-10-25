# Components reference

Generated from the engine's reflection data. Version marks: a component added after 0.1.0 has a "Since 0.1.x." line under its heading, and a field added later than its component ends with "(since 0.1.x)"; "Not released yet" means it is only on the main branch, in no download. Nothing is printed for what existed in 0.1.0; if your factoria is older than a mark, that item is missing there. In scene JSON a component is `"Name": { field: value, ... }` (omitted fields keep their defaults); in scripts use `entity.get("Name")`. Vectors accept `[x, y]` or `{x, y}`; colors accept `[r, g, b, a]` (0..1) or `"#rrggbb"`.

## Core

### EntityInfo

Identity of an entity; present on every entity. In scene files these fields are the entity's top-level keys (id, name, tags, active), not a component entry. Tags are handled by the scene serializer.

| Field | Type | Default | Description |
|---|---|---|---|
| `id` | string | `""` | Stable unique string id within the scene (e.g. "player"). Used to reference the entity from Entity fields, scripts (world.find) and tools. Auto-generated ("e1", "e2"...) if omitted. |
| `name` | string | `""` | Display name shown in the editor and logs. Not unique. |
| `active` | bool | `true` | If false the entity and all its children are skipped by rendering, physics, audio and scripts. |

### Transform

Position, rotation and scale of an entity relative to its parent. Present on every entity. 2D uses x/y of position and the z angle of rotation; 3D units are meters.

| Field | Type | Default | Description |
|---|---|---|---|
| `position` | vec3 | `[0.0,0.0,0.0]` | Local position relative to the parent [x, y, z]. 2D: x right, y up, z is only used for depth ordering of 3D content. Units: world units (design pixels in 2D, meters in 3D). |
| `rotation` | vec3 | `[0.0,0.0,0.0]` | Local rotation as euler angles in DEGREES [pitch around X, yaw around Y, roll around Z], applied in the order Y, X, Z. 2D games only use the z value (counter-clockwise). |
| `scale` | vec3 | `[1.0,1.0,1.0]` | Local scale [x, y, z]. 1 = original size; negative values mirror. |

## Camera

### Camera

Renders the scene to the screen. The active camera with primary=true and the lowest depth draws the game (only one camera renders for now; split-screen/overlay cameras are on the roadmap). 3D cameras look down their local -Z axis.

| Field | Type | Default | Description |
|---|---|---|---|
| `projection` | enum: orthographic \\| perspective | `"orthographic"` | orthographic: flat 2D view (no perspective). perspective: 3D view with depth. |
| `fov` | float | `60.0` | Perspective only: vertical field of view in degrees. Range 1.0..179.0. |
| `orthoSize` | float | `0.0` | Orthographic only: half of the visible height in world units. 0 = use the design resolution (pixel perfect: one world unit is one design pixel). Range 0.0..100000.0. |
| `nearPlane` | float | `0.1` | Perspective only: distance of the near clip plane in meters. Keep it as large as possible for depth precision. Range 0.001..100000.0. |
| `farPlane` | float | `1000.0` | Perspective only: distance of the far clip plane in meters. Range 0.01..1000000.0. |
| `clearColor` | color | `[0.08,0.08,0.12,1.0]` | Background color the camera clears to when clear is true. |
| `clear` | bool | `true` | Clear the target before drawing. Set false on overlay cameras that draw on top of another camera. |
| `primary` | bool | `true` | The first active primary camera renders the game. |
| `depth` | int | `0` | Picks the rendering camera when several are primary: the lowest depth wins (multi-camera rendering is on the roadmap). |
| `bloom` | bool | `false` | Bloom (glow) post-process: bright pixels bleed light into their surroundings, the neon / laser / fire / explosion look. Works for 2D and 3D cameras, is applied to the whole finished frame (screen-space HUD included, unless bloomScreenSpace is false) and shows in screenshots. Combine with blend "additive" on Sprite, Shape2D or ParticleEmitter instead of hand-drawing blurred halo sprites. Off by default; costs a few extra render passes per frame (cheap on a GPU, about 5 ms at 1280x720 on the software renderer used for headless runs). Tune with bloomThreshold, bloomIntensity and bloomRadius; keep the HUD crisp with bloomScreenSpace. |
| `bloomThreshold` | float | `0.7` | Only used when bloom is true. Brightness (0..1, the largest of a pixel's r, g, b) at which glow starts: pixels at or below it do not glow, the glow ramps up linearly to full strength at 1 (white / fully saturated). Lower it (0.3-0.6) to make dim colors glow too; raise it (0.9+) so only the brightest pixels do (values above 0.99 behave like 0.99). Range 0.0..1.0. |
| `bloomIntensity` | float | `1.2` | Only used when bloom is true. Strength of the glow that is added back onto the frame: 0 = none, 1 = the blurred bright pixels are added once, 2 = twice (brighter, saturates sooner). Limited to 0..10. Range 0.0..10.0. |
| `bloomRadius` | float | `20.0` | Only used when bloom is true. How far the glow reaches, in design pixels (1280x720 by default): a gaussian blur whose visible halo fades out roughly this far from the bright pixels. Values below ~5 behave like 5 (the glow is computed at reduced resolution, and larger radii at even lower resolution, so wide glows are softer). Limited to 1..128. Range 1.0..128.0. |
| `bloomScreenSpace` | bool | `true` | Only used when bloom is true. true (default): the whole finished frame glows, screen-space items (Sprite, Shape2D, Text with space "screen", and debug text) included, so a bright neon title or HUD icon glows too. false: screen-space items are drawn AFTER the bloom, so the HUD (score, lives, menus) stays crisp and never glows while the world still does. Set it to false whenever the HUD has white or bright text over a glowing world; leave it true to make a screen-space title or logo glow. |
| `colorFilter` | enum: none \\| greyscale \\| highContrast \\| protanopia \\| deuteranopia \\| tritanopia | `"none"` | Accessibility colour filter, the LAST post-process pass: it is applied to the whole finished frame (HUD included, after the bloom) on every graphics backend, so screenshots, factoria run --screenshot-at and --record-video show it too. A game's options screen sets it from the player's choice (it is not saved by itself). none (default): no pass, no cost. greyscale: Rec. 709 luminance in linear light. highContrast: contrast stretched 1.8x around mid grey, clipped. protanopia, deuteranopia, tritanopia: a daltonize correction for a player who lacks that cone: the loss is estimated with the Machado 2009 matrix (severity 1.0) and the lost information is shifted into the channels the player still sees (Fidaner's method), so colours that collapse together (red vs green) differ in brightness or in the remaining hue. To CHECK a game without changing what the player sees, use the `simulate` option of game.screenshot / --screenshot-simulate instead. (since 0.2.0) |

## 2D

### Sprite

Draws a textured (or solid color) quad. Use `region` to pick a frame from a sprite sheet. Draw order: higher `layer` on top; ties sort by position.y (lower y on top), then creation order.

| Field | Type | Default | Description |
|---|---|---|---|
| `texture` | asset (texture) | `""` | Project-relative path of the image (e.g. "assets/hero.png"). Empty draws a solid quad of `color`. |
| `region` | rect | `[0.0,0.0,0.0,0.0]` | Source rectangle [x, y, w, h] in texture pixels with the origin at the TOP-LEFT. A zero size means the whole texture. SpriteAnimator overwrites it every frame. |
| `size` | vec2 | `[0.0,0.0]` | Size [w, h] in world units. [0, 0] = use the region (or texture) size in pixels. |
| `pivot` | vec2 | `[0.5,0.5]` | Anchor inside the sprite: [0, 0] bottom-left, [0.5, 0.5] center, [1, 1] top-right. |
| `color` | color | `[1.0,1.0,1.0,1.0]` | Tint multiplied with the texture. Alpha makes it translucent. Accepts [r,g,b,a], "#rrggbb" or a name. |
| `flipX` | bool | `false` | Mirror horizontally. |
| `flipY` | bool | `false` | Mirror vertically. |
| `layer` | int | `0` | Draw order. Higher layers draw on top of lower ones. Backgrounds use negative layers. |
| `space` | enum: world \\| screen | `"world"` | world: positioned in the game world and affected by cameras. screen: UI/HUD in design-resolution pixels with (0,0) at the TOP-LEFT and +Y DOWN; drawn after the world. |
| `pixelArt` | bool | `true` | true = nearest-neighbour filtering (crisp pixels), false = smooth linear filtering. |
| `blend` | enum: alpha \\| additive \\| multiply | `"alpha"` | Compositing: alpha (normal), additive (glow, neon, fire, lasers; brightens), multiply (darkens/tints). |
| `anchor` | vec2 | `[0.0,0.0]` | Screen space only: screen point the position is relative to. [0,0] top-left (default), [1,0] top-right, [0.5,0.5] center, [1,1] bottom-right. Keeps HUD elements glued to screen edges on any aspect ratio. |
| `safeArea` | bool | `false` | Screen space only. true: the anchor names a point of the SAFE area, the screen minus the notch, rounded corners and system bars of a phone (screen.safeArea in scripts), instead of the whole screen: anchor [0, 0] is the top-left corner of the safe area, [1, 1] its bottom-right. Keeps HUD and buttons out of the notch. On a screen without cutouts (desktop, most tablets) it changes nothing. Default false. (since 0.2.0) |
| `slice` | vec4 | `[0.0,0.0,0.0,0.0]` | 9-slice borders in texture pixels [left, top, right, bottom], measured inside `region` (or the whole texture). With a border set the four corners are drawn at their texture size (1 texture pixel = 1 world unit), the edges stretch along one axis and the centre along both, so one small frame gives a panel, bar or platform of any `size`. [0, 0, 0, 0] (default) stretches the whole region. Borders that do not fit in `size` shrink together. Works with atlas-packed textures, flipX / flipY and a lit sprite. Screen-space UI panels use the same slicing through Panel.texture and Panel.slice. (since 0.2.0) |
| `lit` | bool | `false` | World space only. true: the sprite is shaded by the Light2D entities of the scene plus SceneSettings.ambientLight (its colour is multiplied by ambient + the sum of the lights); false (default): drawn exactly as the texture says, whatever lights exist. At most 16 lights shade a frame (see Light2D). (since 0.2.0) |
| `normalMap` | asset (texture) | `""` | Lit sprites only. Tangent-space normal map: RGB = (x, y, z) mapped from 0..1 to -1..1, +x to the right and +y UP the picture (OpenGL / Unity convention), laid out exactly like `texture` and `region` (same size). It turns with the sprite's rotation and flips. Empty (default) = a flat sprite lit only by distance. Ignored unless `lit` is true. (since 0.2.0) |

### Parallax

Since 0.2.0.

Shifts the drawing of this entity's world-space visuals (Sprite, Shape2D, Text, Tilemap) with the camera so far layers slide slower than near ones. Offset = camera position * (1 - factor) per axis: factor 1 behaves like any world object, 0 stays glued to the camera (a sky), 0.5 is half as fast (distant hills), above 1 is a foreground. With the camera at (0, 0) the entity is exactly where its Transform says. Only the drawing moves: Transform, physics and picking positions stay put, while entity.bounds() reports where it is drawn. Deterministic: it depends only on the camera position.

| Field | Type | Default | Description |
|---|---|---|---|
| `factor` | vec2 | `[0.5,0.5]` | [x, y] fraction of the camera's movement this layer follows (0 = fixed on screen, 1 = a normal world object). |
| `repeatX` | bool | `false` | Sprite only. Tile the sprite endlessly left and right (at `repeatSize.x` spacing, or its own width) so a background strip never runs out. The copies are drawn only where the camera sees them. |
| `repeatY` | bool | `false` | Sprite only. Same as repeatX, up and down. |
| `repeatSize` | vec2 | `[0.0,0.0]` | Distance between repeated copies in world units [x, y]. 0 = the sprite's own width / height. Use a smaller value to overlap soft edges, a larger one for gaps. |
| `offset` | vec2 | `[0.0,0.0]` | Runtime: the shift [x, y] currently applied to the drawing (written by the renderer every frame). Read-only. Runtime-only (not saved). |

### Light2D

Since 0.2.0.

A light for lit 2D visuals: sprites and tilemaps with `lit` true. Their colour is multiplied by SceneSettings.ambientLight plus the light of every Light2D (point: color * intensity * (1 - distance / radius)^falloff, scaled by the normal map's angle to the light when the sprite has a normalMap; directional: even light from one direction). Unlit visuals ignore lights, so existing games look the same. At most 16 lights shade a frame (the same on every graphics backend): directional lights first, then the point lights whose radius reaches the camera view, the ones with more of their radius in view first, then the more intense ones; a light entirely off-view is never kept over one in view. More than 16 in view logs one warning per scene, and renderStats().lights2d / lights2dDropped count what was kept and left out. The light sits at the entity's position (Transform) and ignores layers.

| Field | Type | Default | Description |
|---|---|---|---|
| `type` | enum: point \\| directional | `"point"` | point: a lamp at the entity's position that fades out at `radius`. directional: sun / moon, the same everywhere, coming from the opposite of `direction`. |
| `color` | color | `[1.0,1.0,1.0,1.0]` | Light colour. Accepts [r,g,b,a], "#rrggbb" or a name (alpha is ignored). |
| `intensity` | float | `1.0` | Strength: multiplies color. 1 = full colour at the lamp; above 1 over-brightens. Range 0.0..100.0. |
| `radius` | float | `300.0` | Point lights: distance in world units at which the light has faded to nothing. Range 0.0..100000.0. |
| `falloff` | float | `2.0` | Point lights: fade curve exponent. 1 = linear, 2 (default) = smooth, higher = a tight bright core. Range 0.01..16.0. |
| `height` | float | `80.0` | Point lights: height above the drawing plane in world units. Only matters for normal-mapped sprites: a low lamp grazes the surface and shows relief, a high one lights it flatly. Range 0.0..100000.0. |
| `direction` | float | `270.0` | Directional lights: degrees the light travels towards (0 = right, 90 = up, 270 = down). |
| `elevation` | float | `45.0` | Directional lights: angle above the drawing plane in degrees (90 = straight at the picture, 0 = along it). Range 0.0..90.0. |

### SpriteAnimator

Flipbook animation over a grid sprite sheet. Requires a Sprite on the same entity; it overwrites Sprite.region every frame. Frames are numbered row-major from the top-left.

| Field | Type | Default | Description |
|---|---|---|---|
| `columns` | int | `1` | Number of columns in the sprite sheet grid. Range 1.0..4096.0. |
| `rows` | int | `1` | Number of rows in the sprite sheet grid. Range 1.0..4096.0. |
| `firstFrame` | int | `0` | First frame of the clip (inclusive, row-major index). |
| `lastFrame` | int | `0` | Last frame of the clip (inclusive, row-major index). |
| `fps` | float | `10.0` | Playback speed in frames per second. Range 0.0..1000.0. |
| `loop` | bool | `true` | Restart from firstFrame after lastFrame. If false the animation stops on the last frame. |
| `playing` | bool | `true` | Set false to pause, true to play. |
| `time` | float | `0.0` | Runtime state: seconds elapsed in the current clip. Runtime-only (not saved). |
| `frame` | int | `0` | Runtime state: current frame index. Runtime-only (not saved). |

### Shape2D

Untextured 2D primitive for prototypes, UI panels and debug visuals.

| Field | Type | Default | Description |
|---|---|---|---|
| `shape` | enum: rectangle \\| circle \\| line \\| triangle \\| diamond \\| polygon \\| star | `"rectangle"` | Kind of primitive to draw. triangle: isosceles, apex at the middle of the top edge of the size box, base along the bottom edge. diamond: a rhombus whose 4 points sit at the middles of the size box's 4 edges (a square rotated 45 degrees when size is square; handy for gems, enemies and neon markers). polygon: a regular polygon with `sides` sides whose vertices lie on the ellipse inscribed in the size box, first vertex pointing up (hexagons, pentagons, octagons; many sides approach a circle). star: `points` tips on that ellipse, first tip pointing up, with notches at `innerRadius` of the outer radius in between. Outlines (filled = false) of triangle, diamond, polygon and star grow INWARD from the silhouette, like the rectangle's, so a thick outline never pokes out of the size box. |
| `size` | vec2 | `[32.0,32.0]` | rectangle/triangle/diamond/polygon/star: [width, height] of the box that contains the shape. circle: diameter in x. line: end point offset from the entity origin. |
| `color` | color | `[1.0,1.0,1.0,1.0]` | Fill or outline color. |
| `filled` | bool | `true` | true = solid shape, false = outline only (lines are always drawn as strokes). |
| `thickness` | float | `2.0` | Outline / line thickness in world units. Range 0.0..10000.0. |
| `layer` | int | `0` | Draw order. Higher layers draw on top. |
| `space` | enum: world \\| screen | `"world"` | world: affected by cameras. screen: UI in design pixels, origin TOP-LEFT, +Y down. |
| `pivot` | vec2 | `[0.5,0.5]` | Anchor point within the shape's size box for every shape but line: [0.5,0.5] = the box centre sits on the position (default), [0,0] bottom-left, [1,1] top-right. This point is also what the entity rotates and scales around. In screen space +Y is down, so [0,1] puts the top-left corner at the position. For a triangle the box centre is NOT its centre of mass (the apex is at the top-middle, the base along the bottom): use [0.5, 0.3333] to put its centroid on the position, the natural point to spin a triangle around without it wobbling. Circles and diamonds are symmetric, so the default [0.5,0.5] already spins them in place. |
| `blend` | enum: alpha \\| additive \\| multiply | `"alpha"` | Compositing: alpha (normal), additive (glow/neon), multiply (darken). |
| `anchor` | vec2 | `[0.0,0.0]` | Screen space only: screen point the position is relative to ([0,0] top-left, [1,1] bottom-right). |
| `safeArea` | bool | `false` | Screen space only. true: the anchor names a point of the SAFE area, the screen minus the notch, rounded corners and system bars of a phone (screen.safeArea in scripts), instead of the whole screen: anchor [0, 0] is the top-left corner of the safe area, [1, 1] its bottom-right. Keeps HUD and buttons out of the notch. On a screen without cutouts (desktop, most tablets) it changes nothing. Default false. (since 0.2.0) |
| `sides` | int | `6` | polygon only: number of sides (3 = triangle, 6 = hexagon, 8 = octagon). Range 3.0..64.0. |
| `points` | int | `5` | star only: number of tips (5 = the classic star). Range 3.0..64.0. |
| `innerRadius` | float | `0.5` | star only: radius of the notches between the tips as a fraction of the outer radius. 0.5 = classic star, near 1 = a fat spiky polygon, near 0 = thin needles. Range 0.0..1.0. |
| `lit` | bool | `false` | World space only. true: the shape is shaded by the Light2D entities of the scene plus SceneSettings.ambientLight (its colour is multiplied by ambient + the sum of the lights), like Sprite.lit, so a dark level can use shapes for platforms and hazards; every shape type, outlines and lines included, is flat (no normal map). false (default): drawn exactly in `color`, whatever lights exist. At most 16 lights shade a frame (see Light2D). (since 0.2.0) |

### Text

Draws a string with a TrueType font (or the built-in font). Works in world and screen space.

| Field | Type | Default | Description |
|---|---|---|---|
| `text` | string | `"Text"` | The string to draw. Use \n for line breaks. While `key` is set the engine overwrites it with the translation of the current language every frame: edit the string table (locales/<language>.json), not this field. |
| `key` | string | `""` | Localization key, e.g. "menu.play" (docs/LOCALIZATION.md). Empty (default) = this Text is not translated. With a key, the runtime writes the string of that key in the current language (locales/<language>.json, falling back to the base language and then to localization.defaultLanguage) into `text` when a scene or prefab loads, every frame and when the language changes, so `text` is overwritten at run time. A key that no string table has keeps the text written here and logs one warning. (since 0.2.0) |
| `keyArgs` | json | `{}` | Values for the {placeholders} of `key`, an object of name -> string or number: {"score": 12} fills "Score: {score}" (and `count` picks the form of a plural entry). Set it once from a script (`entity.set("Text", { keyArgs: { score } })` or `scene.set_component`) instead of rewriting the text every frame: the engine formats the translation with them when the text is localized, when the args change and when the language changes, so a language switch keeps them. Empty (default) = no arguments. Ignored while `key` is empty. (not released yet, on main after 0.2.0) |
| `font` | asset (font) | `""` | Project-relative path of a .ttf font. Empty uses the built-in font, DejaVu Sans (Latin, Greek, Cyrillic, Hebrew, Arabic); "builtin:pixel" is Press Start 2P. Characters the font has no glyph for draw as nothing and log one warning per font: Chinese, Japanese and Korean need a .ttf that covers them (e.g. Noto Sans SC, JP or KR). Keep this empty and list the extra fonts in factoria.json (localization.fallbackFonts, localization.languageFonts) to cover every Text of the game (docs/TEXT.md). |
| `fontSize` | float | `24.0` | Glyph height in world units (pixels in 2D). Range 1.0..4096.0. |
| `color` | color | `[1.0,1.0,1.0,1.0]` | Text color. |
| `align` | enum: left \\| center \\| right \\| start \\| end | `"left"` | Horizontal alignment of lines inside the text box. left / right are always the left / right edge, even for right-to-left text. start / end follow the current language: start = left and end = right in a left-to-right language, start = right and end = left in Arabic, Hebrew and the other right-to-left languages (i18n.direction); use them for text that must read from its start side. |
| `pivot` | vec2 | `[0.0,1.0]` | Anchor of the text box: [0, 1] top-left (default), [0.5, 0.5] center, [1, 0] bottom-right. |
| `maxWidth` | float | `0.0` | If > 0, lines wrap at this width in world units. 0 = no wrapping. With autoShrink it is also the width the text must fit (a word longer than the box shrinks the font). Range 0.0..100000.0. |
| `maxHeight` | float | `0.0` | Box height in the same units as maxWidth that autoShrink fits the text into: a card title with maxWidth 200 and maxHeight 30 stays on one line at any text size by shrinking. 0 (default) = only the width counts. Nothing is clipped or wrapped by it; it only drives autoShrink and ui.overflowed(id). Range 0.0..100000.0. (not released yet, on main after 0.2.0) |
| `autoShrink` | bool | `false` | true: when the text does not fit its box at the current text size (ui.textScale) and language, the font is made smaller until it does, never under `minFontSize` (so a German label in a fixed button stays inside at 200 % text, and a long translation is smaller instead of cut). It is decided every frame from the laid-out size, with no script. If it still does not fit at minFontSize it is drawn there and ui.overflowed(id) is true. false (default): the size is never reduced. (not released yet, on main after 0.2.0) |
| `minFontSize` | float | `10.0` | autoShrink floor in design pixels, before ui.textScale (the floor is minFontSize times the player's text size, capped by maxTextScale, so the accessibility setting keeps working). Never above fontSize. Range 1.0..4096.0. (not released yet, on main after 0.2.0) |
| `maxTextScale` | float | `0.0` | > 0: the player's text size (ui.textScale) stops growing this text at this scale, so a heading or a round button label does not outgrow its place: 1.3 means it is drawn at most 1.3 times its fontSize however big the option is. It only limits growth: at a text size below the cap it is drawn at the player's size. 0 (default) = no cap. Measuring (autoSize, layout, ui.measureText, ui.rectOf) and drawing use the same capped size. Range 0.0..3.0. (not released yet, on main after 0.2.0) |
| `layer` | int | `100` | Draw order. Higher layers draw on top. Text defaults above sprites. |
| `space` | enum: world \\| screen | `"world"` | world: affected by cameras. screen: HUD/UI in design pixels, origin TOP-LEFT, +Y down. |
| `anchor` | vec2 | `[0.0,0.0]` | Screen space only: screen point the position is relative to ([0,0] top-left, [1,0] top-right, [0.5,0] top-center, [1,1] bottom-right). Combine with pivot, e.g. anchor [1,0] + pivot [1,1] + position [-20, 20] = right-aligned 20px from the top-right corner. |
| `safeArea` | bool | `false` | Screen space only. true: the anchor names a point of the SAFE area, the screen minus the notch, rounded corners and system bars of a phone (screen.safeArea in scripts), instead of the whole screen: anchor [0, 0] is the top-left corner of the safe area, [1, 1] its bottom-right. Keeps HUD and buttons out of the notch. On a screen without cutouts (desktop, most tablets) it changes nothing. Default false. (since 0.2.0) |

### Tilemap

A grid of tiles drawn from a tileset texture; tile index -1 is empty. Row 0 is the TOP row. Solid tiles can generate static 2D collision.

| Field | Type | Default | Description |
|---|---|---|---|
| `tileset` | asset (texture) | `""` | Project-relative path of the tileset image (tiles laid out left-to-right, top-to-bottom). |
| `tileSize` | vec2 | `[16.0,16.0]` | Size of one tile [w, h], both in the tileset texture (pixels) and in the world (units). |
| `columns` | int | `0` | Number of tile columns in the tileset texture (used to find a tile's source rectangle). Optional: 0 (the default) derives it from the tileset texture, as many whole tiles of tileSize.x as fit across its width. Set it only when the image has a different layout. Range 0.0..4096.0. |
| `width` | int | `0` | Map width in tiles, for a flat tiles array. Not needed when tiles is an array of rows (the rows define the size; drawing and collision both use it). Range 0.0..65536.0. |
| `height` | int | `0` | Map height in tiles, for a flat tiles array. Not needed when tiles is an array of rows. Range 0.0..65536.0. |
| `tiles` | json | `[]` | Tile values, row-major with row 0 at the TOP: either a flat array of width*height integers (set width and height) or an array of rows (the size comes from the rows). -1 = empty. A value is the tileset index, optionally plus flags that mirror or turn that tile when drawn: 268435456 flips it left-right (flipX), 536870912 top-bottom (flipY), 1073741824 mirrors it across the diagonal (transpose). The image is transposed first, then flipped in x, then in y; a 90 degree clockwise turn is transpose + flipX = 1342177280 + index, 180 is flipX + flipY = 805306368 + index, 90 counter-clockwise is transpose + flipY = 1610612736 + index. scene.import_ascii legends write these for you: {"tile": 3, "rotate": 90, "flipX": true}. |
| `solidTiles` | json | `[]` | List of plain tile indices (no flip flags) that block movement; static colliders are generated for them. A flipped or rotated copy of a solid tile is still solid. Empty = nothing collides. |
| `color` | color | `[1.0,1.0,1.0,1.0]` | Tint multiplied with the tileset. |
| `layer` | int | `-10` | Draw order. Defaults below sprites (-10). |
| `lit` | bool | `false` | true: the tiles are shaded by the Light2D entities and SceneSettings.ambientLight, like Sprite.lit. Default false. (since 0.2.0) |
| `normalMap` | asset (texture) | `""` | Lit tilemaps only. Normal map image laid out exactly like the tileset (same size, same tile positions); flipped and rotated tiles turn their normals with them. Empty = flat tiles. (since 0.2.0) |

### ParticleEmitter

Emits short-lived particles (smoke, sparks, explosions). Particles interpolate size and color over their lifetime.

| Field | Type | Default | Description |
|---|---|---|---|
| `emitting` | bool | `true` | Continuously emit while true. Set false to stop spawning (live particles finish). |
| `rate` | float | `20.0` | Particles emitted per second while emitting. Range 0.0..100000.0. |
| `burst` | int | `0` | Number of particles emitted once when the emitter starts (explosions). Range 0.0..100000.0. |
| `maxParticles` | int | `500` | Upper limit of simultaneously alive particles. Range 1.0..1000000.0. |
| `lifetime` | float | `1.0` | How long a particle lives, in seconds. Range 0.001..3600.0. |
| `lifetimeVariance` | float | `0.2` | Random +- fraction applied to lifetime (0.2 = +-20%). Range 0.0..1.0. |
| `speed` | float | `100.0` | Initial speed in world units per second. |
| `speedVariance` | float | `0.3` | Random +- fraction applied to speed. Range 0.0..1.0. |
| `direction` | float | `90.0` | 2D emission direction in degrees: 0 = right, 90 = up. |
| `spread` | float | `30.0` | Half-angle of the emission cone in degrees (180 = all directions). Range 0.0..180.0. |
| `gravity` | vec3 | `[0.0,-200.0,0.0]` | Constant acceleration [x, y, z] in world units/s^2 (default pulls down). |
| `startSize` | float | `8.0` | Particle size when born, in world units. |
| `endSize` | float | `0.0` | Particle size at the end of its life. |
| `startColor` | color | `[1.0,1.0,1.0,1.0]` | Particle color when born. |
| `endColor` | color | `[1.0,1.0,1.0,0.0]` | Particle color at the end of life (alpha 0 fades out). |
| `texture` | asset (texture) | `""` | Particle image. Empty uses a soft round particle. |
| `worldSpace` | bool | `true` | true = particles stay where they were emitted when the emitter moves; false = they follow the emitter. |
| `is3D` | bool | `false` | Emit in a 3D cone as camera-facing billboards instead of in the 2D plane. |
| `layer` | int | `50` | Draw order. Higher layers draw on top. |
| `blend` | enum: alpha \\| additive \\| multiply | `"alpha"` | Compositing of particles: additive is ideal for sparks, fire, magic and neon effects. |
| `autoDestroy` | bool | `false` | Destroy the entity automatically once it is not emitting and all its particles died. Use with burst > 0 and emitting = false for one-shot effects (explosions, pickups). |
| `space` | enum: world \\| screen | `"world"` | world: affected by cameras. screen: HUD/UI effects (menu sparks, score bursts) in design pixels, origin TOP-LEFT, +Y down, unaffected by cameras and drawn in the screen-space pass (so with Camera.bloomScreenSpace = false they are not bloomed). direction, gravity and speed keep their world meaning on screen: 90 = up, negative gravity y falls down the screen. Ignored (treated as world) when is3D is true. |
| `anchor` | vec2 | `[0.0,0.0]` | Screen space only: screen point the position is relative to ([0,0] top-left, [1,0] top-right, [0.5,0.5] center, [1,1] bottom-right). |
| `safeArea` | bool | `false` | Screen space only. true: the anchor names a point of the SAFE area, the screen minus the notch, rounded corners and system bars of a phone (screen.safeArea in scripts), instead of the whole screen: anchor [0, 0] is the top-left corner of the safe area, [1, 1] its bottom-right. Keeps HUD and buttons out of the notch. On a screen without cutouts (desktop, most tablets) it changes nothing. Default false. (since 0.2.0) |

## 3D

### MeshRenderer

Draws a 3D mesh with a PBR material (GGX highlights, sky reflections, normal maps; glTF materials are read). Needs a perspective Camera and (unless unlit) a Light to be visible.

| Field | Type | Default | Description |
|---|---|---|---|
| `mesh` | string | `"cube"` | Built-in shape name ("cube", "sphere", "plane", "cylinder", "capsule", "cone", "quad") or a project-relative path to a .gltf/.glb model (e.g. "assets/models/ship.glb"). |
| `texture` | asset (texture) | `""` | Base color texture. Empty = none (or the glTF material). |
| `normalMap` | asset (texture) | `""` | Tangent-space normal map (glTF convention: +Y up, the usual blue-ish image) that adds small-scale relief without more triangles. Empty = none (or the glTF material's normalTexture). Replaces the glTF one when set. (since 0.2.0) |
| `normalScale` | float | `1.0` | How strong the normal map is: 0 = flat, 1 = as authored. Range 0.0..4.0. (since 0.2.0) |
| `color` | color | `[1.0,1.0,1.0,1.0]` | Base color, multiplied with the texture. |
| `metallic` | float | `0.0` | 0 = plastic/stone, 1 = metal. glTF models use their own metallic value and metallicRoughnessTexture instead. Range 0.0..1.0. |
| `roughness` | float | `0.6` | 0 = mirror-smooth, 1 = fully rough/matte. glTF models use their own roughness and metallicRoughnessTexture instead. Range 0.0..1.0. |
| `emissive` | color | `[0.0,0.0,0.0,1.0]` | Light emitted by the surface regardless of lighting (glow). Black = none. |
| `unlit` | bool | `false` | true = ignore lighting and draw the flat base color. |
| `castShadows` | bool | `true` | Cast shadows from shadow-casting lights. |
| `receiveShadows` | bool | `true` | Receive shadows from shadow-casting lights. |
| `uvScale` | vec2 | `[1.0,1.0]` | Texture tiling [u, v]; 2 repeats the texture twice. |
| `material` | asset (material) | `""` | Project-relative path of a custom material, a *.material.json file (e.g. "materials/water.material.json"), or "" (default) for the standard PBR material. The material file names a GLSL snippet whose surface() changes what the standard material computed (albedo, alpha, normal, emission...) and whose optional vertex() moves the vertices, and declares its params, textures, lighting (pbr or unlit) and alphaMode (opaque, clip or blend). The `material.info` command lists a material's params and textures; `shader.compile` compiles it and reports errors with file:line. The material's alphaMode wins over color.a < 1; `unlit` true forces unlit lighting. A material that does not compile draws magenta and logs why. Guide with worked examples: docs/SHADERS.md (`factoria docs read shaders`). (since 0.2.0) |
| `materialParams` | json | `{}` | Per-entity overrides of the material's params and textures, as an object keyed by the name declared in the material file: numbers for float params, arrays for vectors and colors ([r, g, b, a]), project-relative paths for textures. Example: {"glow": [1, 0.2, 0, 1], "mask": "textures/leaf.png"}. Unnamed params keep the material's defaults. An entity without overrides batches with the others that share the material. (since 0.2.0) |
| `materialColors` | json | `{}` | Per-material colours of a glTF model, an object keyed by glTF material name: {"Body": [0.2, 0.8, 0.7, 1]}. The colour REPLACES that material's baseColorFactor on its sub-meshes (the texture still multiplies it) and `color` still multiplies the result, so `color` stays the tint of the whole model. Materials not named keep their own colour. Names come from the model (the sub-mesh keeps its material name from import); `factoria validate` checks them and suggests the right one for a typo. Ignored by built-in shapes. Entities that differ only in materialColors are drawn in separate batches. (not released yet, on main after 0.2.0) |

### Light

A light source for 3D meshes. A directional light shines along the entity's forward direction (-Z rotated by the Transform), point and spot lights shine from the entity's position.

| Field | Type | Default | Description |
|---|---|---|---|
| `type` | enum: directional \\| point \\| spot | `"directional"` | directional: sun-like, infinite distance. point: radiates in all directions. spot: cone along forward. |
| `color` | color | `[1.0,1.0,1.0,1.0]` | Light color. |
| `intensity` | float | `1.0` | Brightness multiplier. Range 0.0..1000.0. |
| `range` | float | `10.0` | Point/spot only: distance in meters where the light fades to zero. Range 0.01..100000.0. |
| `spotAngle` | float | `30.0` | Spot only: cone half-angle in degrees. Range 1.0..89.0. |
| `castShadows` | bool | `false` | Cast shadows. Only supported on directional lights for now. |

### Animator

Since 0.2.0.

Plays the skeletal animation clips of a skinned glTF model (the model of the MeshRenderer on the same entity, or `model`): one clip at a time with cross-fades, clip events, and an optional small state machine (`params`, `states`, `transitions`). It runs in the fixed step, so headless runs and replays match. Scripts: entity.animator.play("Run", 0.2), .set("speed", 3), .stop(); events reach world.on(name, ...).

| Field | Type | Default | Description |
|---|---|---|---|
| `model` | string | `""` | Project-relative .gltf/.glb path with the skin and the clips. Empty = the `mesh` of the MeshRenderer on the same entity (usual case: leave it empty). |
| `clip` | string | `""` | Name of the glTF animation playing now (see entity.animator.clips). Assigning it at run time switches clips with a cross-fade of `fade` seconds. Empty = bind pose (the model as exported). |
| `speed` | float | `1.0` | Playback speed multiplier: 1 = authored speed, 2 = twice as fast, 0 = frozen. Range 0.0..100.0. |
| `loop` | bool | `true` | true = start over when the clip ends. false = stop on the last pose and send the `anim.finished` event. |
| `playing` | bool | `true` | Set false to pause, true to play. |
| `fade` | float | `0.2` | Cross-fade seconds used when `clip` is changed by assignment (play() takes its own). Range 0.0..60.0. |
| `params` | json | `{}` | State machine parameters and their start values, an object such as {"speed": 0, "grounded": true}. Numbers and booleans. Scripts change them with animator.set(name, value); transitions read them. |
| `states` | json | `{}` | State machine states, an object name -> {clip, loop (default true), speed (default 1), onEnter}. `onEnter` is the name of a game event sent when the state starts (world.on). Example: {"idle": {"clip": "Idle"}, "run": {"clip": "Run", "onEnter": "started_running"}}. |
| `transitions` | json | `[]` | State machine transitions, an array checked in order every step; the first that matches fires. Each: {from (a state, or "*"/omitted = any), to, when, fade (seconds, default 0.2), onFinish}. `when` is conditions joined by "&&": `speed > 0.1`, `grounded`, `!grounded`, `hp <= 0` (operators > >= < <= == !=). A parameter set with animator.trigger(name) is true for one step. onFinish: true fires when the current non-looping clip ended (alone or together with `when`). |
| `events` | json | `[]` | Clip events, an array of {clip, time, name}: when the clip's time passes `time` (seconds) the game event `name` is sent once per loop, with data {id, clip, time}; listen with world.on(name, fn). Example: [{"clip": "Walk", "time": 0.3, "name": "footstep"}]. |
| `state` | string | `""` | State machine: the state the animator is in (the start state when set in the scene; empty = the first state of `states`). Updated as transitions fire. |
| `time` | float | `0.0` | Runtime state: seconds into the current clip. Assigning it seeks (no events fire). Runtime-only (not saved). |
| `values` | json | `{}` | Runtime state: current value of every state machine parameter. Runtime-only (not saved). |

## Physics

### RigidBody2D

Puts the entity under 2D physics (Box2D). Pair it with a Collider2D. Positions are simulated in world units; gravity comes from the scene settings (gravity2D).

| Field | Type | Default | Description |
|---|---|---|---|
| `type` | enum: static \\| dynamic \\| kinematic | `"dynamic"` | static: never moves (walls, floors). dynamic: moved by forces and collisions. kinematic: moved only by setting velocity or the Transform; pushes dynamic bodies but is not pushed back. |
| `gravityScale` | float | `1.0` | Multiplier on world gravity. 0 = floats, negative = falls upwards. |
| `linearDamping` | float | `0.0` | Air resistance for movement; 0 = none, higher slows faster. Range 0.0..1000.0. |
| `angularDamping` | float | `0.05` | Air resistance for spinning. Range 0.0..1000.0. |
| `fixedRotation` | bool | `false` | true = never rotates from collisions (platformer characters). |
| `bullet` | bool | `false` | true = continuous collision detection, for fast small objects that would tunnel through walls. |
| `velocity` | vec2 | `[0.0,0.0]` | Linear velocity [x, y] in world units per second. Read/write: writes apply before the next physics step. |
| `angularVelocity` | float | `0.0` | Spin in degrees per second (counter-clockwise positive). |

### Collider2D

Collision shape for 2D physics. Without a RigidBody2D the collider acts as a static obstacle. Colliders collide when each one's layer is included in the other's mask.

| Field | Type | Default | Description |
|---|---|---|---|
| `shape` | enum: box \\| circle \\| capsule | `"box"` | Shape type; uses size (box, capsule) or radius (circle). |
| `size` | vec2 | `[32.0,32.0]` | box/capsule: [width, height] in world units (capsule is vertical). |
| `radius` | float | `16.0` | circle: radius in world units. |
| `offset` | vec2 | `[0.0,0.0]` | Shape center offset [x, y] from the entity origin, in world units. |
| `isTrigger` | bool | `false` | true = sensor: reports overlaps (onTriggerEnter/Exit) but does not block movement. |
| `friction` | float | `0.4` | Surface friction; 0 = ice, 1 = grippy. Range 0.0..10.0. |
| `restitution` | float | `0.0` | Bounciness: 0 = no bounce, 1 = perfectly elastic. Range 0.0..1.0. |
| `density` | float | `1.0` | Mass per area; mass = density * shape area. Range 0.0..10000.0. |
| `layer` | int | `0` | Collision category of this collider, 0..31. Range 0.0..31.0. |
| `mask` | int | `-1` | Bitmask of layers this collider collides with. -1 = all layers (bit i = layer i). |
| `oneWay` | bool | `false` | One-way platform: only blocks bodies landing on it from above (the entity's +Y side); bodies can jump up through it from below and pass sideways. |

### Joint2D

Since 0.2.0.

A Box2D joint on this entity's body: revolute (a hinge / pendulum / wheel axle), distance (a rope or spring of fixed length), prismatic (a slider along an axis) or weld (glue two bodies together). Both this entity and `connected` need a RigidBody2D (or a Collider2D, which makes a static body); leave `connected` empty to pin to the world. Lengths and anchors are world units (pixels), angles degrees; created when the entity is, destroyed with either body or when the component is removed. Changing type, connected, anchors, axis or collideConnected rebuilds the joint; limits, motor, spring and length apply live, so scripts can toggle a motor. Positive angle, motor speed and translation move THIS entity counter-clockwise / along +axis relative to `connected` (the axis is in the connected body's frame, the world's when empty). Reaction force, angle and translation are read-only runtime fields.

| Field | Type | Default | Description |
|---|---|---|---|
| `type` | enum: revolute \\| distance \\| prismatic \\| weld | `"revolute"` | revolute: the bodies share the anchor point and may turn around it. distance: the anchors stay `length` apart (a spring when enableSpring). prismatic: the anchor slides along `axis` and the bodies cannot turn relative to each other. weld: the bodies stay rigidly together (soft with springHertz > 0). |
| `connected` | entity |  | Id of the other entity (it needs a body). Empty (leave it out, null or "") = the joint is fixed to the world and connectedAnchor is a world position. |
| `anchor` | vec2 | `[0.0,0.0]` | Joint point [x, y] in THIS entity's local space (scaled by Transform.scale), world units from its origin. |
| `connectedAnchor` | vec2 | `[0.0,0.0]` | Joint point [x, y] in the connected entity's local space; a world position when `connected` is empty. For a hinge both anchors name the same spot in the world when the joint is created. |
| `axis` | vec2 | `[1.0,0.0]` | Prismatic only: slide direction [x, y] in this entity's local space; normalised. [1, 0] slides along local x. |
| `collideConnected` | bool | `false` | true: the two joined bodies still collide with each other (default false). |
| `length` | float | `0.0` | Distance only: rest length in world units. 0 = the distance between the anchors when the joint is created. Range 0.0..1000000.0. |
| `enableLimit` | bool | `false` | Limit the motion: revolute angle, prismatic translation, or distance length (needs enableSpring to stretch). |
| `lowerLimit` | float | `0.0` | Lower limit: revolute degrees (between -178 and 178, 0 = the pose at creation), prismatic translation in world units (0 = anchors coincide), distance minimum length in world units. |
| `upperLimit` | float | `0.0` | Upper limit, same units as lowerLimit. |
| `enableMotor` | bool | `false` | Drive the joint at motorSpeed with at most maxMotorTorque. Revolute and prismatic; a distance joint motor works only with enableSpring. |
| `motorSpeed` | float | `0.0` | Target speed: revolute degrees per second (positive = counter-clockwise), prismatic / distance world units per second. |
| `maxMotorTorque` | float | `0.0` | Strongest push the motor may apply: a torque for a revolute joint, a force for prismatic and distance joints (the same units as physics.applyForce). 0 = the motor does nothing. Range 0.0..999999995904.0. |
| `enableSpring` | bool | `false` | Revolute, prismatic, distance: make the free motion springy, pulling towards the rest pose (angle 0, translation 0, `length`). |
| `springHertz` | float | `0.0` | Spring stiffness in cycles per second (about 1 = a slow bounce, 5 = stiff). Weld joints: 0 = rigid, above 0 = a soft weld (no enableSpring needed). Range 0.0..1000.0. |
| `dampingRatio` | float | `0.0` | Spring damping: 0 = bounces on, 1 = settles without overshoot. Range 0.0..100.0. |
| `reactionForce` | vec2 | `[0.0,0.0]` | Runtime: the force [x, y] the joint applied last step to hold the bodies (same units as physics.applyForce). Compare it with a limit to break a rope. Read-only. Runtime-only (not saved). |
| `reactionTorque` | float | `0.0` | Runtime: the torque the joint applied last step. Read-only. Runtime-only (not saved). |
| `angle` | float | `0.0` | Runtime: revolute and weld: the current joint angle in degrees (0 = the pose at creation). Read-only. Runtime-only (not saved). |
| `translation` | float | `0.0` | Runtime: prismatic: the current slide position; distance: the current length, in world units. Read-only. Runtime-only (not saved). |

### RigidBody3D

Simple 3D physics body for arcade games (spheres, oriented boxes, capsules and convex hulls; a triangle-mesh collider is for static level geometry only). Pair it with a Collider3D; add a Joint3D to hinge it to the world or to another body. A capsule body with lockRotation is a simple physics character (for a controller that slides, climbs steps and checks slopes use CharacterController3D instead). Gravity comes from scene settings (gravity3D). Fast bodies are swept against every solid collider (continuous collision, automatic). A dynamic BOX is a rigid body: collisions and friction apply torque at the contact points (inertia from its size and mass), so it tips over a ledge, tumbles and settles on a face; set lockRotation for a character or an upright crate. A sphere is an arcade rolling ball by default (rollWithMotion = true: spun to match its motion, contacts never turn it); with rollWithMotion = false it is a rigid body too: friction at the contact point spins it, so it rolls down slopes and a glancing hit spins it. A tumbling box precesses like a real one. A dynamic body that stays nearly still for half a second falls asleep together with the bodies it touches (no cost, no events) and wakes when touched by something moving, when gameplay writes its position, rotation or velocity, applies a force, or when what it rests on goes away.

| Field | Type | Default | Description |
|---|---|---|---|
| `type` | enum: static \\| dynamic \\| kinematic | `"dynamic"` | static: never moves. dynamic: moved by gravity and collisions. kinematic: moved only by velocity/Transform. |
| `mass` | float | `1.0` | Mass in kilograms (affects collision responses between dynamic bodies). Range 0.0001..1000000.0. |
| `gravityScale` | float | `1.0` | Multiplier on world gravity. |
| `linearDamping` | float | `0.0` | Air resistance; 0 = none. Range 0.0..1000.0. |
| `velocity` | vec3 | `[0.0,0.0,0.0]` | Linear velocity [x, y, z] in meters per second. Read/write. |
| `angularVelocity` | vec3 | `[0.0,0.0,0.0]` | Rotation speed in degrees/second around x, y, z; integrated into Transform.rotation each step. Read/write (writing it wakes a sleeping body). A box spinning about a non-principal axis keeps its angular momentum, so this vector wanders (precession) while it tumbles. |
| `rollWithMotion` | bool | `true` | Sphere colliders only. true (default, arcade ball): while it touches the ground the sphere is spun to match its rolling motion (sets angularVelocity from the horizontal velocity) and uses rolling resistance (rollingFriction) instead of sliding friction; contacts never turn it, so setting velocity every frame steers it exactly. false: the sphere is a rigid body (solid-sphere inertia 2/5 m r^2): friction at the contact point spins it, so on a slope it rolls (spin = speed / radius) and a glancing hit makes it spin; on flat ground it keeps rolling until angularDamping / linearDamping or an obstacle stops it. Add lockRotation for a ball that slides and is never spun by contacts. |
| `rollingFriction` | float | `0.02` | Rolling resistance of a dynamic sphere with rollWithMotion = true: friction cap = rollingFriction * normal force, replacing the sliding friction of its contacts, so on flat ground its speed decays by about rollingFriction * gravity per second (default 0.02 rolls about 23 m from 3 m/s; 0 never slows down). Ignored when rollWithMotion is false (then Collider3D.friction acts at the contact point of the rigid sphere) and for boxes. Range 0.0..10.0. |
| `angularDamping` | float | `0.0` | Rotation drag of a dynamic body: angularVelocity is divided by (1 + dt * angularDamping) every step, so 0 = a spinning body keeps spinning in the air, larger values slow it down faster. Range 0.0..1000.0. |
| `lockRotation` | bool | `false` | true = collisions and friction never turn this body (a dynamic box, or a sphere with rollWithMotion = false): it stays upright and slides, as boxes did before rotation dynamics. Use it for characters and upright crates. angularVelocity and Transform.rotation written by gameplay still turn it. A rollWithMotion sphere is never turned by contacts either way. |

### Collider3D

Collision shape for 3D physics: box, sphere, capsule, convex hull or triangle mesh. Boxes, capsules and meshes are ORIENTED: they follow the entity's world rotation (parents included), so a box rotated 45 degrees blocks at its rotated edge. Scaled by the Transform scale. A `mesh` collider is for level geometry and needs a static body (no RigidBody3D, or type static): a dynamic or kinematic body with one is reported as an error and ignored.

| Field | Type | Default | Description |
|---|---|---|---|
| `shape` | enum: box \\| sphere \\| capsule \\| convex \\| mesh | `"box"` | box: uses size. sphere: uses radius. capsule: uses radius and height, along the entity's local Y. convex: the convex hull of the vertices of `mesh` (any dynamic body, fast). mesh: the triangles of `mesh` (static level geometry only; concave shapes, ramps, terrain). |
| `size` | vec3 | `[1.0,1.0,1.0]` | box: full extents [x, y, z] in meters along the entity's own (rotated) axes, before Transform scale. |
| `radius` | float | `0.5` | sphere and capsule: radius in meters. |
| `height` | float | `2.0` | capsule: full height in meters from tip to tip along the entity's local Y (so the straight part is height - 2 * radius; never less than 2 * radius). Range 0.002..100000.0. (since 0.2.0) |
| `mesh` | string | `""` | convex / mesh shapes: a built-in primitive name ("cube", "sphere", "plane", "cylinder", "capsule", "cone", "quad", the same sizes as MeshRenderer) or a project-relative path to a .gltf/.glb model (every mesh node of the file, with its node transform). Use the same value as the MeshRenderer so the collider matches what is drawn. (since 0.2.0) |
| `offset` | vec3 | `[0.0,0.0,0.0]` | Shape center offset [x, y, z] from the entity origin, scaled and rotated with the entity (for convex and mesh: where the model's own origin sits). |
| `isTrigger` | bool | `false` | true = sensor: reports overlaps but does not block movement. |
| `friction` | float | `0.4` | Surface friction; 0 = ice, 1 = grippy. Range 0.0..10.0. |
| `restitution` | float | `0.0` | Bounciness: 0 = none, 1 = perfectly elastic. Range 0.0..1.0. |
| `layer` | int | `0` | Collision category of this collider, 0..31. Range 0.0..31.0. |
| `mask` | int | `-1` | Bitmask of layers this collider collides with. -1 = all layers. |
| `navObstacle` | bool | `false` | true = a NavMesh3D does not bake this collider into the ground (a crate, a gate, a door that moves): it blocks the navigation cells it covers, plus the agent's radius, wherever it is NOW, and the affected cells are marked again each time it moves, so nav.findPath goes around it. Use it on anything that moves or is removed during play; static level geometry needs nothing. (not released yet, on main after 0.2.0) |
| `navWalkable` | bool | `false` | true = a NavMesh3D does not bake this collider either, but its TOP surface is walkable wherever it is NOW: put it on a kinematic body or a body held by a joint that characters stand on (a rope-bridge plank, a seesaw, a moving platform, a lift). The cells it covers are added to the navigation mesh and marked again each time it moves (only the cells it left and entered), and they join the ground around them within stepHeight, so nav.findPath crosses a bridge, rides a platform that is docked and says `disconnected` while it is away. The ground under it is blocked meanwhile. Surfaces steeper than maxSlope are not walkable. Wins over navObstacle when both are set. (not released yet, on main after 0.2.0) |

### Joint3D

Since 0.2.0.

Joins this entity's RigidBody3D to another body or to the world: a hinge (door, pendulum, wheel), a ball joint (rope link, ragdoll shoulder) or a fixed joint (welds the two bodies). Solved together with the contacts. Put it on the body that swings; set `connected` to the other entity (empty = the world). A jointed dynamic body is always a rotating rigid body. Bodies joined together fall asleep together once the whole chain is at rest (a motor keeps its bodies awake), so a settled rope bridge costs nothing. A chain of three or more jointed bodies is solved with extra iterations, so planks of any width hang still without heavy damping. The joint holds the pose the bodies have when it is created (autoAnchor); hinge limits are angles relative to that pose.

| Field | Type | Default | Description |
|---|---|---|---|
| `type` | enum: hinge \\| ball \\| fixed | `"hinge"` | hinge: rotation about `axis` only. ball: free rotation about the anchor point. fixed: no relative movement at all. |
| `connected` | entity |  | The other body's entity id. Empty (leave it out, null or "") = the world: the anchor point stays where it is. The entity needs a RigidBody3D (any type) or a Collider3D. |
| `anchor` | vec3 | `[0.0,0.0,0.0]` | Joint point [x, y, z] in THIS entity's local space (scaled and rotated with it): the pendulum's pivot, the door's hinge edge. |
| `connectedAnchor` | vec3 | `[0.0,0.0,0.0]` | Joint point in the connected entity's local space, or a world position when `connected` is empty. Ignored while autoAnchor is true. |
| `autoAnchor` | bool | `true` | true (default): connectedAnchor is computed from `anchor` when the joint is created, so the bodies stay joined exactly where they are. false: use connectedAnchor as given (the bodies are pulled together). |
| `axis` | vec3 | `[0.0,0.0,1.0]` | hinge: the rotation axis [x, y, z] in THIS entity's local space (normalized). |
| `useLimits` | bool | `false` | hinge: keep the angle between lowerLimit and upperLimit. |
| `lowerLimit` | float | `-45.0` | hinge: lowest angle in degrees, relative to the pose the joint was created in (0 there). Range -360.0..360.0. |
| `upperLimit` | float | `45.0` | hinge: highest angle in degrees (same reference). Range -360.0..360.0. |
| `useMotor` | bool | `false` | hinge: drive the joint at motorSpeed (a wheel, an opening door). |
| `motorSpeed` | float | `0.0` | hinge motor: target speed in degrees/second of this body relative to the connected one, about the axis. |
| `maxMotorTorque` | float | `10.0` | hinge motor: the most torque in newton-meters the motor may apply; a heavy or loaded body needs more. Range 0.0..1000000.0. |
| `collideConnected` | bool | `false` | false (default): the two joined bodies do not collide with each other. true: they do. |
| `damping` | float | `0.0` | Resistance to the two bodies turning relative to each other, per second: each physics sub-step the relative angular velocity (about the axis for a hinge, every axis for a ball joint) is divided by 1 + damping * dt. 0 (default) = free; 1 takes the swing out of a door in a few seconds; 2..5 stops a rope-bridge plank ringing. A chain of 3+ bodies already settles without it. Range 0.0..1000.0. (not released yet, on main after 0.2.0) |
| `angle` | float | `0.0` | Runtime: the current hinge angle in degrees, relative to the creation pose. Read-only. Runtime-only (not saved). |
| `stalled` | bool | `false` | Runtime, read only: true while a motor (useMotor with a non-zero motorSpeed) cannot turn the joint: the relative speed stayed below a tenth of motorSpeed for a quarter of a second, e.g. a gate pushing against a wall, or a maxMotorTorque too low for the load. False when the hinge simply reached its limit. Scripts read it to open another way or raise the torque. Read-only. Runtime-only (not saved). (not released yet, on main after 0.2.0) |

### CharacterController3D

Since 0.2.0.

A walking character: a kinematic capsule that moves and slides. Move it with physics.moveCharacter(entity, [dx, dy, dz]) (Unity-style: you add gravity and jumping to the move yourself, using isGrounded) or set `velocity`. It slides along walls and ceilings, climbs steps up to stepOffset, will not climb slopes steeper than slopeLimit (it slides down them), stays on the ground going down ramps, is carried by the kinematic platform it stands on (carriedByPlatforms), weighs on the dynamic body below it (applyWeight, mass: a seesaw tips) and pushes the free dynamic bodies it walks into (pushStrength). Other bodies treat it as a kinematic capsule. The entity origin is the capsule centre (plus `center`). Do not add RigidBody3D or Collider3D to the same entity.

| Field | Type | Default | Description |
|---|---|---|---|
| `radius` | float | `0.4` | Capsule radius in meters (scaled by Transform.scale). Range 0.01..100.0. |
| `height` | float | `1.8` | Capsule height in meters from tip to tip (never less than 2 * radius). Range 0.02..1000.0. |
| `center` | vec3 | `[0.0,0.0,0.0]` | Capsule centre [x, y, z] from the entity origin, in meters. |
| `stepOffset` | float | `0.3` | Highest step in meters the character walks up (and the distance it snaps down to stay on the ground). Range 0.0..10.0. |
| `slopeLimit` | float | `45.0` | Steepest slope in degrees the character can walk up; steeper surfaces count as walls. Range 0.0..89.0. |
| `skin` | float | `0.02` | Gap in meters kept between the capsule and the surfaces it touches; avoids jitter and tunnelling. Range 0.001..1.0. |
| `layer` | int | `0` | Collision category of the character, 0..31. Range 0.0..31.0. |
| `mask` | int | `-1` | Bitmask of layers the character collides with. -1 = all layers. |
| `velocity` | vec3 | `[0.0,0.0,0.0]` | Velocity in meters/second [x, y, z]: when not zero the character moves by velocity * dt every physics step (no gravity is added). Use it or moveCharacter, not both for the same motion. |
| `carriedByPlatforms` | bool | `true` | When true (default) a kinematic RigidBody3D the character stands on carries it: every physics step it moves with the platform's displacement (velocity, or a teleport by script) and turns about the platform's centre with its angularVelocity (the character also yaws with it). Set false and it stays where it is, so a moving platform slides out from under it and the script must carry it. (not released yet, on main after 0.2.0) |
| `applyWeight` | bool | `true` | When true (default) a character standing on a dynamic RigidBody3D presses on it with mass * gravity at its feet, every physics step: a seesaw tips towards the side it stands on, a bridge plank or a crate feels the load. Set false for a character that weighs nothing. (not released yet, on main after 0.2.0) |
| `mass` | float | `70.0` | Weight in kilograms pressed on the dynamic body below when applyWeight is on (see applyWeight). Range 0.0..100000.0. (not released yet, on main after 0.2.0) |
| `pushStrength` | float | `1.0` | How hard the character shoves the free dynamic bodies it walks into: 1 (default) gives them its own speed, 0.5 half of it, 0 none (they block it like a wall). A body held by a Joint3D (a seesaw on its pivot, a bridge plank, a door) is never shoved whatever the value. Range 0.0..10.0. (not released yet, on main after 0.2.0) |
| `isGrounded` | bool | `false` | Runtime: true when the last move ended standing on walkable ground (slope up to slopeLimit). Read-only. Runtime-only (not saved). |
| `groundNormal` | vec3 | `[0.0,1.0,0.0]` | Runtime: the normal of the ground under the character after the last move (up when airborne). Read-only. Runtime-only (not saved). |

### NavMesh3D

Not released yet (on main after 0.2.0).

A navigation mesh for path finding on 3D ground. It is baked from the STATIC colliders (no RigidBody3D, or a static one) inside a box around this entity, when the scene loads (autoBake) or with the nav.bake command: the box is cut into cells of cellSize; a cell is walkable where the ground is not steeper than maxSlope, has agentHeight of free space above it and lies at least agentRadius from a wall or a drop; neighbouring cells connect when their heights differ by at most stepHeight. Then nav.findPath(from, to) in scripts (the nav.find_path command) returns the points of a path over it. A collider with Collider3D.navObstacle is not baked: it blocks the cells it covers while it is there; one with Collider3D.navWalkable (a bridge, a lift) adds its top surface while it is there, and NavLink3D entities add off-mesh links. The mesh is deterministic: the same colliders always give the same cells. See docs/NAVIGATION.md.

| Field | Type | Default | Description |
|---|---|---|---|
| `size` | vec3 | `[40.0,10.0,40.0]` | Size [x, y, z] in meters of the baked box, centred on the entity's world position; rotation and scale are ignored. Cover the whole level: ground outside is not walkable and the box edge counts as a drop. y must reach from below the lowest floor to above the highest head. |
| `cellSize` | float | `0.25` | Width of one cell on the ground plane, meters. Smaller = finer paths, more memory and a slower bake (cells = x/cellSize * z/cellSize, at most 4 million). Walls thinner than half a cell can be missed. Range 0.05..10.0. |
| `cellHeight` | float | `0.05` | Heights are rounded to a multiple of this, meters; a path is up to half of it above or below the true surface. Keep it at most stepHeight / 4. Range 0.01..5.0. |
| `agentRadius` | float | `0.3` | Radius in meters of the walker the mesh is made for: walkable cells stay this far from walls and drops, so a body of that radius never touches them. findPath with a bigger radius is an error (bake another NavMesh3D for the bigger agent). Range 0.0..10.0. |
| `agentHeight` | float | `1.8` | Height in meters of the walker; ground with less free space above it (under a low ceiling or table) is not walkable. Range 0.1..50.0. |
| `stepHeight` | float | `0.4` | Highest step in meters the walker climbs; a higher ledge is a wall. Match CharacterController3D.stepOffset. Range 0.0..10.0. |
| `maxSlope` | float | `45.0` | Steepest walkable ground in degrees; steeper ground is a wall. Match CharacterController3D.slopeLimit. Range 0.0..89.0. |
| `autoBake` | bool | `true` | true (default): bake when the scene loads and again when a static collider is added, moved or removed. false: only the nav.bake command bakes (and a scene without a bake has no paths). |
| `enabled` | bool | `true` | false = nav.findPath ignores this mesh (and it is not baked). |
| `walkableCells` | int | `0` | Runtime: how many cells can be walked on after the last bake (read only). Read-only. Runtime-only (not saved). |
| `regions` | int | `0` | Runtime: how many separate walkable areas the last bake found; two points in different areas have no path (read only). Read-only. Runtime-only (not saved). |

### NavLink3D

Not released yet (on main after 0.2.0).

An off-mesh link of the NavMesh3D: a jump across a gap, a climb up a ladder, a drop off a ledge. The walkable cells do not join the two places, so this joins them: the link runs from this entity's world position to `end` (both are moved onto the nearest walkable cell). nav.findPath may take it, and its result lists where in `links` (the index of the point where the link starts and the link's entity), so a script makes the character jump or climb there; the next point is where it ends. See docs/NAVIGATION.md.

| Field | Type | Default | Description |
|---|---|---|---|
| `end` | vec3 | `[0.0,0.0,0.0]` | World position [x, y, z] where the link ends. The entity's own world position is where it starts. Both ends must be within the NavMesh3D box and near walkable ground (agentRadius + two cells horizontally, about stepHeight up and agentHeight down); a link whose end is not is ignored, and nav.info says so. |
| `bidirectional` | bool | `true` | true (default): the path may also go from `end` to the entity. false: one way only, from the entity to `end` (a drop, a jump that cannot be climbed back). |
| `cost` | float | `0.0` | Extra path length in meters added to the straight distance between the two ends. 0 = as long as the straight line; raise it so a path prefers walking around when that is not much longer. Range 0.0..1000.0. |

## Audio

### AudioSource

Plays a sound clip from the entity. Set playOnStart to start automatically, or set `playing` from a script to trigger it.

| Field | Type | Default | Description |
|---|---|---|---|
| `clip` | asset (audio) | `""` | Project-relative path of the sound (.wav, .ogg, .mp3 or .qoa). |
| `volume` | float | `1.0` | Loudness multiplier, 0 (silent) to 1 (full). Range 0.0..1.0. |
| `pitch` | float | `1.0` | Playback speed multiplier; 2 = one octave higher and twice as fast. Range 0.05..8.0. |
| `loop` | bool | `false` | Restart the clip when it ends. |
| `playOnStart` | bool | `false` | Start playing when the entity spawns / the scene loads. |
| `playing` | bool | `false` | Runtime state: true while a voice is playing. Set true to play, false to stop. Runtime-only (not saved). |
| `spatial` | bool | `false` | true = pan and attenuate relative to the AudioListener; false = plain stereo (music, UI). |
| `range` | float | `800.0` | Spatial only: distance in world units where the volume reaches 0. Range 0.0..1000000.0. |

### AudioListener

The 'ears' for spatial audio, usually on the camera or player. If no listener exists, the primary camera is used.

| Field | Type | Default | Description |
|---|---|---|---|
| `volume` | float | `1.0` | Master volume multiplier for everything this listener hears. Range 0.0..4.0. |

## UI

### Panel

Since 0.1.6.

Container widget: a background rectangle (solid or 9-slice) whose children are laid out in a row, a column or a grid. Children are ordinary entities parented to it (Button, Toggle, Slider, TextField, Text, other Panels...). Every UI widget is SCREEN SPACE only (design pixels, origin top-left, +Y down; no `space` field); rotation and scale of UI entities are ignored by layout and hit-testing. Widgets draw above the world and above HUD Text; events (ui.click, ui.change...) and focus are in docs/SCRIPTING.md.

| Field | Type | Default | Description |
|---|---|---|---|
| `size` | vec2 | `[320.0,240.0]` | Size [w, h] in design pixels. The default depends on the kind (Button 240 x 56, Toggle 240 x 40, Slider 320 x 40, TextField 320 x 48, Panel and ScrollList 320 x 240, TouchStick 200 x 200, TouchButton 96 x 96, Captions 960 x 180, Video 640 x 360). A Panel with fit = true recomputes it every frame. |
| `pivot` | vec2 | `[0.5,0.5]` | Which point of the widget sits on the position: [0.5, 0.5] = its centre (default), [0, 1] = top-left corner, [1, 0] = bottom-right. Same meaning as Shape2D.pivot in screen space: +Y is down on screen but pivot [0, 1] is still the visual top-left. Layout does not care about the pivot of its children. |
| `anchor` | vec2 | `[0.0,0.0]` | Screen point the position is relative to, as a fraction of the screen: [0, 0] top-left (default), [1, 0] top-right, [0.5, 0.5] centre. Anchor [0.5, 0.5] with position [0, 0] centres the widget on any aspect ratio. The anchor of the widget itself is used, not its parent's: children of a Panel normally keep anchor [0, 0] and are placed by the Panel's layout. |
| `safeArea` | bool | `false` | Screen space only. true: the anchor names a point of the SAFE area, the screen minus the notch, rounded corners and system bars of a phone (screen.safeArea in scripts), instead of the whole screen: anchor [0, 0] is the top-left corner of the safe area, [1, 1] its bottom-right. Keeps HUD and buttons out of the notch. On a screen without cutouts (desktop, most tablets) it changes nothing. Default false (true on TouchStick and TouchButton). (since 0.2.0) |
| `layer` | int | `200` | Draw order of the background; higher is on top. Defaults to 200, above HUD Text (layer 100). The label draws at layer + 1 and the focus ring at layer + 2. Pointer hit-testing follows the same order: the highest layer, then the latest entity, under the pointer is the hovered widget. |
| `color` | color | `[0.16,0.18,0.24,0.92]` | Background colour, multiplied with `texture` when there is one. Hovered widgets are brightened, pressed ones darkened, non-interactable ones drawn at half alpha. Accepts [r,g,b,a], "#rrggbb" or a name. |
| `texture` | asset (texture) | `""` | Optional background image (project path), drawn as a 9-slice (see `slice`) with nearest-neighbour sampling, so pixel art stays crisp. Empty draws a solid rectangle of `color`. |
| `slice` | vec4 | `[0.0,0.0,0.0,0.0]` | 9-slice borders in TEXTURE pixels [left, top, right, bottom]. The four corners are drawn unscaled (1 texture pixel = 1 design pixel), the edges stretch along one axis and the centre along both, so one small image gives panels of any size. [0, 0, 0, 0] (default) stretches the whole image. When the widget is smaller than left + right (or top + bottom) the borders shrink proportionally. |
| `layout` | enum: none \\| row \\| column \\| grid | `"none"` | How children are placed, every frame: none = they keep their own positions; row / column = one after the other along that axis; grid = `columns` per row, every cell as large as the largest child. Children are the active child entities that have a size (a widget, or a Text / Sprite / Shape2D in screen space); the rest are skipped. A child's own position, anchor and pivot do not matter: layout moves its Transform.position so it lands in its slot. |
| `spacing` | float | `8.0` | Gap in design pixels between children (a grid uses it on both axes). Range 0.0..10000.0. |
| `padding` | vec4 | `[16.0,16.0,16.0,16.0]` | Space [left, top, right, bottom] between the panel's edge and its children. |
| `columns` | int | `2` | Grid only: number of columns. Range 1.0..64.0. |
| `align` | enum: start \\| center \\| end | `"center"` | Cross-axis alignment: horizontal in a column, vertical in a row, both axes inside a grid cell. start = left / top, end = right / bottom (a panel with `direction` rtl, or auto in a right-to-left language, swaps left and right: start = right). |
| `justify` | enum: start \\| center \\| end | `"start"` | Main-axis placement of the whole run of children inside the padded box: start = packed at the left / top, center, end = packed at the right / bottom (with a right-to-left `direction`, start = the right edge). A grid is placed as one block on both axes. |
| `direction` | enum: ltr \\| auto \\| rtl | `"ltr"` | Horizontal reading direction of the layout. ltr (default) = a row runs left to right and start means left. rtl = the first child of a row is at the right, a grid fills its columns from the right and align / justify `start` means the right edge. auto = ltr in a left-to-right language and rtl in Arabic, Hebrew and the other right-to-left languages (i18n.direction): one menu that mirrors itself. (since 0.2.0) |
| `fit` | bool | `false` | true: `size` is recomputed every frame as the content size + padding (needs layout row, column or grid); the pivot then decides which point of the fitted box stays on the position. |
| `uniformSize` | bool | `false` | true: every Button, Toggle and Slider with autoSize anywhere inside this panel (children, and the children of the panels and lists inside it; active ones only) takes the size of the largest of them, width and height separately, every layout. Widgets without autoSize keep their size and do not count. Use it for a grid of level buttons as wide as the widest label. (since 0.2.0) |
| `fallbackLayout` | enum: none \\| row \\| column \\| grid | `"none"` | Layout used instead of `layout` when the panel laid out with `layout` would not fit the screen (none = never switch). The panel leaves the screen when its content size + padding, or the size of the outermost fit Panel around it, is wider than the screen and `layout` is row or grid, or taller and `layout` is column or grid. The deepest panels switch first, so a menu changes one level at a time until it fits; the choice is made again every frame, so it follows the text size and the language and goes back to `layout` when the texts shrink. Example: a column of two blocks with fallbackLayout "row" stands them side by side at a big text size; a row of buttons with fallbackLayout "column" stacks them. Scripts that must adapt read `usingFallback`. (since 0.2.0) |
| `usingFallback` | bool | `false` | Runtime: true while the panel is laid out with `fallbackLayout` instead of `layout`. Read-only. Runtime-only (not saved). (since 0.2.0) |

### Button

Since 0.1.6.

Clickable button with a text label. Activated by the mouse / a touch, or by ui_submit (Enter, Space, gamepad A) while it has focus; the event is ui.click {id}. Focus rules and the other widgets: see Panel.

| Field | Type | Default | Description |
|---|---|---|---|
| `size` | vec2 | `[240.0,56.0]` | Size [w, h] in design pixels. The default depends on the kind (Button 240 x 56, Toggle 240 x 40, Slider 320 x 40, TextField 320 x 48, Panel and ScrollList 320 x 240, TouchStick 200 x 200, TouchButton 96 x 96, Captions 960 x 180, Video 640 x 360). A Panel with fit = true recomputes it every frame. |
| `pivot` | vec2 | `[0.5,0.5]` | Which point of the widget sits on the position: [0.5, 0.5] = its centre (default), [0, 1] = top-left corner, [1, 0] = bottom-right. Same meaning as Shape2D.pivot in screen space: +Y is down on screen but pivot [0, 1] is still the visual top-left. Layout does not care about the pivot of its children. |
| `anchor` | vec2 | `[0.0,0.0]` | Screen point the position is relative to, as a fraction of the screen: [0, 0] top-left (default), [1, 0] top-right, [0.5, 0.5] centre. Anchor [0.5, 0.5] with position [0, 0] centres the widget on any aspect ratio. The anchor of the widget itself is used, not its parent's: children of a Panel normally keep anchor [0, 0] and are placed by the Panel's layout. |
| `safeArea` | bool | `false` | Screen space only. true: the anchor names a point of the SAFE area, the screen minus the notch, rounded corners and system bars of a phone (screen.safeArea in scripts), instead of the whole screen: anchor [0, 0] is the top-left corner of the safe area, [1, 1] its bottom-right. Keeps HUD and buttons out of the notch. On a screen without cutouts (desktop, most tablets) it changes nothing. Default false (true on TouchStick and TouchButton). (since 0.2.0) |
| `layer` | int | `200` | Draw order of the background; higher is on top. Defaults to 200, above HUD Text (layer 100). The label draws at layer + 1 and the focus ring at layer + 2. Pointer hit-testing follows the same order: the highest layer, then the latest entity, under the pointer is the hovered widget. |
| `color` | color | `[0.16,0.18,0.24,0.92]` | Background colour, multiplied with `texture` when there is one. Hovered widgets are brightened, pressed ones darkened, non-interactable ones drawn at half alpha. Accepts [r,g,b,a], "#rrggbb" or a name. |
| `texture` | asset (texture) | `""` | Optional background image (project path), drawn as a 9-slice (see `slice`) with nearest-neighbour sampling, so pixel art stays crisp. Empty draws a solid rectangle of `color`. |
| `slice` | vec4 | `[0.0,0.0,0.0,0.0]` | 9-slice borders in TEXTURE pixels [left, top, right, bottom]. The four corners are drawn unscaled (1 texture pixel = 1 design pixel), the edges stretch along one axis and the centre along both, so one small image gives panels of any size. [0, 0, 0, 0] (default) stretches the whole image. When the widget is smaller than left + right (or top + bottom) the borders shrink proportionally. |
| `font` | asset (font) | `""` | Font of the label: project path of a .ttf, empty = the built-in font (same values as Text.font). |
| `key` | string | `""` | Localization key, e.g. "menu.play" (docs/LOCALIZATION.md). Empty (default) = not translated. With a key, the runtime writes the translation into the widget's own text: Button.text, Toggle.label, Slider.label, or TextField.placeholder (never TextField.text, which is what the player typed). It does so when a scene or prefab loads, every frame and when the language changes, so that field is overwritten at run time while `key` is set. A key that no string table has keeps the text written in the field and logs one warning. (since 0.2.0) |
| `keyArgs` | json | `{}` | Values for the {placeholders} of `key`, an object of name -> string or number: {"score": 12} fills "Score: {score}" (and `count` picks the form of a plural entry). Set it once from a script (`entity.set("Text", { keyArgs: { score } })` or `scene.set_component`) instead of rewriting the text every frame: the engine formats the translation with them when the text is localized, when the args change and when the language changes, so a language switch keeps them. Empty (default) = no arguments. Ignored while `key` is empty. (not released yet, on main after 0.2.0) |
| `fontSize` | float | `24.0` | Label glyph height in design pixels. Range 1.0..4096.0. |
| `maxTextScale` | float | `0.0` | > 0: the player's text size (ui.textScale) stops growing this text at this scale, so a heading or a round button label does not outgrow its place: 1.3 means it is drawn at most 1.3 times its fontSize however big the option is. It only limits growth: at a text size below the cap it is drawn at the player's size. 0 (default) = no cap. Measuring (autoSize, layout, ui.measureText, ui.rectOf) and drawing use the same capped size. Range 0.0..3.0. (not released yet, on main after 0.2.0) |
| `textColor` | color | `[1.0,1.0,1.0,1.0]` | Label colour. |
| `accentColor` | color | `[1.0,0.76,0.2,1.0]` | Colour of the focus ring, the slider fill and knob, the toggle check mark and the text caret. |
| `interactable` | bool | `true` | false: the widget is drawn at half alpha and is never hovered, focused or clicked, so it sends no ui events. A focused widget that becomes non-interactable loses focus. |
| `autoFocus` | bool | `false` | Focus rule: nothing takes keyboard / gamepad focus by itself, except that when NOTHING is focused the first widget with autoFocus = true (reading order: top, then left) takes it. Mark the first item of each menu; HUD buttons then stay out of gamepad play (Space / A must never click a HUD button). When the focused widget disappears (inactive, destroyed, not interactable) autoFocus applies again. When every visible autoFocus widget has interactable = false (a greyed-out buy button), the first interactable widget in reading order takes the focus instead, so the gamepad is never left with nothing focused. |
| `focused` | bool | `false` | Runtime: true while the widget has keyboard / gamepad focus. Written by the UI every frame; move focus with ui.focus(entity). Read-only. Runtime-only (not saved). |
| `hovered` | bool | `false` | Runtime: the pointer (mouse or first touch) is over this widget, the top-most visible interactable one. Read-only. Runtime-only (not saved). |
| `pressed` | bool | `false` | Runtime: the pointer is held down on this widget. Read-only. Runtime-only (not saved). |
| `text` | string | `"Button"` | Label, centred on the button. ` ` starts a new line; every line is centred. Text longer than the button is clipped to it: use `maxWidth` to wrap it, `autoSize` to grow the button or `autoShrink` to shrink the text. |
| `maxWidth` | float | `0.0` | > 0 wraps the label at this width in design pixels (like Text.maxWidth); 0 = the label wraps only at ` `. With autoSize the button is at most maxWidth plus its margins wide and grows taller instead. Range 0.0..100000.0. (since 0.2.0) |
| `autoSize` | bool | `false` | true: the widget is at least its design `size` and grows to fit its label at the current text size (ui.textScale) and language, re-laid out when either changes (needs no script). Width and height are set every frame, so writing `size` while this is on sets the NEW design size; turn it off to keep a size. A Button, Toggle or Slider label wraps at its `maxWidth` (and the widget grows taller); with no maxWidth the label does not wrap. autoSize makes room for the full-size label, so autoShrink only works on a widget that does not grow. false (default): the widget keeps its size and a big label sticks out of it (Button labels are clipped). (since 0.2.0) |
| `autoShrink` | bool | `false` | true: when the text does not fit its box at the current text size (ui.textScale) and language, the font is made smaller until it does, never under `minFontSize` (so a German label in a fixed button stays inside at 200 % text, and a long translation is smaller instead of cut). It is decided every frame from the laid-out size, with no script. If it still does not fit at minFontSize it is drawn there and ui.overflowed(id) is true. false (default): the size is never reduced. (not released yet, on main after 0.2.0) |
| `minFontSize` | float | `10.0` | autoShrink floor in design pixels, before ui.textScale (the floor is minFontSize times the player's text size, capped by maxTextScale, so the accessibility setting keeps working). Never above fontSize. Range 1.0..4096.0. (not released yet, on main after 0.2.0) |

### Toggle

Since 0.1.6.

Check box with a label: a square box at the left (a filled inner square in accentColor when on) and the label to its right. Flips on click or ui_submit; the event is ui.change {id, value: bool}.

| Field | Type | Default | Description |
|---|---|---|---|
| `size` | vec2 | `[240.0,40.0]` | Size [w, h] in design pixels. The default depends on the kind (Button 240 x 56, Toggle 240 x 40, Slider 320 x 40, TextField 320 x 48, Panel and ScrollList 320 x 240, TouchStick 200 x 200, TouchButton 96 x 96, Captions 960 x 180, Video 640 x 360). A Panel with fit = true recomputes it every frame. |
| `pivot` | vec2 | `[0.5,0.5]` | Which point of the widget sits on the position: [0.5, 0.5] = its centre (default), [0, 1] = top-left corner, [1, 0] = bottom-right. Same meaning as Shape2D.pivot in screen space: +Y is down on screen but pivot [0, 1] is still the visual top-left. Layout does not care about the pivot of its children. |
| `anchor` | vec2 | `[0.0,0.0]` | Screen point the position is relative to, as a fraction of the screen: [0, 0] top-left (default), [1, 0] top-right, [0.5, 0.5] centre. Anchor [0.5, 0.5] with position [0, 0] centres the widget on any aspect ratio. The anchor of the widget itself is used, not its parent's: children of a Panel normally keep anchor [0, 0] and are placed by the Panel's layout. |
| `safeArea` | bool | `false` | Screen space only. true: the anchor names a point of the SAFE area, the screen minus the notch, rounded corners and system bars of a phone (screen.safeArea in scripts), instead of the whole screen: anchor [0, 0] is the top-left corner of the safe area, [1, 1] its bottom-right. Keeps HUD and buttons out of the notch. On a screen without cutouts (desktop, most tablets) it changes nothing. Default false (true on TouchStick and TouchButton). (since 0.2.0) |
| `layer` | int | `200` | Draw order of the background; higher is on top. Defaults to 200, above HUD Text (layer 100). The label draws at layer + 1 and the focus ring at layer + 2. Pointer hit-testing follows the same order: the highest layer, then the latest entity, under the pointer is the hovered widget. |
| `color` | color | `[0.16,0.18,0.24,0.92]` | Background colour, multiplied with `texture` when there is one. Hovered widgets are brightened, pressed ones darkened, non-interactable ones drawn at half alpha. Accepts [r,g,b,a], "#rrggbb" or a name. |
| `texture` | asset (texture) | `""` | Optional background image (project path), drawn as a 9-slice (see `slice`) with nearest-neighbour sampling, so pixel art stays crisp. Empty draws a solid rectangle of `color`. |
| `slice` | vec4 | `[0.0,0.0,0.0,0.0]` | 9-slice borders in TEXTURE pixels [left, top, right, bottom]. The four corners are drawn unscaled (1 texture pixel = 1 design pixel), the edges stretch along one axis and the centre along both, so one small image gives panels of any size. [0, 0, 0, 0] (default) stretches the whole image. When the widget is smaller than left + right (or top + bottom) the borders shrink proportionally. |
| `font` | asset (font) | `""` | Font of the label: project path of a .ttf, empty = the built-in font (same values as Text.font). |
| `key` | string | `""` | Localization key, e.g. "menu.play" (docs/LOCALIZATION.md). Empty (default) = not translated. With a key, the runtime writes the translation into the widget's own text: Button.text, Toggle.label, Slider.label, or TextField.placeholder (never TextField.text, which is what the player typed). It does so when a scene or prefab loads, every frame and when the language changes, so that field is overwritten at run time while `key` is set. A key that no string table has keeps the text written in the field and logs one warning. (since 0.2.0) |
| `keyArgs` | json | `{}` | Values for the {placeholders} of `key`, an object of name -> string or number: {"score": 12} fills "Score: {score}" (and `count` picks the form of a plural entry). Set it once from a script (`entity.set("Text", { keyArgs: { score } })` or `scene.set_component`) instead of rewriting the text every frame: the engine formats the translation with them when the text is localized, when the args change and when the language changes, so a language switch keeps them. Empty (default) = no arguments. Ignored while `key` is empty. (not released yet, on main after 0.2.0) |
| `fontSize` | float | `24.0` | Label glyph height in design pixels. Range 1.0..4096.0. |
| `maxTextScale` | float | `0.0` | > 0: the player's text size (ui.textScale) stops growing this text at this scale, so a heading or a round button label does not outgrow its place: 1.3 means it is drawn at most 1.3 times its fontSize however big the option is. It only limits growth: at a text size below the cap it is drawn at the player's size. 0 (default) = no cap. Measuring (autoSize, layout, ui.measureText, ui.rectOf) and drawing use the same capped size. Range 0.0..3.0. (not released yet, on main after 0.2.0) |
| `textColor` | color | `[1.0,1.0,1.0,1.0]` | Label colour. |
| `accentColor` | color | `[1.0,0.76,0.2,1.0]` | Colour of the focus ring, the slider fill and knob, the toggle check mark and the text caret. |
| `interactable` | bool | `true` | false: the widget is drawn at half alpha and is never hovered, focused or clicked, so it sends no ui events. A focused widget that becomes non-interactable loses focus. |
| `autoFocus` | bool | `false` | Focus rule: nothing takes keyboard / gamepad focus by itself, except that when NOTHING is focused the first widget with autoFocus = true (reading order: top, then left) takes it. Mark the first item of each menu; HUD buttons then stay out of gamepad play (Space / A must never click a HUD button). When the focused widget disappears (inactive, destroyed, not interactable) autoFocus applies again. When every visible autoFocus widget has interactable = false (a greyed-out buy button), the first interactable widget in reading order takes the focus instead, so the gamepad is never left with nothing focused. |
| `focused` | bool | `false` | Runtime: true while the widget has keyboard / gamepad focus. Written by the UI every frame; move focus with ui.focus(entity). Read-only. Runtime-only (not saved). |
| `hovered` | bool | `false` | Runtime: the pointer (mouse or first touch) is over this widget, the top-most visible interactable one. Read-only. Runtime-only (not saved). |
| `pressed` | bool | `false` | Runtime: the pointer is held down on this widget. Read-only. Runtime-only (not saved). |
| `label` | string | `"Toggle"` | Text to the right of the box. |
| `maxWidth` | float | `0.0` | > 0 wraps the label at this width in design pixels (like Text.maxWidth); 0 = one line. With autoSize the toggle is at most maxWidth plus the box and margins wide and grows taller instead. Range 0.0..100000.0. (not released yet, on main after 0.2.0) |
| `autoSize` | bool | `false` | true: the widget is at least its design `size` and grows to fit its label at the current text size (ui.textScale) and language, re-laid out when either changes (needs no script). Width and height are set every frame, so writing `size` while this is on sets the NEW design size; turn it off to keep a size. A Button, Toggle or Slider label wraps at its `maxWidth` (and the widget grows taller); with no maxWidth the label does not wrap. autoSize makes room for the full-size label, so autoShrink only works on a widget that does not grow. false (default): the widget keeps its size and a big label sticks out of it (Button labels are clipped). (since 0.2.0) |
| `autoShrink` | bool | `false` | true: when the text does not fit its box at the current text size (ui.textScale) and language, the font is made smaller until it does, never under `minFontSize` (so a German label in a fixed button stays inside at 200 % text, and a long translation is smaller instead of cut). It is decided every frame from the laid-out size, with no script. If it still does not fit at minFontSize it is drawn there and ui.overflowed(id) is true. false (default): the size is never reduced. (not released yet, on main after 0.2.0) |
| `minFontSize` | float | `10.0` | autoShrink floor in design pixels, before ui.textScale (the floor is minFontSize times the player's text size, capped by maxTextScale, so the accessibility setting keeps working). Never above fontSize. Range 1.0..4096.0. (not released yet, on main after 0.2.0) |
| `value` | bool | `false` | true = checked. Scripts may write it; no event is sent for a write. |

### Slider

Since 0.1.6.

Horizontal value slider: label in the left 35% (when not empty), the track in the next 50% (85% without a label) with a fill and a knob in accentColor, the value in the last 15% (with labelAbove the label is above the track and the track gets the 85%). Left / right (ui_left / ui_right, d-pad, stick) change the value while focused; dragging the track with the mouse sets it. Event: ui.change {id, value: number}.

| Field | Type | Default | Description |
|---|---|---|---|
| `size` | vec2 | `[320.0,40.0]` | Size [w, h] in design pixels. The default depends on the kind (Button 240 x 56, Toggle 240 x 40, Slider 320 x 40, TextField 320 x 48, Panel and ScrollList 320 x 240, TouchStick 200 x 200, TouchButton 96 x 96, Captions 960 x 180, Video 640 x 360). A Panel with fit = true recomputes it every frame. |
| `pivot` | vec2 | `[0.5,0.5]` | Which point of the widget sits on the position: [0.5, 0.5] = its centre (default), [0, 1] = top-left corner, [1, 0] = bottom-right. Same meaning as Shape2D.pivot in screen space: +Y is down on screen but pivot [0, 1] is still the visual top-left. Layout does not care about the pivot of its children. |
| `anchor` | vec2 | `[0.0,0.0]` | Screen point the position is relative to, as a fraction of the screen: [0, 0] top-left (default), [1, 0] top-right, [0.5, 0.5] centre. Anchor [0.5, 0.5] with position [0, 0] centres the widget on any aspect ratio. The anchor of the widget itself is used, not its parent's: children of a Panel normally keep anchor [0, 0] and are placed by the Panel's layout. |
| `safeArea` | bool | `false` | Screen space only. true: the anchor names a point of the SAFE area, the screen minus the notch, rounded corners and system bars of a phone (screen.safeArea in scripts), instead of the whole screen: anchor [0, 0] is the top-left corner of the safe area, [1, 1] its bottom-right. Keeps HUD and buttons out of the notch. On a screen without cutouts (desktop, most tablets) it changes nothing. Default false (true on TouchStick and TouchButton). (since 0.2.0) |
| `layer` | int | `200` | Draw order of the background; higher is on top. Defaults to 200, above HUD Text (layer 100). The label draws at layer + 1 and the focus ring at layer + 2. Pointer hit-testing follows the same order: the highest layer, then the latest entity, under the pointer is the hovered widget. |
| `color` | color | `[0.16,0.18,0.24,0.92]` | Background colour, multiplied with `texture` when there is one. Hovered widgets are brightened, pressed ones darkened, non-interactable ones drawn at half alpha. Accepts [r,g,b,a], "#rrggbb" or a name. |
| `texture` | asset (texture) | `""` | Optional background image (project path), drawn as a 9-slice (see `slice`) with nearest-neighbour sampling, so pixel art stays crisp. Empty draws a solid rectangle of `color`. |
| `slice` | vec4 | `[0.0,0.0,0.0,0.0]` | 9-slice borders in TEXTURE pixels [left, top, right, bottom]. The four corners are drawn unscaled (1 texture pixel = 1 design pixel), the edges stretch along one axis and the centre along both, so one small image gives panels of any size. [0, 0, 0, 0] (default) stretches the whole image. When the widget is smaller than left + right (or top + bottom) the borders shrink proportionally. |
| `font` | asset (font) | `""` | Font of the label: project path of a .ttf, empty = the built-in font (same values as Text.font). |
| `key` | string | `""` | Localization key, e.g. "menu.play" (docs/LOCALIZATION.md). Empty (default) = not translated. With a key, the runtime writes the translation into the widget's own text: Button.text, Toggle.label, Slider.label, or TextField.placeholder (never TextField.text, which is what the player typed). It does so when a scene or prefab loads, every frame and when the language changes, so that field is overwritten at run time while `key` is set. A key that no string table has keeps the text written in the field and logs one warning. (since 0.2.0) |
| `keyArgs` | json | `{}` | Values for the {placeholders} of `key`, an object of name -> string or number: {"score": 12} fills "Score: {score}" (and `count` picks the form of a plural entry). Set it once from a script (`entity.set("Text", { keyArgs: { score } })` or `scene.set_component`) instead of rewriting the text every frame: the engine formats the translation with them when the text is localized, when the args change and when the language changes, so a language switch keeps them. Empty (default) = no arguments. Ignored while `key` is empty. (not released yet, on main after 0.2.0) |
| `fontSize` | float | `24.0` | Label glyph height in design pixels. Range 1.0..4096.0. |
| `maxTextScale` | float | `0.0` | > 0: the player's text size (ui.textScale) stops growing this text at this scale, so a heading or a round button label does not outgrow its place: 1.3 means it is drawn at most 1.3 times its fontSize however big the option is. It only limits growth: at a text size below the cap it is drawn at the player's size. 0 (default) = no cap. Measuring (autoSize, layout, ui.measureText, ui.rectOf) and drawing use the same capped size. Range 0.0..3.0. (not released yet, on main after 0.2.0) |
| `textColor` | color | `[1.0,1.0,1.0,1.0]` | Label colour. |
| `accentColor` | color | `[1.0,0.76,0.2,1.0]` | Colour of the focus ring, the slider fill and knob, the toggle check mark and the text caret. |
| `interactable` | bool | `true` | false: the widget is drawn at half alpha and is never hovered, focused or clicked, so it sends no ui events. A focused widget that becomes non-interactable loses focus. |
| `autoFocus` | bool | `false` | Focus rule: nothing takes keyboard / gamepad focus by itself, except that when NOTHING is focused the first widget with autoFocus = true (reading order: top, then left) takes it. Mark the first item of each menu; HUD buttons then stay out of gamepad play (Space / A must never click a HUD button). When the focused widget disappears (inactive, destroyed, not interactable) autoFocus applies again. When every visible autoFocus widget has interactable = false (a greyed-out buy button), the first interactable widget in reading order takes the focus instead, so the gamepad is never left with nothing focused. |
| `focused` | bool | `false` | Runtime: true while the widget has keyboard / gamepad focus. Written by the UI every frame; move focus with ui.focus(entity). Read-only. Runtime-only (not saved). |
| `hovered` | bool | `false` | Runtime: the pointer (mouse or first touch) is over this widget, the top-most visible interactable one. Read-only. Runtime-only (not saved). |
| `pressed` | bool | `false` | Runtime: the pointer is held down on this widget. Read-only. Runtime-only (not saved). |
| `label` | string | `""` | Text at the left (or above the track with labelAbove); empty gives the track the extra room. |
| `maxWidth` | float | `0.0` | > 0 wraps the label at this width in design pixels (like Text.maxWidth); 0 = one line. With autoSize the slider grows taller for the extra lines. Range 0.0..100000.0. (not released yet, on main after 0.2.0) |
| `labelAbove` | bool | `false` | true: the label is drawn above the track on the slider's full width (wrapping at maxWidth or the width) and the track, knob and value sit in a row of 28 px at the bottom, so a long label does not squeeze the track. The slider needs a height of the label plus 28 px (autoSize adds it). false (default): the label is in the left 35%. (not released yet, on main after 0.2.0) |
| `autoSize` | bool | `false` | true: the widget is at least its design `size` and grows to fit its label at the current text size (ui.textScale) and language, re-laid out when either changes (needs no script). Width and height are set every frame, so writing `size` while this is on sets the NEW design size; turn it off to keep a size. A Button, Toggle or Slider label wraps at its `maxWidth` (and the widget grows taller); with no maxWidth the label does not wrap. autoSize makes room for the full-size label, so autoShrink only works on a widget that does not grow. false (default): the widget keeps its size and a big label sticks out of it (Button labels are clipped). (since 0.2.0) |
| `autoShrink` | bool | `false` | true: when the text does not fit its box at the current text size (ui.textScale) and language, the font is made smaller until it does, never under `minFontSize` (so a German label in a fixed button stays inside at 200 % text, and a long translation is smaller instead of cut). It is decided every frame from the laid-out size, with no script. If it still does not fit at minFontSize it is drawn there and ui.overflowed(id) is true. false (default): the size is never reduced. (not released yet, on main after 0.2.0) |
| `minFontSize` | float | `10.0` | autoShrink floor in design pixels, before ui.textScale (the floor is minFontSize times the player's text size, capped by maxTextScale, so the accessibility setting keeps working). Never above fontSize. Range 1.0..4096.0. (not released yet, on main after 0.2.0) |
| `value` | float | `0.5` | Current value, always within [min, max] and snapped to `step` by the UI. Scripts may write it; no event is sent for a write. |
| `min` | float | `0.0` | Smallest value. |
| `max` | float | `1.0` | Largest value. |
| `step` | float | `0.1` | Keyboard / gamepad increment, and the grid the value is snapped to (also when dragging). 0 = continuous: keys move (max - min) / 20 per press and dragging is not snapped. Range 0.0..1000000.0. |
| `showValue` | bool | `true` | Draw the value at the right. Without `format`: "60%" when min is 0 and max is 1, else the number with up to 2 decimals. |
| `format` | string | `""` | Pattern of the shown value, e.g. "{v}%" or "{v:1}x". {v} is the value with up to 2 decimals (trailing zeros dropped), {v:N} the value with exactly N decimals (0 to 6), {percent} the value times 100 rounded to a whole number (a 0.3..1 opacity slider shows 30%..100% with "{percent}%"; {percent} does not depend on min and max). A doubled brace writes one brace; any other {name} is drawn as it is, so a typo is visible. Empty = the default of showValue. It sizes autoSize and draws in the value column only; ui.state `value` stays the number. Use formatKey for a pattern per language. (not released yet, on main after 0.2.0) |
| `formatKey` | string | `""` | Localization key whose translation is the pattern, written into `format` like `key` writes the label ("slider.percent": "{v} %" in French). "" = none. A key no table has is reported once and `format` stays as it is. (not released yet, on main after 0.2.0) |

### TextField

Since 0.1.6.

Single-line text input. While focused it appends the typed characters (Input text), Backspace removes the last one (it repeats while held) and Enter submits. There is no caret movement: the caret stays at the end. Events: ui.change {id, value} on every edit (one per frame), ui.submit {id, value} on Enter. Left / right do nothing in a TextField and Space types a space (ui_submit is ignored).

| Field | Type | Default | Description |
|---|---|---|---|
| `size` | vec2 | `[320.0,48.0]` | Size [w, h] in design pixels. The default depends on the kind (Button 240 x 56, Toggle 240 x 40, Slider 320 x 40, TextField 320 x 48, Panel and ScrollList 320 x 240, TouchStick 200 x 200, TouchButton 96 x 96, Captions 960 x 180, Video 640 x 360). A Panel with fit = true recomputes it every frame. |
| `pivot` | vec2 | `[0.5,0.5]` | Which point of the widget sits on the position: [0.5, 0.5] = its centre (default), [0, 1] = top-left corner, [1, 0] = bottom-right. Same meaning as Shape2D.pivot in screen space: +Y is down on screen but pivot [0, 1] is still the visual top-left. Layout does not care about the pivot of its children. |
| `anchor` | vec2 | `[0.0,0.0]` | Screen point the position is relative to, as a fraction of the screen: [0, 0] top-left (default), [1, 0] top-right, [0.5, 0.5] centre. Anchor [0.5, 0.5] with position [0, 0] centres the widget on any aspect ratio. The anchor of the widget itself is used, not its parent's: children of a Panel normally keep anchor [0, 0] and are placed by the Panel's layout. |
| `safeArea` | bool | `false` | Screen space only. true: the anchor names a point of the SAFE area, the screen minus the notch, rounded corners and system bars of a phone (screen.safeArea in scripts), instead of the whole screen: anchor [0, 0] is the top-left corner of the safe area, [1, 1] its bottom-right. Keeps HUD and buttons out of the notch. On a screen without cutouts (desktop, most tablets) it changes nothing. Default false (true on TouchStick and TouchButton). (since 0.2.0) |
| `layer` | int | `200` | Draw order of the background; higher is on top. Defaults to 200, above HUD Text (layer 100). The label draws at layer + 1 and the focus ring at layer + 2. Pointer hit-testing follows the same order: the highest layer, then the latest entity, under the pointer is the hovered widget. |
| `color` | color | `[0.16,0.18,0.24,0.92]` | Background colour, multiplied with `texture` when there is one. Hovered widgets are brightened, pressed ones darkened, non-interactable ones drawn at half alpha. Accepts [r,g,b,a], "#rrggbb" or a name. |
| `texture` | asset (texture) | `""` | Optional background image (project path), drawn as a 9-slice (see `slice`) with nearest-neighbour sampling, so pixel art stays crisp. Empty draws a solid rectangle of `color`. |
| `slice` | vec4 | `[0.0,0.0,0.0,0.0]` | 9-slice borders in TEXTURE pixels [left, top, right, bottom]. The four corners are drawn unscaled (1 texture pixel = 1 design pixel), the edges stretch along one axis and the centre along both, so one small image gives panels of any size. [0, 0, 0, 0] (default) stretches the whole image. When the widget is smaller than left + right (or top + bottom) the borders shrink proportionally. |
| `font` | asset (font) | `""` | Font of the label: project path of a .ttf, empty = the built-in font (same values as Text.font). |
| `key` | string | `""` | Localization key, e.g. "menu.play" (docs/LOCALIZATION.md). Empty (default) = not translated. With a key, the runtime writes the translation into the widget's own text: Button.text, Toggle.label, Slider.label, or TextField.placeholder (never TextField.text, which is what the player typed). It does so when a scene or prefab loads, every frame and when the language changes, so that field is overwritten at run time while `key` is set. A key that no string table has keeps the text written in the field and logs one warning. (since 0.2.0) |
| `keyArgs` | json | `{}` | Values for the {placeholders} of `key`, an object of name -> string or number: {"score": 12} fills "Score: {score}" (and `count` picks the form of a plural entry). Set it once from a script (`entity.set("Text", { keyArgs: { score } })` or `scene.set_component`) instead of rewriting the text every frame: the engine formats the translation with them when the text is localized, when the args change and when the language changes, so a language switch keeps them. Empty (default) = no arguments. Ignored while `key` is empty. (not released yet, on main after 0.2.0) |
| `fontSize` | float | `24.0` | Label glyph height in design pixels. Range 1.0..4096.0. |
| `maxTextScale` | float | `0.0` | > 0: the player's text size (ui.textScale) stops growing this text at this scale, so a heading or a round button label does not outgrow its place: 1.3 means it is drawn at most 1.3 times its fontSize however big the option is. It only limits growth: at a text size below the cap it is drawn at the player's size. 0 (default) = no cap. Measuring (autoSize, layout, ui.measureText, ui.rectOf) and drawing use the same capped size. Range 0.0..3.0. (not released yet, on main after 0.2.0) |
| `textColor` | color | `[1.0,1.0,1.0,1.0]` | Label colour. |
| `accentColor` | color | `[1.0,0.76,0.2,1.0]` | Colour of the focus ring, the slider fill and knob, the toggle check mark and the text caret. |
| `interactable` | bool | `true` | false: the widget is drawn at half alpha and is never hovered, focused or clicked, so it sends no ui events. A focused widget that becomes non-interactable loses focus. |
| `autoFocus` | bool | `false` | Focus rule: nothing takes keyboard / gamepad focus by itself, except that when NOTHING is focused the first widget with autoFocus = true (reading order: top, then left) takes it. Mark the first item of each menu; HUD buttons then stay out of gamepad play (Space / A must never click a HUD button). When the focused widget disappears (inactive, destroyed, not interactable) autoFocus applies again. When every visible autoFocus widget has interactable = false (a greyed-out buy button), the first interactable widget in reading order takes the focus instead, so the gamepad is never left with nothing focused. |
| `focused` | bool | `false` | Runtime: true while the widget has keyboard / gamepad focus. Written by the UI every frame; move focus with ui.focus(entity). Read-only. Runtime-only (not saved). |
| `hovered` | bool | `false` | Runtime: the pointer (mouse or first touch) is over this widget, the top-most visible interactable one. Read-only. Runtime-only (not saved). |
| `pressed` | bool | `false` | Runtime: the pointer is held down on this widget. Read-only. Runtime-only (not saved). |
| `text` | string | `""` | The text, UTF-8. Scripts may write it; no event is sent for a write. |
| `placeholder` | string | `""` | Hint drawn at half alpha while `text` is empty. |
| `maxLength` | int | `64` | Longest text, in characters (code points). 0 = unlimited. Range 0.0..1000000.0. |
| `caret` | bool | `false` | Runtime: the caret is in the visible half of its blink (a 1 second cycle of the UI's own unscaled clock; it restarts visible on every edit). Drawn only while focused. Read-only. Runtime-only (not saved). |

### ScrollList

Since 0.1.6.

Scrolling container: its children are stacked in a column (aligned left, packed at the top) at -scroll, and everything drawn by them and their descendants (widgets, Text, Sprite, Shape2D) is CLIPPED to the list's rectangle. The mouse wheel over the list scrolls it (the innermost list under the pointer), and focusing a widget inside scrolls just enough to show it.

| Field | Type | Default | Description |
|---|---|---|---|
| `size` | vec2 | `[320.0,240.0]` | Size [w, h] in design pixels. The default depends on the kind (Button 240 x 56, Toggle 240 x 40, Slider 320 x 40, TextField 320 x 48, Panel and ScrollList 320 x 240, TouchStick 200 x 200, TouchButton 96 x 96, Captions 960 x 180, Video 640 x 360). A Panel with fit = true recomputes it every frame. |
| `pivot` | vec2 | `[0.5,0.5]` | Which point of the widget sits on the position: [0.5, 0.5] = its centre (default), [0, 1] = top-left corner, [1, 0] = bottom-right. Same meaning as Shape2D.pivot in screen space: +Y is down on screen but pivot [0, 1] is still the visual top-left. Layout does not care about the pivot of its children. |
| `anchor` | vec2 | `[0.0,0.0]` | Screen point the position is relative to, as a fraction of the screen: [0, 0] top-left (default), [1, 0] top-right, [0.5, 0.5] centre. Anchor [0.5, 0.5] with position [0, 0] centres the widget on any aspect ratio. The anchor of the widget itself is used, not its parent's: children of a Panel normally keep anchor [0, 0] and are placed by the Panel's layout. |
| `safeArea` | bool | `false` | Screen space only. true: the anchor names a point of the SAFE area, the screen minus the notch, rounded corners and system bars of a phone (screen.safeArea in scripts), instead of the whole screen: anchor [0, 0] is the top-left corner of the safe area, [1, 1] its bottom-right. Keeps HUD and buttons out of the notch. On a screen without cutouts (desktop, most tablets) it changes nothing. Default false (true on TouchStick and TouchButton). (since 0.2.0) |
| `layer` | int | `200` | Draw order of the background; higher is on top. Defaults to 200, above HUD Text (layer 100). The label draws at layer + 1 and the focus ring at layer + 2. Pointer hit-testing follows the same order: the highest layer, then the latest entity, under the pointer is the hovered widget. |
| `color` | color | `[0.16,0.18,0.24,0.92]` | Background colour, multiplied with `texture` when there is one. Hovered widgets are brightened, pressed ones darkened, non-interactable ones drawn at half alpha. Accepts [r,g,b,a], "#rrggbb" or a name. |
| `texture` | asset (texture) | `""` | Optional background image (project path), drawn as a 9-slice (see `slice`) with nearest-neighbour sampling, so pixel art stays crisp. Empty draws a solid rectangle of `color`. |
| `slice` | vec4 | `[0.0,0.0,0.0,0.0]` | 9-slice borders in TEXTURE pixels [left, top, right, bottom]. The four corners are drawn unscaled (1 texture pixel = 1 design pixel), the edges stretch along one axis and the centre along both, so one small image gives panels of any size. [0, 0, 0, 0] (default) stretches the whole image. When the widget is smaller than left + right (or top + bottom) the borders shrink proportionally. |
| `spacing` | float | `8.0` | Gap in design pixels between children. Range 0.0..10000.0. |
| `padding` | vec4 | `[8.0,8.0,8.0,8.0]` | Space [left, top, right, bottom] between the list's edge and its children. |
| `scroll` | float | `0.0` | Runtime: pixels scrolled from the top. Scripts may write it; it is clamped to [0, content height - inner height] every frame. Runtime-only (not saved). |
| `scrollSpeed` | float | `40.0` | Pixels scrolled per mouse-wheel notch. Range 0.0..10000.0. |
| `fill` | bool | `false` | true: when the parent is a Panel with layout column, `size.y` is set every frame to the height the other children leave. In a Panel with `fit` that is the screen height (minus the safe-area insets) minus the panel's padding, the gaps and the other children, so the panel ends exactly as tall as the screen at most (never below 64 px; if the other children do not leave that, the panel is taller than the screen and warns). In a Panel without fit it is the panel's own inner height minus the others. Several fill lists share the room equally. Ignored when the parent is not a column Panel. `size.x` is yours. (since 0.2.0) |
| `shrink` | bool | `false` | true: like `fill`, but the list is only as tall as its content (padding, children and gaps) when that is less than the room the other children leave, so inside a `fit` Panel a short list makes a short panel and a long one stops at the screen height and scrolls. The room is computed as for `fill` (it needs a parent Panel with layout column; ignored otherwise; never below 64 px). `fill` and `shrink` together: `fill` wins. Several shrink lists share the room: each takes what it needs, and a list that needs more than an equal share takes what the shorter ones leave. `size.x` is yours. (not released yet, on main after 0.2.0) |

### TouchStick

Since 0.2.0.

On-screen analog stick for phones and tablets (docs/MOBILE.md): a disc in `color` with a knob that follows the finger. A finger that lands on it moves a stick of the TOUCH PAD, a virtual gamepad the action bindings read like a real one, so actions bound to GamepadLeftStickLeft/Right/Up/Down (or the right stick) work with no change to the game; the default ui_* actions include the left stick, so it also walks menus. Full tilt is the edge of the disc (half the shorter side); the pad deadzone (input.deadzone) applies like on a real stick. That finger is the stick's until it lifts, even outside the disc: it is not in input.touches, the Touch binding or the mouse. Several fingers work at once (a stick and buttons). Defaults: 200 x 200, inside the safe area, shown only while the player uses touch (touchOnly).

| Field | Type | Default | Description |
|---|---|---|---|
| `size` | vec2 | `[200.0,200.0]` | Size [w, h] in design pixels. The default depends on the kind (Button 240 x 56, Toggle 240 x 40, Slider 320 x 40, TextField 320 x 48, Panel and ScrollList 320 x 240, TouchStick 200 x 200, TouchButton 96 x 96, Captions 960 x 180, Video 640 x 360). A Panel with fit = true recomputes it every frame. |
| `pivot` | vec2 | `[0.5,0.5]` | Which point of the widget sits on the position: [0.5, 0.5] = its centre (default), [0, 1] = top-left corner, [1, 0] = bottom-right. Same meaning as Shape2D.pivot in screen space: +Y is down on screen but pivot [0, 1] is still the visual top-left. Layout does not care about the pivot of its children. |
| `anchor` | vec2 | `[0.0,0.0]` | Screen point the position is relative to, as a fraction of the screen: [0, 0] top-left (default), [1, 0] top-right, [0.5, 0.5] centre. Anchor [0.5, 0.5] with position [0, 0] centres the widget on any aspect ratio. The anchor of the widget itself is used, not its parent's: children of a Panel normally keep anchor [0, 0] and are placed by the Panel's layout. |
| `safeArea` | bool | `true` | Screen space only. true: the anchor names a point of the SAFE area, the screen minus the notch, rounded corners and system bars of a phone (screen.safeArea in scripts), instead of the whole screen: anchor [0, 0] is the top-left corner of the safe area, [1, 1] its bottom-right. Keeps HUD and buttons out of the notch. On a screen without cutouts (desktop, most tablets) it changes nothing. Default false (true on TouchStick and TouchButton). |
| `layer` | int | `200` | Draw order of the background; higher is on top. Defaults to 200, above HUD Text (layer 100). The label draws at layer + 1 and the focus ring at layer + 2. Pointer hit-testing follows the same order: the highest layer, then the latest entity, under the pointer is the hovered widget. |
| `color` | color | `[1.0,1.0,1.0,0.2]` | Background colour, multiplied with `texture` when there is one. Hovered widgets are brightened, pressed ones darkened, non-interactable ones drawn at half alpha. Accepts [r,g,b,a], "#rrggbb" or a name. |
| `texture` | asset (texture) | `""` | Optional background image (project path), drawn as a 9-slice (see `slice`) with nearest-neighbour sampling, so pixel art stays crisp. Empty draws a solid rectangle of `color`. |
| `slice` | vec4 | `[0.0,0.0,0.0,0.0]` | 9-slice borders in TEXTURE pixels [left, top, right, bottom]. The four corners are drawn unscaled (1 texture pixel = 1 design pixel), the edges stretch along one axis and the centre along both, so one small image gives panels of any size. [0, 0, 0, 0] (default) stretches the whole image. When the widget is smaller than left + right (or top + bottom) the borders shrink proportionally. |
| `stick` | enum: left \\| right | `"left"` | Which stick of the touch pad it moves. |
| `knobColor` | color | `[1.0,1.0,1.0,0.6]` | Colour of the knob, a disc 45% as wide as the stick. |
| `touchOnly` | bool | `true` | true (default): drawn and listed as visible only while the last input came from a finger (input.lastDevice "touch"; a phone or tablet starts that way), so it hides when the player picks up a gamepad or a keyboard and comes back on the next touch. A finger landing on it always works. false: always drawn (desktop previews, screenshots, tests). |
| `value` | vec2 | `[0.0,0.0]` | Runtime: the finger's offset from the centre over the radius [x, y], length <= 1, +Y up; [0, 0] when no finger holds it. Before the deadzone; read actions (input.vector) for the value the game should use. Read-only. Runtime-only (not saved). |
| `pressed` | bool | `false` | Runtime: a finger holds the stick. Read-only. Runtime-only (not saved). |
| `shown` | bool | `false` | Runtime: drawn this frame (see touchOnly). Read-only. Runtime-only (not saved). |

### TouchButton

Since 0.2.0.

On-screen button for phones and tablets (docs/MOBILE.md): a disc in `color` (darker while held) with an optional label. While a finger holds it, `button` of the TOUCH PAD is down, a virtual gamepad the action bindings read like a real one: a TouchButton with button "A" fires every action bound to GamepadA, with no change to the game. The finger is the button's until it lifts, even if it slides off, and it is not in input.touches, the Touch binding or the mouse. Several fingers work at once. Defaults: 96 x 96, inside the safe area, shown only while the player uses touch (touchOnly). It is not focusable and sends no ui events.

| Field | Type | Default | Description |
|---|---|---|---|
| `size` | vec2 | `[96.0,96.0]` | Size [w, h] in design pixels. The default depends on the kind (Button 240 x 56, Toggle 240 x 40, Slider 320 x 40, TextField 320 x 48, Panel and ScrollList 320 x 240, TouchStick 200 x 200, TouchButton 96 x 96, Captions 960 x 180, Video 640 x 360). A Panel with fit = true recomputes it every frame. |
| `pivot` | vec2 | `[0.5,0.5]` | Which point of the widget sits on the position: [0.5, 0.5] = its centre (default), [0, 1] = top-left corner, [1, 0] = bottom-right. Same meaning as Shape2D.pivot in screen space: +Y is down on screen but pivot [0, 1] is still the visual top-left. Layout does not care about the pivot of its children. |
| `anchor` | vec2 | `[0.0,0.0]` | Screen point the position is relative to, as a fraction of the screen: [0, 0] top-left (default), [1, 0] top-right, [0.5, 0.5] centre. Anchor [0.5, 0.5] with position [0, 0] centres the widget on any aspect ratio. The anchor of the widget itself is used, not its parent's: children of a Panel normally keep anchor [0, 0] and are placed by the Panel's layout. |
| `safeArea` | bool | `true` | Screen space only. true: the anchor names a point of the SAFE area, the screen minus the notch, rounded corners and system bars of a phone (screen.safeArea in scripts), instead of the whole screen: anchor [0, 0] is the top-left corner of the safe area, [1, 1] its bottom-right. Keeps HUD and buttons out of the notch. On a screen without cutouts (desktop, most tablets) it changes nothing. Default false (true on TouchStick and TouchButton). |
| `layer` | int | `200` | Draw order of the background; higher is on top. Defaults to 200, above HUD Text (layer 100). The label draws at layer + 1 and the focus ring at layer + 2. Pointer hit-testing follows the same order: the highest layer, then the latest entity, under the pointer is the hovered widget. |
| `color` | color | `[1.0,1.0,1.0,0.2]` | Background colour, multiplied with `texture` when there is one. Hovered widgets are brightened, pressed ones darkened, non-interactable ones drawn at half alpha. Accepts [r,g,b,a], "#rrggbb" or a name. |
| `texture` | asset (texture) | `""` | Optional background image (project path), drawn as a 9-slice (see `slice`) with nearest-neighbour sampling, so pixel art stays crisp. Empty draws a solid rectangle of `color`. |
| `slice` | vec4 | `[0.0,0.0,0.0,0.0]` | 9-slice borders in TEXTURE pixels [left, top, right, bottom]. The four corners are drawn unscaled (1 texture pixel = 1 design pixel), the edges stretch along one axis and the centre along both, so one small image gives panels of any size. [0, 0, 0, 0] (default) stretches the whole image. When the widget is smaller than left + right (or top + bottom) the borders shrink proportionally. |
| `button` | enum: A \\| B \\| X \\| Y \\| Start \\| Back \\| Guide \\| DpadLeft \\| DpadRight \\| DpadUp \\| DpadDown \\| LeftShoulder \\| RightShoulder \\| LeftThumb \\| RightThumb | `"A"` | The pad button it holds down: actions bound to "Gamepad" + this name (GamepadA, GamepadDpadUp...) fire. Bind the game's actions to pad buttons in factoria.json input.actions to use them. |
| `text` | string | `""` | Label centred on the button, e.g. "A" or "Jump". Empty (default) draws none. |
| `key` | string | `""` | Localization key, e.g. "touch.jump" (docs/LOCALIZATION.md). Empty (default) = not translated. With a key, the runtime writes the translation into `text` when a scene loads, every frame and when the language changes. A key that no string table has keeps `text` and logs one warning. (not released yet, on main after 0.2.0) |
| `keyArgs` | json | `{}` | Values for the {placeholders} of `key`, an object of name -> string or number: {"score": 12} fills "Score: {score}" (and `count` picks the form of a plural entry). Set it once from a script (`entity.set("Text", { keyArgs: { score } })` or `scene.set_component`) instead of rewriting the text every frame: the engine formats the translation with them when the text is localized, when the args change and when the language changes, so a language switch keeps them. Empty (default) = no arguments. Ignored while `key` is empty. (not released yet, on main after 0.2.0) |
| `font` | asset (font) | `""` | Font of the label: project path of a .ttf, empty = the built-in font. |
| `fontSize` | float | `32.0` | Label glyph height in design pixels. Range 1.0..4096.0. |
| `autoShrink` | bool | `false` | true: when the text does not fit its box at the current text size (ui.textScale) and language, the font is made smaller until it does, never under `minFontSize` (so a German label in a fixed button stays inside at 200 % text, and a long translation is smaller instead of cut). It is decided every frame from the laid-out size, with no script. If it still does not fit at minFontSize it is drawn there and ui.overflowed(id) is true. false (default): the size is never reduced. (not released yet, on main after 0.2.0) |
| `minFontSize` | float | `10.0` | autoShrink floor in design pixels, before ui.textScale (the floor is minFontSize times the player's text size, capped by maxTextScale, so the accessibility setting keeps working). Never above fontSize. Range 1.0..4096.0. (not released yet, on main after 0.2.0) |
| `maxTextScale` | float | `0.0` | > 0: the player's text size (ui.textScale) stops growing this text at this scale, so a heading or a round button label does not outgrow its place: 1.3 means it is drawn at most 1.3 times its fontSize however big the option is. It only limits growth: at a text size below the cap it is drawn at the player's size. 0 (default) = no cap. Measuring (autoSize, layout, ui.measureText, ui.rectOf) and drawing use the same capped size. Range 0.0..3.0. (not released yet, on main after 0.2.0) |
| `textColor` | color | `[1.0,1.0,1.0,0.9]` | Label colour. |
| `touchOnly` | bool | `true` | true (default): drawn and listed as visible only while the last input came from a finger (input.lastDevice "touch"; a phone or tablet starts that way), so it hides when the player picks up a gamepad or a keyboard and comes back on the next touch. A finger landing on it always works. false: always drawn (desktop previews, screenshots, tests). |
| `pressed` | bool | `false` | Runtime: a finger holds the button. Read-only. Runtime-only (not saved). |
| `shown` | bool | `false` | Runtime: drawn this frame (see touchOnly). Read-only. Runtime-only (not saved). |

### Captions

Since 0.2.0.

The subtitles of the game (docs/TEXT.md, "Captions"): draws the lines that `audio.play(path, { caption })` and `ui.caption(text, seconds)` put on the caption list, the newest `maxLines` of them, at the bottom of this entity's rectangle on a background that hugs the text. Text is drawn like Text: it follows ui.textScale, the localization font chain and right-to-left languages. Put ONE per scene (or in a persistent HUD). Without any Captions entity captions are still tracked (game.captions() in tests lists them) but nothing is drawn, and the log says so once. An inactive Captions entity draws nothing either: that is how a "Subtitles" option turns them off. Defaults: bottom centre of the safe area, 960 x 180, over a dark background.

| Field | Type | Default | Description |
|---|---|---|---|
| `size` | vec2 | `[960.0,180.0]` | Size [w, h] in design pixels. The default depends on the kind (Button 240 x 56, Toggle 240 x 40, Slider 320 x 40, TextField 320 x 48, Panel and ScrollList 320 x 240, TouchStick 200 x 200, TouchButton 96 x 96, Captions 960 x 180, Video 640 x 360). A Panel with fit = true recomputes it every frame. |
| `pivot` | vec2 | `[0.5,0.0]` | Which point of the widget sits on the position: [0.5, 0.5] = its centre (default), [0, 1] = top-left corner, [1, 0] = bottom-right. Same meaning as Shape2D.pivot in screen space: +Y is down on screen but pivot [0, 1] is still the visual top-left. Layout does not care about the pivot of its children. |
| `anchor` | vec2 | `[0.5,1.0]` | Screen point the position is relative to, as a fraction of the screen: [0, 0] top-left (default), [1, 0] top-right, [0.5, 0.5] centre. Anchor [0.5, 0.5] with position [0, 0] centres the widget on any aspect ratio. The anchor of the widget itself is used, not its parent's: children of a Panel normally keep anchor [0, 0] and are placed by the Panel's layout. |
| `safeArea` | bool | `true` | Screen space only. true: the anchor names a point of the SAFE area, the screen minus the notch, rounded corners and system bars of a phone (screen.safeArea in scripts), instead of the whole screen: anchor [0, 0] is the top-left corner of the safe area, [1, 1] its bottom-right. Keeps HUD and buttons out of the notch. On a screen without cutouts (desktop, most tablets) it changes nothing. Default false (true on TouchStick and TouchButton). |
| `layer` | int | `200` | Draw order of the background; higher is on top. Defaults to 200, above HUD Text (layer 100). The label draws at layer + 1 and the focus ring at layer + 2. Pointer hit-testing follows the same order: the highest layer, then the latest entity, under the pointer is the hovered widget. |
| `color` | color | `[0.0,0.0,0.0,0.7]` | Background colour, multiplied with `texture` when there is one. Hovered widgets are brightened, pressed ones darkened, non-interactable ones drawn at half alpha. Accepts [r,g,b,a], "#rrggbb" or a name. |
| `texture` | asset (texture) | `""` | Optional background image (project path), drawn as a 9-slice (see `slice`) with nearest-neighbour sampling, so pixel art stays crisp. Empty draws a solid rectangle of `color`. |
| `slice` | vec4 | `[0.0,0.0,0.0,0.0]` | 9-slice borders in TEXTURE pixels [left, top, right, bottom]. The four corners are drawn unscaled (1 texture pixel = 1 design pixel), the edges stretch along one axis and the centre along both, so one small image gives panels of any size. [0, 0, 0, 0] (default) stretches the whole image. When the widget is smaller than left + right (or top + bottom) the borders shrink proportionally. |
| `maxLines` | int | `3` | How many captions show at once. When more are on the list the oldest are not drawn (they stay on the list until their sound ends or their seconds run out). Range 1.0..16.0. |
| `padding` | vec4 | `[16.0,8.0,16.0,8.0]` | Space [left, top, right, bottom] between the edge of the background and the text. |
| `font` | asset (font) | `""` | Font of the captions: project path of a .ttf, empty = the built-in font (same values as Text.font). |
| `fontSize` | float | `28.0` | Glyph height in design pixels, before ui.textScale. Range 1.0..4096.0. |
| `textColor` | color | `[1.0,1.0,1.0,1.0]` | Colour of the caption text. |
| `speakerColor` | color | `[1.0,0.82,0.35,1.0]` | Colour of the speaker's name, drawn before the line ("Mara:"). Captions without a speaker have no name. |
| `align` | enum: left \\| center \\| right \\| start \\| end | `"center"` | Where the block of captions sits inside the rectangle's width, and how the lines align in it. Same values as Text.align: start / end follow the language (start = right in Arabic or Hebrew). |
| `spacing` | float | `4.0` | Gap in design pixels between two captions. Range 0.0..1000.0. |
| `lines` | json | `[]` | Runtime: what is drawn now, [{text, speaker}] oldest first, at most `maxLines`. Written by the engine every frame from the caption list; do not edit it. Read-only. Runtime-only (not saved). |

### Video

Not released yet (on main after 0.2.0).

A video on the screen (docs/MENUS.md, "Studio intro"): plays an .mpg file (MPEG-1 video with MP2 sound, the same decoder on every platform) in this entity's rectangle, the way an image fills a widget. Convert any other video with `factoria call assets.import '{"source":"intro.mp4"}'` (needs ffmpeg: `factoria setup ffmpeg`). The sound plays on the mixer bus `bus` at `volume`. Time follows the game clock: the video pauses with the game (time.scale 0) and a headless run shows the same pictures at the same times as a windowed one. Control it from a script with `entity.video.play()`, `pause()`, `stop()`, `seek(seconds)` and read `time`, `duration`, `playing`; when it reaches its end the game event `video.ended` ({id, path}) fires once (`entity.video.on("ended", fn)`). The picture is decoded on the CPU: keep videos at most about 1280 x 720. Defaults: 640 x 360, a black background (shown as bars where the picture does not fill the rectangle), starts playing at once.

| Field | Type | Default | Description |
|---|---|---|---|
| `size` | vec2 | `[640.0,360.0]` | Size [w, h] in design pixels. The default depends on the kind (Button 240 x 56, Toggle 240 x 40, Slider 320 x 40, TextField 320 x 48, Panel and ScrollList 320 x 240, TouchStick 200 x 200, TouchButton 96 x 96, Captions 960 x 180, Video 640 x 360). A Panel with fit = true recomputes it every frame. |
| `pivot` | vec2 | `[0.5,0.5]` | Which point of the widget sits on the position: [0.5, 0.5] = its centre (default), [0, 1] = top-left corner, [1, 0] = bottom-right. Same meaning as Shape2D.pivot in screen space: +Y is down on screen but pivot [0, 1] is still the visual top-left. Layout does not care about the pivot of its children. |
| `anchor` | vec2 | `[0.0,0.0]` | Screen point the position is relative to, as a fraction of the screen: [0, 0] top-left (default), [1, 0] top-right, [0.5, 0.5] centre. Anchor [0.5, 0.5] with position [0, 0] centres the widget on any aspect ratio. The anchor of the widget itself is used, not its parent's: children of a Panel normally keep anchor [0, 0] and are placed by the Panel's layout. |
| `safeArea` | bool | `false` | Screen space only. true: the anchor names a point of the SAFE area, the screen minus the notch, rounded corners and system bars of a phone (screen.safeArea in scripts), instead of the whole screen: anchor [0, 0] is the top-left corner of the safe area, [1, 1] its bottom-right. Keeps HUD and buttons out of the notch. On a screen without cutouts (desktop, most tablets) it changes nothing. Default false (true on TouchStick and TouchButton). |
| `layer` | int | `200` | Draw order of the background; higher is on top. Defaults to 200, above HUD Text (layer 100). The label draws at layer + 1 and the focus ring at layer + 2. Pointer hit-testing follows the same order: the highest layer, then the latest entity, under the pointer is the hovered widget. |
| `color` | color | `[0.0,0.0,0.0,1.0]` | Background colour, multiplied with `texture` when there is one. Hovered widgets are brightened, pressed ones darkened, non-interactable ones drawn at half alpha. Accepts [r,g,b,a], "#rrggbb" or a name. |
| `texture` | asset (texture) | `""` | Optional background image (project path), drawn as a 9-slice (see `slice`) with nearest-neighbour sampling, so pixel art stays crisp. Empty draws a solid rectangle of `color`. |
| `slice` | vec4 | `[0.0,0.0,0.0,0.0]` | 9-slice borders in TEXTURE pixels [left, top, right, bottom]. The four corners are drawn unscaled (1 texture pixel = 1 design pixel), the edges stretch along one axis and the centre along both, so one small image gives panels of any size. [0, 0, 0, 0] (default) stretches the whole image. When the widget is smaller than left + right (or top + bottom) the borders shrink proportionally. |
| `path` | asset (video) | `""` | Project path of the video (.mpg). Changing it opens the new file (and starts it again when `autoplay`). A file that is missing or is not MPEG-1 video is logged once and the entity draws only its background. |
| `autoplay` | bool | `true` | true (default): `playing` becomes true as soon as the file is open. false: it waits for `entity.video.play()` or `playing = true`, showing the first picture. |
| `loop` | bool | `false` | true: at the end the video starts over from the beginning, picture and sound (no `video.ended` event). false: it stops on its last picture and fires `video.ended`. |
| `volume` | float | `1.0` | Loudness of the sound, 0 (silent) to 1 (full), before the bus volume. Range 0.0..1.0. |
| `bus` | string | `"sfx"` | Mixer bus of the sound: "sfx" (default), "music" or "ui". The bus volumes of a Settings menu apply to it like to any other sound. Any other name plays on sfx. |
| `fit` | enum: contain \\| cover \\| stretch | `"contain"` | How the picture fills the rectangle: contain (default) shows all of it, with bars of `color` where the shapes differ; cover fills the rectangle and cuts off what overflows; stretch fills it and distorts the picture. |
| `tint` | color | `[1.0,1.0,1.0,1.0]` | Colour multiplied with the picture: white (default) leaves it as it is, alpha below 1 fades the video over what is behind it. `color` (the background) is a separate colour. |
| `playing` | bool | `false` | Runtime: true while the video advances. Set true to play (from the start when it had ended), false to pause. Becomes false when the video ends. Runtime-only (not saved). |
| `ended` | bool | `false` | Runtime: true once the video reached its end (never while `loop`); false again after a seek or a restart. Read-only. Runtime-only (not saved). |
| `time` | float | `0.0` | Runtime: seconds into the video, 0 .. duration. Assign to seek (the picture and the sound jump there). Range 0.0..1000000.0. Runtime-only (not saved). |
| `duration` | float | `0.0` | Runtime: length of the video in seconds; 0 while the file is not open. Read-only. Runtime-only (not saved). |

## Scripting

### Script

Attaches JavaScript behaviour to the entity. `path` is an ES module whose default export is a class extending Behaviour (see docs/SCRIPTING.md).

| Field | Type | Default | Description |
|---|---|---|---|
| `path` | asset (script) | `""` | Project-relative path of the script, e.g. "scripts/player.js". |
| `props` | json | `{}` | JSON object of tunable values assigned onto the behaviour instance (this.speed = props.speed) before onStart. Lets one script serve many entities with different settings. |
| `enabled` | bool | `true` | false = the script receives no callbacks. |

## Scene

### SceneSettings

Scene-wide settings stored under "settings" in the scene file: lighting, fog, gravity and background music.

| Field | Type | Default | Description |
|---|---|---|---|
| `ambientLight` | color | `[0.25,0.25,0.3,1.0]` | Base light added to all lit 3D surfaces so shadows are not pitch black. It is also the base light of lit 2D visuals (Sprite.lit, Tilemap.lit): a lit sprite shows its texture multiplied by this colour plus the Light2D lights. Raise it to [1, 1, 1] and the lit sprites look unlit. |
| `gravity2D` | vec2 | `[0.0,-980.0]` | 2D gravity [x, y] in world units/s^2 (default 980 pixels/s^2 downwards). |
| `gravity3D` | vec3 | `[0.0,-9.81,0.0]` | 3D gravity [x, y, z] in m/s^2 (default 9.81 downwards). |
| `fogColor` | color | `[0.5,0.6,0.7,1.0]` | Color distant 3D objects fade to. |
| `fogDensity` | float | `0.0` | Fog thickness; 0 disables fog. Range 0.0..10.0. |
| `skyColor` | color | `[0.45,0.62,0.85,1.0]` | Top color of the 3D background gradient (used when a perspective camera clears). |
| `horizonColor` | color | `[0.8,0.85,0.9,1.0]` | Bottom color of the 3D background gradient. |
| `music` | asset (audio) | `""` | Looping background music asset path. Empty = none. |
| `musicVolume` | float | `0.6` | Volume of the background music, 0..1. Range 0.0..1.0. |


# Commands reference

Every command is a CLI call (`factoria call <name> '<json>'`), an MCP tool (dots become underscores) and a script function (`fa.call(name, args)`).

## ai

### `ai.models`

List the models each AI provider offers (the values for roles.<role>.model).

Asks the providers themselves, so newly released models show up: Claude Code through its CLI (aliases such as opus first, then full names; no model call, no usage), the Anthropic API and OpenAI-compatible APIs through GET /models. Codex and generic CLIs cannot list their models: their entry has an error. Without `provider` it lists every provider that ai.providers reports available; one provider's failure is in its own entry (error, hint) and does not fail the call. Returns {providers:[{name, models:[{id, name, description, resolved}], error?, hint?}]}: id is the value for roles.<role>.model, name the display name (empty when the provider gives none), description one line, resolved the model an alias stands for (empty for a full name). Example: {"provider":"claude-code"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `provider` | string | no | Only this provider (a name from ai.providers). Omit for every available one. |

### `ai.providers`

List configured AI providers and roles, or diagnose which ones are usable (doctor).

action "list" (default) shows providers and the role mapping from ~/.factoria/ai.json. action "doctor" also checks for CLIs (claude, codex, ant) and API keys (never printed). `assets` maps each kind of asset (image, sound, music, voice, model3d) to the provider that generates it (assets.generate_* commands). Example: {"action":"doctor"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `action` | string ["list","doctor"] | no | list or doctor. Default "list". |

### `ai.run` (modifies state)

Run an AI agent on a task in the current project (blocks until it finishes).

Uses the provider/model mapped to `role` in ~/.factoria/ai.json (default orchestrator). CLI providers (claude-code, codex) run their own loop with the FactorIA MCP server attached; API providers run the built-in tool loop. An orchestrator that is itself a CLI agent delegates with this tool: role "worker" or "fast" and a self-contained task; the result's finalText is the sub-agent's report. Example: {"task":"Add a pause menu","role":"orchestrator","maxCostUsd":2}

| Argument | Type | Required | Description |
|---|---|---|---|
| `task` | string | yes | What the agent should do. |
| `role` | string ["orchestrator","worker","fast"] | no |  Default "orchestrator". |
| `provider` | string | no | Override the role's provider (e.g. claude-code, codex, openrouter). |
| `model` | string | no | Override the role's model. |
| `maxTurns` | integer | no |  |
| `maxCostUsd` | number | no |  |
| `stream` | boolean | no |  Default true. |

## api

### `api.commands`

Describe every registered command (name, summary, schema).

Example: api.commands {}

### `api.components`

Describe every component type: fields, kinds, defaults, docs.

Read this before writing scene JSON. Example: api.components {}

### `api.scripting`

Machine-readable JavaScript API (modules, classes, functions) for gameplay scripts.

Example: api.scripting {}

## assets

### `assets.analyze_audio` (modifies state)

Since 0.1.6.

Measure the loudness of a sound (or of every sound) and keep the result in assets.json.

Measures integrated loudness (LUFS, ITU-R BS.1770-4 / EBU R128) and sample peak (dBFS) of .wav, .ogg, .mp3 and .qoa files, and stores them under the sound's `analysis` in assets.json together with the size and SHA-256 of the file, so editing the sound later makes the record stale instead of wrong. Sounds with import "normalize": true play at `targetLufs` using that record; without one the desktop engine measures the sound when it loads it, and mobile builds cannot, so run this (or export, which stores it) before shipping. A sound whose record is still fresh is not measured again. Without `path` every sound under assets/ and every sound a scene or prefab names is analyzed. Returns {files: [{path, loudnessLufs, peakDb, seconds, streams, normalize, gainDb, cached, stored}], measured, cached, failed}: `streams` says whether the sound is decoded while it plays (import stream), `gainDb` is the gain normalize would apply (only when normalize is on). A sound that cannot be decoded is listed with `error` and `hint` when no path is given. Example: {"path": "assets/music/theme.ogg"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | no | Project-relative sound file, e.g. assets/sfx/jump.wav. Omit to analyze every sound of the project. |

### `assets.disclosure`

Since 0.1.6.

Write the AI-generated content disclosure for store forms (Steam) from the provenance records.

Returns Markdown that answers the AI-generated content questions of Steam's content survey and similar forms: what was pre-generated with AI by category (art, sound effects, music, voice, 3D models) with counts, providers and models; that nothing is generated while the game runs; the terms recorded for each provider; and the art, sound and model files that still have no provenance record (fix those with assets.set_provenance first). `factoria export` writes the same text as AI_CONTENT_DISCLOSURE.md. Example: {}

### `assets.draw_capsules` (modifies state)

Since 0.2.0.

Make the store page images (capsules, heroes, covers, screenshots) at each store's sizes from one piece of key art and a logo.

Cover-crops `keyArt` (an image in the project, e.g. a screenshot taken with game.screenshot {scale}) around `focus` to every image size the `stores` ask for and writes store/capsules/<store>/<name>_<w>x<h>.png (folders are created, files replaced). Stores: steam, epic, gog, microsoft, googleplay, appstore, itch (default: all). The sizes are in one table (docs/EXPORTING.md#store-page-material, as of 2026-10); assets with the same size in one store are one file.
The `logo` is placed by the rule of each asset: capsules and covers get it centred (Microsoft: in the upper part, the bottom third is overlaid; Steam library capsule: low), heroes, page backgrounds and screenshots get none (Steam's library hero must have no text), and the logo-only assets (Steam library logo 1280x720, Epic logo 960x540) are a transparent PNG with just the logo. `logo` is {"image": "assets/logo.png"} (transparent PNG) or {"text": "My Game", font, fill, outline} (title drawn like assets.draw_icon draws text; fill default white, outline default a dark one, false = none). Without a logo the art is cut without one and the logo-only assets are skipped.
`orientation` (landscape, default; or portrait) turns the phone and tablet screenshot sizes of Google Play and the App Store. Capsules are not the store screenshots: take those at the stores' sizes with `--render-scale` (a 1280x720 game at 1.5 gives 1920x1080).
Example: {"keyArt":"store/keyart.png","focus":[0.5,0.4],"logo":{"text":"Lantern Keep"},"stores":["steam"]}.

| Argument | Type | Required | Description |
|---|---|---|---|
| `keyArt` | string | yes | The art to cut the capsules from: a project image path, 1920x1080 or bigger is best (a screenshot taken with --render-scale). |
| `focus` | array | no | The point of the art that must stay in view when it is cropped, as fractions [x, y]. Default [0.5, 0.5]. |
| `logo` | object | no | The logo: give image or text. |
| `stores` | array | no | Which stores. Default all. |
| `name` | string | no | File name prefix. Default: the project name. |
| `orientation` | string ["landscape","portrait"] | no | Phone and tablet screenshot sizes of Google Play and the App Store. Default landscape. |
| `overwrite` | boolean | no | Replace files that already exist. Default true. |

### `assets.draw_icon` (modifies state)

Since 0.2.0.

Draw the game's icon (1024x1024 PNG) and the Android adaptive-icon foreground from shapes and text, no image provider needed.

Draws on the CPU (anti-aliased, identical everywhere, works headless): a background plus layers drawn in order. Writes the 1024x1024 icon at `path` (default: factoria.json `icon`, else assets/icon.png) and the Android adaptive-icon foreground (432x432, transparent; the 0..100 drawing box is scaled into the 66/108 safe zone, so nothing inside it is cropped) at `foreground` (default: export.android.adaptiveIcon.foreground, else assets/icon_fg.png; false = skip). An icon or foreground path factoria.json does not name yet is added to it. Files are replaced; assets.json gets provenance origin "original", ai false.
Drawing space: x and y run 0..100 across the icon, origin top-left, y down; sizes and radii are in the same units (shapes may reach outside 0..100: the icon crops them). Layer types: rect {x,y,w,h} (x,y = top-left), roundRect {x,y,w,h,radius}, circle {x,y,radius} (x,y = centre), ellipse {x,y,rx,ry}, polygon {points:[[x,y],...]} and text {text,x,y,size,font}: x,y = centre of the text, size = em height, font = a project .ttf (default DejaVu Sans), one line, no shaping. Shapes take fill and/or outline (colours "#rrggbb"[aa] or names), fillBottom (vertical gradient from fill at the top of the icon to fillBottom at its bottom), outlineWidth (default 2), softness (feathers the edge: glows). Text takes fill. foreground: false on a layer keeps it out of the Android foreground (backdrops such as a ground or arch; the adaptive icon has its own background colour). Unknown keys and types are errors with suggestions.
Example: {"background":{"color":"#141428","shape":"rounded"},"layers":[{"type":"circle","x":50,"y":50,"radius":28,"fill":"#ffcc44","outline":"#ffffff"},{"type":"text","text":"K","x":50,"y":50,"size":34,"fill":"#141428"}]}.

| Argument | Type | Required | Description |
|---|---|---|---|
| `background` | object | yes | The icon's backdrop. |
| `layers` | array | yes | Drawn in order, later on top. Each has a `type` (rect, roundRect, circle, ellipse, polygon, text) and the fields listed in the command description. |
| `path` | string | no | PNG to write the icon to. Default: factoria.json `icon`, else assets/icon.png. |
| `foreground` | any | no | PNG for the Android adaptive-icon foreground, or false to skip it. Default: export.android.adaptiveIcon.foreground, else assets/icon_fg.png. |

### `assets.generate_image` (modifies state)

Since 0.1.6.

Generate a PNG image with the image asset provider and record where it came from.

Calls the provider that ai.json assigns to "image" (assets.image; there is no default, so add one, or pass `provider` such as "fake" for an offline placeholder), writes a PNG of exactly width x height at `path` and records provenance (origin generated, ai true, provider, model, the full prompt, references, date, license note) in assets.json. The house style of assets.json is applied unless style is false: its `prompt` is appended to yours, its `references` are sent along with `references`, and its `palette` reduces the result to those colours. Returns the path, size, provenance and the image itself. Generation costs money with paid providers: check the first result before generating more. Example: {"prompt":"a red potion bottle, side view","path":"assets/items/potion.png","width":64,"height":64,"transparent":true}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | Where to write the file, project-relative, under assets/ (for example "assets/sfx/jump.wav"). The extension must match what the provider makes. |
| `prompt` | string | yes | What to draw. Describe the subject and the view; the house style is added for you. |
| `width` | integer | no | Width of the PNG in pixels. The provider's picture is resized to it. Default 512. |
| `height` | integer | no | Height of the PNG in pixels. Default 512. |
| `transparent` | boolean | no | Ask for a transparent background (sprites, items, icons). Default false. |
| `references` | array | no | Project-relative images the result should follow (a character to keep consistent, a style). Sent to providers that accept reference images, in addition to style.references of assets.json. |
| `style` | boolean | no | Apply the house style of assets.json (style.prompt, style.references, style.palette). false skips all of it for this call. Default true. |
| `provider` | string | no | Asset provider to use instead of the one ai.json assigns to this kind of asset (a name from ai.providers, for example "fake" to try the flow offline). |
| `model` | string | no | Model to use instead of the one in ai.json. Empty: the provider's default. |
| `seed` | integer | no | Seed, for providers that take one (fake, asset-command with {seed}). Others ignore it with a warning. |
| `overwrite` | boolean | no | Replace the file when it already exists. The old file is not kept. Default false. |
| `author` | string | no | Who gets the credit in the provenance record. Default: "factoria". |

### `assets.generate_model` (modifies state)

Since 0.1.6.

Generate a 3D model with the model3d asset provider and record where it came from.

Calls the provider that ai.json assigns to "model3d" (assets.model3d) and writes the glTF binary at `path` (.glb; the fake provider makes a small .gltf cube). Generating models takes minutes with real providers. The model is not textured or rigged; check it in the scene before building on it. Records provenance in assets.json. Example: {"prompt":"a low-poly wooden crate","path":"assets/models/crate.glb"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | Where to write the file, project-relative, under assets/ (for example "assets/sfx/jump.wav"). The extension must match what the provider makes. |
| `prompt` | string | yes | The object to make: shape, material, style. |
| `provider` | string | no | Asset provider to use instead of the one ai.json assigns to this kind of asset (a name from ai.providers, for example "fake" to try the flow offline). |
| `model` | string | no | Model to use instead of the one in ai.json. Empty: the provider's default. |
| `seed` | integer | no | Seed, for providers that take one (fake, asset-command with {seed}). Others ignore it with a warning. |
| `overwrite` | boolean | no | Replace the file when it already exists. The old file is not kept. Default false. |
| `author` | string | no | Who gets the credit in the provenance record. Default: "factoria". |

### `assets.generate_music` (modifies state)

Since 0.1.6.

Generate a music track with the music asset provider and record where it came from.

Calls the provider that ai.json assigns to "music" (assets.music) and writes the audio file at `path` (extension as for assets.generate_sound). Tracks are instrumental. Records provenance in assets.json. Tracks are not looped for you: ask for a loopable piece in the prompt and set `loop` on the AudioSource. Example: {"prompt":"calm forest theme, soft flute and strings","path":"assets/music/forest.mp3","seconds":60}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | Where to write the file, project-relative, under assets/ (for example "assets/sfx/jump.wav"). The extension must match what the provider makes. |
| `prompt` | string | yes | The music to make: mood, instruments, tempo. |
| `seconds` | number | no | Length in seconds. Default: the provider chooses. |
| `provider` | string | no | Asset provider to use instead of the one ai.json assigns to this kind of asset (a name from ai.providers, for example "fake" to try the flow offline). |
| `model` | string | no | Model to use instead of the one in ai.json. Empty: the provider's default. |
| `seed` | integer | no | Seed, for providers that take one (fake, asset-command with {seed}). Others ignore it with a warning. |
| `overwrite` | boolean | no | Replace the file when it already exists. The old file is not kept. Default false. |
| `author` | string | no | Who gets the credit in the provenance record. Default: "factoria". |

### `assets.generate_sound` (modifies state)

Since 0.1.6.

Generate a sound effect with the sound asset provider and record where it came from.

Calls the provider that ai.json assigns to "sound" (assets.sound) and writes the audio file at `path`, whose extension must be the one the provider makes (.mp3 for elevenlabs, .wav for fake and asset-command). Records provenance in assets.json. Example: {"prompt":"short coin pickup chime","path":"assets/sfx/coin.mp3","seconds":1}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | Where to write the file, project-relative, under assets/ (for example "assets/sfx/jump.wav"). The extension must match what the provider makes. |
| `prompt` | string | yes | The sound to make, for example "heavy wooden door slam". |
| `seconds` | number | no | Length in seconds. Default: the provider chooses. |
| `provider` | string | no | Asset provider to use instead of the one ai.json assigns to this kind of asset (a name from ai.providers, for example "fake" to try the flow offline). |
| `model` | string | no | Model to use instead of the one in ai.json. Empty: the provider's default. |
| `seed` | integer | no | Seed, for providers that take one (fake, asset-command with {seed}). Others ignore it with a warning. |
| `overwrite` | boolean | no | Replace the file when it already exists. The old file is not kept. Default false. |
| `author` | string | no | Who gets the credit in the provenance record. Default: "factoria". |

### `assets.generate_sprite_sheet` (modifies state)

Since 0.1.6.

Generate a sprite sheet (a grid of animation frames) and record its layout for SpriteAnimator.

Like assets.generate_image, but the picture is a grid of `frames` animation frames of frameWidth x frameHeight, normalized to exactly columns * frameWidth by rows * frameHeight pixels (each side at most 4096). The layout is written to assets.json as the `sheet` of the file with one clip "default" (all frames, at `fps`), and the result shows the Sprite and SpriteAnimator components to use. Providers draw grids unevenly: look at the result and regenerate when frames wander. Example: {"prompt":"a knight walking right","path":"assets/knight_walk.png","frames":6,"columns":3,"frameWidth":64,"frameHeight":64,"fps":10}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | Where to write the file, project-relative, under assets/ (for example "assets/sfx/jump.wav"). The extension must match what the provider makes. |
| `prompt` | string | yes | What the animation shows: the subject and what it does over the frames. |
| `frames` | integer | yes | Number of animation frames. |
| `columns` | integer | no | Frames per row. Default: the square root of frames, rounded up. |
| `frameWidth` | integer | yes | Width of one frame in pixels. |
| `frameHeight` | integer | yes | Height of one frame in pixels. |
| `fps` | number | no | Frames per second of the "default" clip. Default 8. |
| `transparent` | boolean | no | Ask for a transparent background (the usual choice for sprites). Default true. |
| `references` | array | no | Project-relative images the result should follow (a character to keep consistent, a style). Sent to providers that accept reference images, in addition to style.references of assets.json. |
| `style` | boolean | no | Apply the house style of assets.json (style.prompt, style.references, style.palette). false skips all of it for this call. Default true. |
| `provider` | string | no | Asset provider to use instead of the one ai.json assigns to this kind of asset (a name from ai.providers, for example "fake" to try the flow offline). |
| `model` | string | no | Model to use instead of the one in ai.json. Empty: the provider's default. |
| `seed` | integer | no | Seed, for providers that take one (fake, asset-command with {seed}). Others ignore it with a warning. |
| `overwrite` | boolean | no | Replace the file when it already exists. The old file is not kept. Default false. |
| `author` | string | no | Who gets the credit in the provenance record. Default: "factoria". |

### `assets.generate_voice` (modifies state)

Since 0.1.6.

Generate spoken audio from text with the voice asset provider and record where it came from.

Calls the provider that ai.json assigns to "voice" (assets.voice) to speak `text` with `voice` (default: the voice in ai.json) and writes the audio file at `path`. Records provenance in assets.json (the text is the prompt). Example: {"text":"Welcome, traveller.","path":"assets/voice/welcome.mp3"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | Where to write the file, project-relative, under assets/ (for example "assets/sfx/jump.wav"). The extension must match what the provider makes. |
| `text` | string | yes | The words to speak. |
| `voice` | string | no | The provider's voice name or id (openai: alloy, verse...; elevenlabs: a voice id). Default: assets.voice.voice in ai.json. |
| `provider` | string | no | Asset provider to use instead of the one ai.json assigns to this kind of asset (a name from ai.providers, for example "fake" to try the flow offline). |
| `model` | string | no | Model to use instead of the one in ai.json. Empty: the provider's default. |
| `seed` | integer | no | Seed, for providers that take one (fake, asset-command with {seed}). Others ignore it with a warning. |
| `overwrite` | boolean | no | Replace the file when it already exists. The old file is not kept. Default false. |
| `author` | string | no | Who gets the credit in the provenance record. Default: "factoria". |

### `assets.import` (modifies state)

Since 0.1.6.

Bring a file made elsewhere (Aseprite, PSD, OBJ, FBX, PNG, WAV, glTF, MP4...) into the project's assets/ folder and record where it came from.

Copies or converts `source` (an absolute path on this machine, or relative to the project) into assets/ and writes its provenance (origin imported, source, license, author, ai, date) in assets.json, so credits and store disclosures can be made later. The importer is chosen by the extension:
- .png .jpg .tga .bmp, .wav .ogg .mp3 .qoa, .ttf .otf: copied as they are (images are checked to decode).
- .gltf and .glb: copied with the .bin buffers and images their uris point at, which must sit next to the model or below it (a missing buffer is an error, a missing image a warning). An identical file already there is shared; a DIFFERENT image with the same name is kept and the result warns (kits ship different Textures/colormap.png files: import each kit into its own folder with `path`, or pass overwrite), and a DIFFERENT buffer is an `exists` error. project.validate reports a model whose texture or buffer is missing.
- .aseprite .ase: becomes ONE PNG sprite sheet (frames in a grid, `columns` per row, default ceil(sqrt(frames))) and the `sheet` entry of assets.json: columns, rows, frameWidth, frameHeight, frames and a clip per tag (firstFrame, lastFrame, fps from the frame durations). Hidden layers are left out, layer and cel opacity apply, RGBA, grayscale and indexed colors work. Blend modes other than normal are drawn as normal, and ping-pong or reverse tags become forward clips; the result says so. The result lists the Sprite and SpriteAnimator settings that play it.
- .psd: the merged image becomes a PNG (layers are flattened).
- .obj (with its .mtl and textures): becomes a .gltf with an embedded buffer and the textures next to it; polygons are triangulated, objects/groups/materials become separate meshes, missing normals give flat shading, and the result has the bounds so you can scale it.
- .fbx: converted to .glb by FBX2glTF ($FACTORIA_FBX2GLTF or PATH) or by Blender (PATH or its install folder). With neither installed the error says where to get them.
- .mp4 .mov .webm .mkv .avi .m4v: converted to an MPEG-1 video with MP2 audio in an .mpg (the only video the engine plays, the same on every platform) by ffmpeg, at most 1280 px wide, quality 4, 30 fps when the frame rate is not one MPEG-1 has. ffmpeg is found through $FACTORIA_FFMPEG, PATH or the copy `factoria setup ffmpeg` installs; without it the error names that command. A source with no audio track gives a silent video (the result warns). The result has width, height, fps and duration and the Video component that plays it. An .mpg or .mpeg is checked to be MPEG-1 and copied.
Files land in assets/ (models in assets/models/, sounds in assets/audio/, fonts in assets/fonts/, videos in assets/video/ by default) or at `path`, which must be under assets/. An existing file is an error unless overwrite is true. Example: {"source":"C:/art/hero.aseprite","license":"CC0","author":"Ana"}.

| Argument | Type | Required | Description |
|---|---|---|---|
| `source` | string | yes | The file to import: an absolute path on this machine, or a path relative to the project folder. Not a URL: download it first. |
| `path` | string | no | Where it lands, under assets/ (a path ending in / is a folder). Default: assets/<name>.<ext>, or assets/models/, assets/audio/, assets/fonts/ or assets/video/ for those kinds. The extension is the importer's output (.png for Aseprite and PSD, .gltf for OBJ, .glb for FBX, .mpg for a video). |
| `license` | string | no | License or terms of the file, e.g. "CC0", "CC-BY 4.0", "bought from itch.io, single project". Recorded in assets.json. |
| `author` | string | no | Who made it. Recorded in assets.json for the credits. |
| `sourceUrl` | string | no | Where the file came from (a page URL). Recorded as the provenance source instead of the local path. |
| `ai` | boolean | no | Set true when AI made the content elsewhere (Steam's AI disclosure reads it). Leave out when unknown. |
| `columns` | integer | no | Aseprite only: frames per row of the sheet (default ceil(sqrt(frames))). |
| `overwrite` | boolean | no | Replace files that already exist. Default false. |

### `assets.list`

List project asset files with type and size. Types: texture, audio, font, mesh, script, scene, prefab, material, other (by file name).

Example: assets.list {"folder":"assets","extension":".png"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `folder` | string | no | Project-relative folder. Default "assets". |
| `extension` | string | no | Only files with this extension, e.g. .png |

### `assets.provenance`

Since 0.1.6.

Show where assets came from: the provenance record of one file, or all of them.

With `path`, the provenance record of that file (null when it has none). Without, every record in assets.json, how many are AI-made, and the art, sound and model files under assets/ that have no record yet. Example: {"path":"assets/hero.png"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | no | Project-relative path under assets/. Omit to list every record. |

### `assets.set_provenance` (modifies state)

Since 0.1.6.

Record where an asset came from (hand-made, imported, or made with AI elsewhere).

Replaces the provenance record of an existing file in assets.json. The generate commands write it for you; use this for files they did not make, so the AI disclosure is complete. `ai` says whether AI made the content (it defaults to true for origin generated, false otherwise). Example: {"path":"assets/music/theme.ogg","origin":"imported","ai":false,"license":"CC0","source":"https://example.com/theme","author":"A. Composer"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | Project-relative path of an existing file under assets/. |
| `origin` | string ["generated","imported","original"] | yes | generated: made by an asset provider. imported: brought in from a file made elsewhere. original: made by hand for this game. |
| `ai` | boolean | no | Whether AI made the content. Default: true for origin generated, false otherwise. |
| `kind` | string ["image","sound","music","voice","model3d"] | no | What the asset is, so the disclosure can tell sound effects, music and voice apart. |
| `provider` | string | no | Tool or provider that made it ("openai", "suno", "Aseprite"...). |
| `model` | string | no | Model that made it, for AI-made assets. |
| `prompt` | string | no | The prompt it was made from, for AI-made assets. |
| `references` | array | no | Reference images used. |
| `seed` | integer | no | Seed, when there was one. |
| `license` | string | no | License or terms ("CC0", "Purchased, standard license"...). |
| `author` | string | no | Person, studio or agent that made or chose the asset. |
| `source` | string | no | Where an imported asset came from: a URL or the original file. |
| `date` | string | no | YYYY-MM-DD. Default: today. |
| `notes` | string | no | Anything else, such as edits made by hand. |

### `assets.slice_sheet` (modifies state)

Since 0.1.6.

Make an image playable by SpriteAnimator: check its frame grid, or find the frames of an uneven sheet and repack them.

SpriteAnimator plays a uniform grid of frames (columns x rows, row-major from the top-left). Two ways to get one:
1. The image already is a grid: give columns/rows (or frameWidth/frameHeight). The grid is checked against the image size (a width that columns does not divide is an error that lists the columns that fit) and recorded as the `sheet` of the image in assets.json. Example: {"path":"assets/hero.png","columns":4,"rows":2,"fps":12}.
2. Frames separated by transparent gutters and of uneven sizes, as AI-generated and downloaded sheets often are: pass auto: true. Every group of touching pixels is a sprite (sprites whose boxes overlap are one frame), ordered by rows then columns, and repacked into a uniform grid of the largest sprite's size, each centred (align "bottom" stands characters on the same ground line). The new PNG is `out` (default <name>_sheet.png next to the image; the source is kept). `frames` is the number of sprites you expect: a different count is an error that lists what was found. Example: {"path":"assets/hero_raw.png","auto":true,"frames":8,"align":"bottom","background":"auto"}.
background "auto" first makes a solid background transparent (the four corners must be the same opaque colour; the background that touches them is cleared, the same colour inside a sprite stays), also for a grid. The result has the `sheet`, the SpriteAnimator fields and the Sprite texture to use. Aseprite files need no slicing: assets.import reads their frames and tags.

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | Project-relative image (png, jpg, tga, bmp), e.g. "assets/hero.png". |
| `columns` | integer | no | Grid mode: frames per row (1 if neither columns nor frameWidth is given). With auto: frames per row of the new sheet (default: the most sprites found in one row). |
| `rows` | integer | no | Grid mode: number of rows (1 if neither rows nor frameHeight is given). |
| `frameWidth` | integer | no | Grid mode: width of a frame in pixels, instead of columns. |
| `frameHeight` | integer | no | Grid mode: height of a frame in pixels, instead of rows. |
| `frames` | integer | no | Grid mode: how many cells are used, row by row (default all; the last row may be partly empty). With auto: the number of sprites you expect (a different count is an error). |
| `fps` | number | no | Playback speed to put in the SpriteAnimator fields of the result (default 10). Not stored in assets.json. |
| `auto` | boolean | no | Find the frames (groups of touching pixels separated by transparent gutters) and repack them into a uniform grid. Default false. |
| `align` | string ["center","bottom"] | no | auto only: where a sprite sits in its cell. center (default), or bottom: centred horizontally with feet on the cell's bottom edge, for characters standing on the ground. |
| `background` | string ["none","auto"] | no | auto: first make the solid background (the four corners the same opaque colour) transparent. Default none. |
| `out` | string | no | PNG to write when the pixels change (auto, background) or when given: default <name>_sheet.png next to the image. An existing file is replaced; use the image's own path to change it in place. |

### `assets.synth_sound` (modifies state)

Not released yet (on main after 0.2.0).

Make a game sound (bark, growl, coin, jump, explosion...) offline from a preset: a deterministic WAV, no provider and no key.

Synthesizes a short mono 16-bit 44.1 kHz WAV at `path` (under assets/, ending in .wav) from `preset`, with no AI provider and no key. The same preset, seed and seconds always give the same bytes; another `seed` is another take of the same sound (pitch and timing move a little). Peaks at -3 dBFS. Records provenance in assets.json (origin original, ai false, license CC0, the preset and the seed). Presets:
- bark: a dog bark: two short rough barks.
- growl: a low growl: a rattling low saw with noise.
- meow: a cat meow: a rising then falling vowel-like tone.
- screech: a high rough screech.
- whoosh: air passing: noise swelling and fading.
- explosion: a blast: low rumble and a noise burst.
- hit: an impact: a short thump with a click.
- coin: a coin pickup: two bright notes.
- pickup: an item pickup: a quick rising blip.
- jump: a jump: a rising chirp.
- powerup: a power-up: a fast rising arpeggio-like sweep.
- laser: a laser shot: a quick falling zap.
- blip: a UI blip: a very short tone.
- click: a UI click: a tiny noise tick.
- error: a refusal buzz: two low square pulses.
- splash: water: a noisy plop that fades.
- footstep: a soft footstep on dirt.
Good for placeholders and simple effects; for richer sounds import a CC0 kit (docs/ASSETS.md) or use assets.generate_sound. Example: {"path":"assets/audio/dog_bark.wav","preset":"bark","seed":3}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | Where to write the WAV, project-relative, under assets/ and ending in .wav, e.g. "assets/audio/bark.wav". |
| `preset` | string ["bark","growl","meow","screech","whoosh","explosion","hit","coin","pickup","jump","powerup","laser","blip","click","error","splash","footstep"] | yes | The kind of sound to make. See the list in the command description. |
| `seed` | integer | no | Chooses the take: the same preset and seed always give the same file; change it for a variation (pitch and timing shift up to about 10 percent). Default 0. |
| `seconds` | number | no | Length in seconds. Default: the preset's own length. |
| `overwrite` | boolean | no | Replace the file when it already exists. Default false. |

## audio

### `audio.log`

List the sounds played so far (clip path, frame, volume, bus, source entity), oldest first.

Every play request is logged: audio.play and audio.music from scripts, AudioSource components and scene music (`music: true`), with `ok: false` when the clip failed to load. `frame`/`time` are the scene clock (time.frame / time.elapsed in scripts). Use it after game.step to check that a sound fired. `after` (a seq from a previous call) returns only newer entries; `path` keeps entries whose path equals it or ends with /<path>. Example: audio.log {"path":"jump.wav"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `after` | integer | no | Only entries with seq greater than this. Default 0. |
| `path` | string | no | Only this clip: a project-relative path or a file name like "jump.wav". |
| `max` | integer | no | Return at most this many (the newest). Default 200. |

## project

### `checkpoint.create` (modifies state)

Since 0.2.0.

Save a checkpoint: a snapshot of every file of the project that checkpoint.restore can put back.

Copies the project's files into .factoria/checkpoints (content-addressed: a file that did not change since an earlier checkpoint is not copied again, so the second checkpoint of a project is cheap). Includes scripts, scenes, tests and assets; skips folders starting with '.', node_modules and a top-level build/. Keeps the newest 30 checkpoints. The editor makes one before every AI run (the Revert button of the AI Assistant), so call this yourself only before a risky change the user did not ask the editor to track. Returns {id, label, created (epoch seconds), files, bytes (size of the files), bytesStored (newly copied), filesHashed}. Example: {"label":"before the refactor"}.

| Argument | Type | Required | Description |
|---|---|---|---|
| `label` | string | no | A short name shown by checkpoint.list and the editor, e.g. "before the refactor". |

### `checkpoint.diff`

Since 0.2.0.

Show which files changed since a checkpoint (modified, added, deleted).

Compares the files now with checkpoint `id`. Returns {modified, added, deleted} (project-relative paths) and counts. Changes nothing. Example: {"id":"20261022-153012-7"}.

| Argument | Type | Required | Description |
|---|---|---|---|
| `id` | string | yes | A checkpoint id from checkpoint.list. |

### `checkpoint.list`

Since 0.2.0.

List the project's checkpoints, newest first.

Returns {checkpoints: [{id, label, created (epoch seconds), files, bytes}], limit}. Only the newest `limit` checkpoints are kept.

### `checkpoint.restore` (modifies state)

Since 0.2.0.

Put the project's files back as they were at a checkpoint (the user's Revert); ask the user before calling it.

Writes back the files that were modified or deleted since checkpoint `id` and deletes the files added since (anything the user edited by hand in those files is lost). First it saves an automatic checkpoint "Before restoring <label>" and returns its id as safetyCheckpointId: restoring that one takes this restore back. Files are written through a temp file and a rename, so a crash never leaves half a file. This does NOT reload the scene open in the editor (the editor's Revert button does). Returns {modified, added, deleted (what was done), safetyCheckpointId}. Example: {"id":"20261022-153012-7"}.

| Argument | Type | Required | Description |
|---|---|---|---|
| `id` | string | yes | A checkpoint id from checkpoint.list. |

## docs

### `docs.commands`

Reference of every available command (tool) with arguments.

Lists the commands of this session, including project tools from tools/*.js.

| Argument | Type | Required | Description |
|---|---|---|---|
| `format` | string ["markdown","json"] | no | Output format. Default "markdown". |

### `docs.components`

Reference of every component and field (types, defaults, docs).

Generated from the engine's reflection data; always accurate for this build. Use before writing scene JSON.

| Argument | Type | Required | Description |
|---|---|---|---|
| `format` | string ["markdown","json"] | no | Output format. Default "markdown". |

### `docs.list`

List the engine documentation available offline.

Start here. Returns name, title and size of each document; read one with docs.read. The document 'ai-guide' explains how to build games with FactorIA.

### `docs.read`

Read a documentation page (Markdown).

Example: {"name":"scripting"}. Long pages can be read in slices with startLine/maxLines. Names: see docs.list (e.g. ai-guide, architecture, scripting, components, licenses).

| Argument | Type | Required | Description |
|---|---|---|---|
| `name` | string | yes | Doc name ("scripting") or path ("docs/SCRIPTING.md"). |
| `startLine` | integer | no | First line to return (1-based). Default 1. |
| `maxLines` | integer | no | Maximum number of lines. Default 2000. |

### `docs.search`

Search the documentation by keywords.

Case-insensitive; every word counts, headings weigh more. Returns best sections with a snippet. Example: {"query":"input actions"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `query` | string | yes | Keywords. |
| `limit` | integer | no | Max results. Default 8. |

### `docs.write_reference` (modifies state)

Since 0.2.0.

Write the browsable API reference pages (docs/reference/) and docs/COMPONENTS.md.

Writes <out>/COMPONENTS.md (the whole `factoria api --md` text, including the scripting API) and <out>/reference/: README.md (index of every component and command), components/<category>.md and commands/<category>.md, all generated from the registries of this session. Run it outside a project (the scratch session) so plugin and project commands are not included; the unit test api_reference compares the committed files with this output. The files are identical on every platform. Example: {"out":"docs"} from the repository root.

| Argument | Type | Required | Description |
|---|---|---|---|
| `out` | string | yes | Docs folder to write into (relative to the working directory), usually "docs". |

## engine

### `engine.info`

Show engine version, platform, graphics backend and loop state.

Returns {engineVersion, platform, graphics, headless, frame, paused, fixedHz, components, commands}. Example: engine.info {}

## feedback

### `feedback.list`

List the engine-feedback entries recorded for this project.

Check this before reporting to see what is already recorded. Filters are optional. Example: {"status":"open","category":"physics"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `status` | string ["open","fixed-in-engine","wont-fix","duplicate"] | no | Only entries with this status. |
| `category` | string ["rendering-2d","rendering-3d","physics","audio","input","ui","scripting","scene","assets","animation","tooling","ai-integration","docs","platform","performance","networking","other"] | no | Only this category. |
| `severity` | string ["blocker","major","minor","nice-to-have"] | no | Only this severity. |

### `feedback.report` (modifies state)

Record an engine gap (missing feature, bug, confusing doc) and the workaround you used.

CALL THIS WHENEVER the engine lacked a feature or had a bug/limitation and you built a workaround or gave up on something, right when it happens (not at the end). Examples: a component field you expected does not exist; an error message did not say how to fix the problem; a documented API behaves differently; you had to emulate a feature in JavaScript; a command you wanted is missing.
The entry is appended to the project's ENGINE_FEEDBACK.json, which engine developers aggregate to decide what to build next. Reporting a gap similar to an open one merges into it (occurrences + 1), so duplicates are harmless. Write 'title' as a short noun phrase ("No one-way platforms"), 'missing' as what you needed and why, 'workaround' as what you did instead and where (list files in workaroundFiles), 'suggestion' as the concrete engine change that would remove the workaround.
Example: {"category":"physics","severity":"major","title":"No one-way platforms","missing":"Collider2D has no one-way option so the player cannot jump up through platforms.","workaround":"scripts/one_way.js disables the platform collider while the player moves upward.","workaroundFiles":["scripts/one_way.js"],"suggestion":"Add Collider2D.oneWay (bool)."}

| Argument | Type | Required | Description |
|---|---|---|---|
| `category` | string ["rendering-2d","rendering-3d","physics","audio","input","ui","scripting","scene","assets","animation","tooling","ai-integration","docs","platform","performance","networking","other"] | yes | Engine area of the gap. |
| `severity` | string ["blocker","major","minor","nice-to-have"] | yes | blocker: could not build the feature at all; major: large/fragile workaround; minor: small workaround; nice-to-have: convenience. |
| `title` | string | yes | Short noun phrase naming the gap; reuse wording for the same gap. |
| `missing` | string | yes | What the engine lacked or got wrong, and what you were trying to do. |
| `workaround` | string | yes | What you did instead (or 'none: feature dropped'). |
| `workaroundFiles` | array | no | Project-relative files implementing the workaround. |
| `suggestion` | string | no | How the engine could fix it (field, command, API). |
| `effort` | string ["small","medium","large"] | no | Your estimate of the engine-side effort to fix it. |
| `reporter` | object | no | Who is reporting. Defaults to {"kind":"ai"}; include your agent and model if you know them. |

### `feedback.update` (modifies state)

Change the status of a feedback entry or link it to an engine issue.

Engine developers use this when a gap is fixed (status fixed-in-engine), rejected (wont-fix) or duplicated. Example: {"id":"FB-0001","status":"fixed-in-engine","engineIssue":"#42"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `id` | string | yes | Entry id, e.g. FB-0001. |
| `status` | string ["open","fixed-in-engine","wont-fix","duplicate"] | no | New status. |
| `engineIssue` | string | no | Issue/PR link or id. |

## fs

### `fs.delete` (modifies state)

Delete a file or folder from the project.

Folders need recursive=true. factoria.json and ENGINE_FEEDBACK.json cannot be deleted. Not undoable unless the project is under version control. Inside .factoria/ (screenshots, saves, AI transcripts) only the scratch folder .factoria/tmp/ can be deleted, the same folder fs.write and scene.save may write to. Example: {"path":"scripts/old.js"} or {"path":".factoria/tmp","recursive":true}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | Project-relative path. |
| `recursive` | boolean | no | Delete a folder and everything in it. Default false. |

### `fs.edit` (modifies state)

Replace exact text in a file (must match exactly once unless replaceAll).

Example: {"path":"scripts/player.js","find":"speed = 300","replace":"speed = 360"}. Fails if 'find' is not found or matches several places; include more surrounding text to make it unique. Same write rule as fs.write (inside .factoria/ only .factoria/tmp/ may be edited).

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | Project-relative file path. |
| `find` | string | yes | Exact text to find (whitespace-sensitive). |
| `replace` | string | yes | Replacement text (may be empty to delete). |
| `replaceAll` | boolean | no | Replace every occurrence. Default false. |

### `fs.list`

List files and folders in the project.

Project-relative. Hides the tools' folders (.factoria, version control) except the scratch folder .factoria/tmp. Example: {"path":"scenes","recursive":true}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | no | Folder to list (default: project root). |
| `recursive` | boolean | no | Descend into subfolders. Default false. |
| `glob` | string | no | Only paths matching this glob, e.g. "**/*.js". |
| `limit` | integer | no | Maximum entries returned. Default 500. |

### `fs.read`

Read a text file (optionally a line range).

Example: {"path":"scripts/player.js","startLine":1,"endLine":80}. Binary files are refused. Set numbered=true to get line numbers for fs.edit planning.

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | Project-relative file path. |
| `startLine` | integer | no | First line (1-based). Default 1. |
| `endLine` | integer | no | Last line, inclusive (default: end of file). Default 0. |
| `numbered` | boolean | no | Prefix every line with its number and a tab. Default false. |

### `fs.search`

Search text in project files (substring or regex).

Skips binary files and .factoria/.git. Example: {"query":"RigidBody2D","glob":"**/*.json"} or {"query":"onUpdate\\(","regex":true}.

| Argument | Type | Required | Description |
|---|---|---|---|
| `query` | string | yes | Text or regular expression (ECMAScript). |
| `regex` | boolean | no | Treat query as a regular expression. Default false. |
| `caseSensitive` | boolean | no | Case-sensitive match. Default false. |
| `path` | string | no | Folder to search (default: project root). |
| `glob` | string | no | Only files matching this glob, e.g. "**/*.js". |
| `limit` | integer | no | Maximum matches returned. Default 100. |

### `fs.write` (modifies state)

Create or overwrite a file (text, or binary via base64; parent folders are created).

Example: {"path":"scripts/enemy.js","content":"export default class ..."}. For binary files such as PNG sprites pass encoding="base64" and the base64 of the bytes as content (e.g. {"path":"sprites/hero.png","encoding":"base64","content":"iVBORw0KGgo..."}). For small changes to an existing file prefer fs.edit. .json files are checked for syntax and a warning is returned if invalid; run project.validate afterwards. Writing into .factoria/ is refused except .factoria/tmp/, the scratch folder for throw-away files (the same rule as scene.save).

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | Project-relative file path. |
| `content` | string | yes | Full new file content (base64 text when encoding=base64). |
| `encoding` | string ["utf8","base64"] | no | "utf8" writes content as text; "base64" decodes it and writes the bytes (images, audio). Default "utf8". |
| `overwrite` | boolean | no | Allow replacing an existing file. Default true. |

## game

### `game.input` (modifies state)

Inject input: press/release actions or keys, or set an action state, mouse position/buttons, gamepad buttons/sticks, touches.

Names may be input actions from factoria.json, key names (Space, A, Left...) or MouseLeft/MouseRight/MouseMiddle. Forms: {"action":"jump","down":true}, {"key":"Space","down":false}, {"press":["jump"],"release":["fire"]}, {"mouse":{"position":[640,360]}}, {"gamepad":{"index":0,"buttons":{"A":true},"axes":{"LeftX":-1}}}, {"touch":{"id":1,"position":[200,300],"down":true}}. gamepad: index 0..3 (default 0), connected (bool), buttons {A, B, X, Y, Start, Back, Guide, DpadLeft/Right/Up/Down, LeftShoulder, RightShoulder, LeftThumb, RightThumb: bool}, axes {LeftX, LeftY, RightX, RightY: -1..1 with +Y up; LeftTrigger, RightTrigger: 0..1}; the state stays until set again (axes back to 0 to release the stick). touch: id (default 1), position in design pixels, down (default true: a new id begins, a known id moves; false lifts); the first finger also drives the mouse like a device. gamepad and touch also take an array for several pads/fingers. {"back":true} presses the system Back button of Android: the input.onBack handlers of the game run at the next frame, and when none consumes it the game asks to quit (game.state shows quitRequested). The input is applied now and seen by the next frame (game.step). Example: game.input {"press":["jump"]}

| Argument | Type | Required | Description |
|---|---|---|---|
| `action` | string | no | Action name (with `down`). |
| `key` | string | no | Key or mouse button name (with `down`). |
| `down` | boolean | no | New state for action/key. Default true. |
| `press` | array | no |  |
| `release` | array | no |  |
| `mouse` | object | no | {position:[x,y] in design pixels, left/right/middle: bool}. |
| `gamepad` | any | no | {index?: 0..3, connected?: bool, buttons?: {A: true, DpadLeft: false...}, axes?: {LeftX: -1, RightTrigger: 0.5...}}, or an array of those for several pads. |
| `touch` | any | no | {id?: number (default 1), position?: [x,y] design pixels, down?: bool (default true)}, or an array of those for several fingers. |
| `back` | boolean | no | true: press the system Back button (Android). |

### `game.logs`

Read recent log lines (engine, scripts, assets...).

Use `after` (a seq from a previous call) to fetch only new lines. Example: game.logs {"minLevel":"warn","max":50}

| Argument | Type | Required | Description |
|---|---|---|---|
| `minLevel` | string ["trace","debug","info","warn","error"] | no |  Default "info". |
| `after` | integer | no | Only entries with seq greater than this. Default 0. |
| `max` | integer | no |  Default 100. |

### `game.pause` (modifies state)

Pause the simulation (frame() stops simulating; game.step still works).

Example: game.pause {}

### `game.render_stats`

Not released yet (on main after 0.2.0).

What the renderer drew in the picture now: draw calls, triangles, lights, shadow casters, texture memory.

Draws a frame first when none was drawn since the last change (a headless run or an on-demand render may not have drawn one yet), then returns {drawCalls, sprites, shapes, textGlyphs, particles, meshes, meshesCulled, meshBatches, triangles, shadowCasters, lights, lightsDropped, lights2d, lights2dDropped, materials, materialFallbacks, textureMB, width, height, renderScale}. lights and lightsDropped count the 3D lights of the main pass (at most 32); lights2d and lights2dDropped count the Light2D lights (at most 16: the ones that reach the camera view are kept first). width and height are the size of the picture in pixels (design size * window.renderScale). Same as game.renderStats() in tests. Needs graphics. Example: game.render_stats {}

### `game.resume` (modifies state)

Resume the simulation after game.pause.

Example: game.resume {}

### `game.screenshot`

Capture the game view as a PNG and show it.

Draws the game view as it is now (design resolution), saves it and returns the path; clients display the image. Scripts only run when frames are stepped: step the game first so the picture shows what you expect. Default path .factoria/screenshots/frame_<n>.png. `scale` (0.25 to 4, default 1) draws the same frame into an image scale times larger, sharp and not upscaled, for store screenshots: HUD, camera and visible area stay the same, so a 1280x720 game at scale 1.5 gives a 1920x1080 PNG. `simulate` (greyscale, protanopia, deuteranopia, tritanopia) converts the saved PNG to what a colour-blind viewer sees (Machado 2009 matrices, severity 1.0, applied to the sRGB pixels in linear light; greyscale = Rec. 709 luminance) without changing what the player sees: use it to check that hazards, pickups and buttons read without their colour. Example: game.screenshot {"path":"shots/start.png","scale":1.5} or game.screenshot {"path":"shots/deut.png","simulate":"deuteranopia"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | no | Output PNG (project-relative or absolute). |
| `scale` | number | no | Render scale: image size = design size * scale, drawn natively (sharp), same HUD and visible area. 1.5 on 1280x720 = 1920x1080. Default 1. |
| `simulate` | string ["none","greyscale","protanopia","deuteranopia","tritanopia"] | no | Convert the saved PNG to what a colour-blind viewer sees (Machado 2009, severity 1.0, linear light) to check that things read without colour. The player's view is unchanged. Default "none". |

### `game.state`

Dump the game state as JSON: entities, physics, script errors, recent warnings, render stats.

Filters: entities (ids), components (names to include), includeDefaults, maxEntities (default 200). Example: game.state {"entities":["player"],"components":["Transform","RigidBody2D"]}

| Argument | Type | Required | Description |
|---|---|---|---|
| `entities` | array | no | Only these entity ids. |
| `components` | array | no | Only these components per entity. |
| `includeDefaults` | boolean | no |  Default false. |
| `maxEntities` | integer | no |  Default 200. |

### `game.step` (modifies state)

Advance the simulation by N fixed frames (deterministic) and return a state summary.

Each frame is exactly 1/fixedHz seconds. `press` holds actions/keys down and `release` lets go; they are applied BEFORE the first frame and stay in effect (a press without release stays held). To tap a button use game.step {"frames":1,"press":["jump"]} then game.step {"frames":1,"release":["jump"]}. Works while paused. Example: game.step {"frames":60,"press":["move_right"]}

| Argument | Type | Required | Description |
|---|---|---|---|
| `frames` | integer | no | Number of frames. Default 1. |
| `press` | array | no | Actions/keys to press first. |
| `release` | array | no | Actions/keys to release first. |

## i18n

### `i18n.export` (modifies state)

Since 0.2.0.

Write the game's string tables as a spreadsheet (CSV) or XLIFF files for translators.

Reads locales/<language>.json of every language and writes what a translator needs into `out` (default build/translations/, never inside locales/): format "csv" is ONE file, translations.csv (UTF-8 with a byte order mark so Excel opens it right; columns `key`, the default language, then one column per language to translate; fields with a comma, quote or line break are quoted), format "xliff" is one XLIFF 1.2 file per language to translate, translations.<language>.xlf (source = the default language's text, target = the translation, state "needs-translation" when missing; trans-unit id and resname = the key). A plural entry is one row per form, the key written `items#one`, `items#other`: the forms the language needs (CLDR) plus any the tables have. The row `$name` is the language's own name. A placeholder note lists the {names} to keep. Returns {format, files, rows, sourceLanguage, languages}. `languages` limits the columns (default: every language except the default). With `delimiter` ";" the CSV opens in Excel set to a language that writes decimals with a comma. Read the result back with i18n.import. Example: {"format": "csv", "languages": ["es", "ja"]}

| Argument | Type | Required | Description |
|---|---|---|---|
| `format` | string ["csv","xliff"] | no | csv = one spreadsheet file; xliff = one XLIFF 1.2 file per language (Poedit, OmegaT, memoQ...). Default "csv". |
| `languages` | array | no | Languages to translate into, as in localization.languages (e.g. ["es", "pt-BR"]). Default: all but the default language. |
| `out` | string | no | Folder to write into, project-relative or absolute (default build/translations). Not inside locales/. |
| `delimiter` | string [",",";","\t"] | no | CSV only. Use ";" for Excel set to Spanish, German, French... (decimal comma). Default ",". |

### `i18n.import` (modifies state)

Since 0.2.0.

Read a translator's CSV or XLIFF file back into locales/<language>.json.

Reads a file written by i18n.export (or edited in a spreadsheet or a translation tool) and updates the tables of the languages in it: existing keys are changed in place (nested objects stay nested, flat keys stay flat, key order is kept), keys the language lacks are added (nested by their dots when the file is nested), and an empty cell never deletes a translation. Rows `items#one` fill the forms of a plural entry. A column or target language that is not in localization.languages is an error with "did you mean"; a key the default language does not have, a {placeholder} that differs from the default language's, or a plural/plain mismatch is a warning and that row is not imported (placeholders: imported with the warning). The default language's own column is the source and is skipped unless named in `languages`. Tables are rewritten with 2-space indentation. Returns {file, format, dryRun, languages: {<tag>: {file, updated, added, unchanged, skippedEmpty, written, warnings}}}. With `dryRun` nothing is written. Example: {"file": "build/translations/translations.csv", "dryRun": true}

| Argument | Type | Required | Description |
|---|---|---|---|
| `file` | string | yes | The CSV or XLIFF file to read, project-relative or absolute. |
| `languages` | array | no | Import only these languages of the file (default: all but the default language). |
| `dryRun` | boolean | no | Report what would change without writing anything. Default false. |

### `i18n.set_language` (modifies state)

Since 0.2.0.

Switch the game to another language now: every Text and widget with a key is rewritten at once.

`language` is one of the game's languages (see i18n.state), written as in factoria.json or close to it ("pt_br", "es-MX" -> "es", "zh-CN" -> "zh-Hans"). Sends the game event "i18n.change" {language, previous} to the scripts (`i18n.on("change", fn)`). The choice is not saved: a game keeps the player's choice with `storage` and calls i18n.setLanguage at start (docs/LOCALIZATION.md). Returns {language, previous, changed}. Example: i18n.set_language {"language": "es"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `language` | string | yes | A language of factoria.json localization.languages, e.g. "es" or "pt-BR". |

### `i18n.state`

Since 0.2.0.

Show the languages of the game: which is current, which strings each lacks compared with the default language.

Returns {enabled, default, current, languages: [{code, name, file, loaded, keys, missing, missingKeys}], systemLanguages}. `enabled` is false when factoria.json has no "localization" section (then there is nothing else). Each language has one string table, file locales/<code>.json; `loaded` is false when the file is missing or broken (its strings come from the fallback languages: see the log). `keys` counts the strings of the table, `missing` the keys of the default language's table that this one lacks (missingKeys lists up to 20 of them), `name` is the table's "$name" or the code. systemLanguages is the player's system languages in a game with its own window and empty in headless runs. Example: i18n.state {}

## material

### `material.info`

Since 0.2.0.

Describe a custom material: lighting, alpha mode, params with types, defaults, ranges and docs, textures, programs and compile state.

Reads a *.material.json (schemas/material.schema.json) and returns {material, doc, shader, lighting, alphaMode, doubleSided, params: [{name, type, default, min?, max?, doc, implicit?}], textures: [{name, default, sampler, doc}], programs, compile: {state, dialect, toolFound}}. params are listed in the order of the uniform block (alphabetical); `implicit` marks alphaCutoff, which alphaMode "clip" adds by itself. `programs` are the shader programs the material makes: mesh and mesh_skin, plus shadow and shadow_skin when the snippet defines vertex() or the alpha mode is clip. compile.state is "compiled" when the cache holds this exact material for this machine's dialect, else "not_compiled" (run shader.compile); nothing is compiled by this command. A material file with errors returns them (JSON pointer, message, fix). Example: {"material": "materials/water.material.json"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `material` | string | yes | Project-relative path of the material, e.g. materials/water.material.json. |

## physics

### `nav.bake`

Not released yet (on main after 0.2.0).

Bake the NavMesh3D walkable grid from the static 3D colliders and return its stats.

A NavMesh3D component marks a box of the level. Baking voxelizes the static colliders inside it (no RigidBody3D or a static one; triggers, Collider3D.navObstacle and Collider3D.navWalkable colliders are left out; navWalkable ones are added as moving cells) into a grid of walkable cells: not steeper than maxSlope, agentHeight of room above, agentRadius from walls and drops, neighbours joined when they differ by at most stepHeight. It is baked by itself when the scene loads and when the colliders change (autoBake); call this to bake on demand, for example with autoBake off. mesh = id of the entity with the NavMesh3D; omitted = every enabled one. Result: a list of {mesh, cellsX, cellsZ, cells, spans, walkableCells, regions, obstacles, links, walkableBodies}; NavLink3D entities add off-mesh links; no timing, so the same level gives the same result. Example: nav.bake {"mesh":"navmesh"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `mesh` | string | no | Id of the entity with the NavMesh3D to bake; omitted = all enabled ones. |

### `nav.find_path`

Not released yet (on main after 0.2.0).

Find a walkable path between two 3D points on the baked NavMesh3D.

A* over the walkable grid, then string pulling: the result is few corner points from `from` to `to` on the walkable surface (meters). Result {found:true, points:[[x,y,z],...], length, complete, links?:[{point, entity}], from, to, mesh} or {found:false, reason, message, hint}: reason is start_off_mesh / goal_off_mesh (not on walkable ground; nearest and nearestDistance say where the nearest walkable point is) or disconnected (the two are in different walkable areas, a moving obstacle blocks the way, or a navWalkable platform is away). A start or goal within `snap` meters of walkable ground is moved onto it. closest=true returns a path to the reachable point nearest the goal (complete=false) instead of failing when disconnected. radius = agent radius of this query; larger than the NavMesh3D.agentRadius it was baked for is an error: bake for the bigger agent (a second NavMesh3D). mesh = id of the NavMesh3D entity; omitted = the first enabled one that contains `from`. Scripts: nav.findPath(from, to, {radius}). Example: nav.find_path {"from":[0,0,0],"to":[10,0,5]}

| Argument | Type | Required | Description |
|---|---|---|---|
| `from` | array | yes | Start point [x,y,z] in meters (the agent's feet). |
| `to` | array | yes | Goal point [x,y,z] in meters. |
| `radius` | number | no | Agent radius for this query; must not exceed NavMesh3D.agentRadius. Default: the mesh's. |
| `snap` | number | no | How far (meters) a start or goal off the walkable cells is moved onto the nearest one. Default: agentRadius + 2 cells. |
| `closest` | boolean | no | When the goal is unreachable, return a path to the reachable point nearest to it (complete=false). |
| `mesh` | string | no | Id of the entity with the NavMesh3D to use. Default: the first enabled one that contains `from`. |

### `nav.info`

Not released yet (on main after 0.2.0).

List the NavMesh3D components with their bounds, agent size, bake state and stats.

Use it to check that a level was baked and how much of it is walkable. Result: a list of {mesh, enabled, autoBake, baked, error?, boundsMin, boundsMax, cellSize, agentRadius, agentHeight, stepHeight, maxSlope, staleSinceBake, stats} (stats include links and walkableBodies). staleSinceBake is true when the colliders changed after the last bake of a mesh with autoBake off (call nav.bake).

## project

### `perf.baseline` (modifies state)

Since 0.2.0.

Measure the game and write or refresh THIS runner's entry in its performance budget file (perf.json).

Measures like perf.measure (3 runs, median) and stores the result under runners.<runner> of the budget file, keeping the other runners' entries, the run settings and any "tolerance" already there. Run it once per kind of machine you want checked (the runner id is os-compiler-renderer, e.g. windows-msvc-d3d11-warp, linux-gcc-llvmpipe, macos-clang-metal-paravirtual; a Debug build adds -debug), and again when the game got heavier ON PURPOSE. A game sets its own budget the same way: `factoria call perf.baseline` writes <project>/perf.json, commit it, and `factoria call perf.check` (in CI it fails past the tolerance) checks it. File: {format:"factoria.perf/1", frames, scene?, input?, tolerance?: {cpuAvg:1.0 (ratio over the baseline), cpuP95:1.5, memory:0.1, drawCalls:0.1, entities:0.1, triangles:0.1, lights:0.1, textureMB:0.1, cpuSlackMs:1, memorySlackMB:8, textureSlackMB:1, countSlack:2}, budgets?: {maxTriangles, maxLights, maxTextureMB, maxDrawCalls, maxEntities} (absolute caps, see perf.check), runners: {<id>: sample}}. A limit is max(baseline*(1+ratio), baseline+slack). `tolerance` here sets the file's tolerances. Returns {file, runner, sample, created}. Example: {"frames":300,"input":"replays/play.json"}.

| Argument | Type | Required | Description |
|---|---|---|---|
| `file` | string | no | Budget file, project-relative (or absolute). Default "perf.json". |
| `frames` | integer | no | Frames per run; stored in the file (default: the file's value, else 300). |
| `scene` | string | no | Start scene; stored in the file. |
| `input` | string | no | Project-relative input replay; stored in the file. |
| `repeats` | integer | no | Runs to take the median of. Default 3. |
| `tolerance` | object | no | Tolerances to store in the file: cpuAvg, cpuP95, memory, drawCalls, entities, triangles, lights, textureMB (ratios), cpuSlackMs, memorySlackMB, textureSlackMB, countSlack. |

### `perf.check`

Since 0.2.0.

Measure the game and fail when it costs more than its performance budget (perf.json) allows on this runner.

Measures with the settings of the budget file (frames, scene, input) and compares with runners.<this runner> of the file (see perf.baseline for the format and the tolerances). Memory, draw calls, entities, triangles, lights and texture memory (the last three only when the baseline has them) past their limit FAIL always. The file's "budgets" object ({maxTriangles, maxLights, maxTextureMB, maxDrawCalls, maxEntities}) or the `budgets` argument sets absolute caps that fail whatever the baseline says, also on a runner with no baseline. A time (cpuMsAvg, cpuMsP95) past its limit FAILS when the CI environment variable is set; elsewhere it only WARNS (status "warn"), because a developer machine can be busy. A time over the limit is measured a second time before it counts. A runner with no entry passes with status "no_baseline" and returns `baselineEntry`: the exact JSON to add under "runners" (or run perf.baseline here); with requireBaseline it fails instead (error `perf_no_baseline`, same data). Returns {runner, status: pass|warn|no_baseline, file, sample, rows: [{metric, measured, baseline, limit, exceeded}], message, baselineEntry?}; a failure is an error `perf_budget_exceeded` with the same data. Example: {} or {"file":"perf.json"}.

| Argument | Type | Required | Description |
|---|---|---|---|
| `file` | string | no | Budget file, project-relative (or absolute). Default "perf.json". |
| `strictTime` | boolean | no | Make a time over its limit fail even outside CI (default: only in CI). |
| `requireBaseline` | boolean | no | Fail when this runner has no entry in the file, so a CI job cannot pass without checking anything. Default false. |
| `budgets` | object | no | Absolute caps that fail whatever the baseline says (they replace the same keys of the file's "budgets"): maxTriangles, maxLights, maxTextureMB, maxDrawCalls, maxEntities. |

### `perf.measure`

Since 0.2.0.

Run the game headless for N frames and report its cost: CPU time per frame, peak memory, draw calls, entities, triangles, lights, texture memory.

Runs the project in a second headless engine inside this process, drawing every frame with the GPU renderer when there is one (graphics "none" otherwise: draw calls are 0), and returns {runner, sample: {frames, cpuMsAvg, cpuMsP95, cpuMsMax (CPU time of the engine per frame: process CPU, not wall clock, so a busy machine moves it less), peakMemoryMB (peak resident memory of the process), drawCalls, entities, triangles (of the main pass), lights (3D lights of the main pass plus Light2D lights of the same frame) and textureMB (GPU texture memory), all max over the run, graphics}}. `runner` is the id of this machine's and build's kind (os-compiler-renderer, plus -debug for a Debug build, e.g. linux-gcc-llvmpipe) that budget files key their baselines by. `input` is an input replay (like `factoria run --input`) to reach the heavy part of the game. Peak memory is the whole process's, so measure with the same host every time (`factoria call --no-graphics perf.measure`). Example: {"frames":300}.

| Argument | Type | Required | Description |
|---|---|---|---|
| `frames` | integer | no | How many frames to run (fixed step). Default 300. |
| `scene` | string | no | Start scene (default: the project's mainScene). |
| `input` | string | no | Project-relative input replay JSON applied during the run. |
| `repeats` | integer | no | Run this many times; time metrics are the median, memory/draw calls/entities the max. Default 1. |

### `perf.profile`

Since 0.2.0.

Run the game headless with the profiler on and report where the time goes: per engine system, per script behaviour class, GPU time, memory.

Use it when the game is slow and you need to know WHY (perf.measure only says how slow). Runs the project like perf.measure (drawing every frame with the GPU renderer when there is one) with the profiler on and returns {runner, graphics, profile}. profile = {frames, clock:"wall", frameMs:{avg,p95,max} (engine time of a frame), systems: {platform, physics, scriptsFixedUpdate, animation, scriptsEvents, ui, scriptsUpdate, audio, scriptsLateUpdate, localization, render, endOfFrame: {avgMs, p95Ms, maxMs}}, behaviours: [{class, path, avgMs (per frame, counting the frames it did not run), maxMs, callsPerFrame}] slowest first (every per-behaviour callback counts: onStart, onUpdate, onFixedUpdate, onLateUpdate, collision/trigger handlers, onEvent; timers, world.on handlers and promise jobs are the bucket "(timers, events and promises)"), gpu: {avgMs, p95Ms, maxMs, samples, reason} (milliseconds the GPU took to draw the world; null with a `reason` where the graphics backend has no timer queries: Metal, GLES3, WebGL2, or no GPU), memory: {start, end, peak: {processMB, jsHeapMB, textureMB, audioDecodedMB, entities}}}. Times are wall-clock milliseconds and vary a little from run to run: compare the ORDER and the big gaps, not the decimals. A system's time includes the behaviours it runs (scriptsUpdate holds every onUpdate). `warmup` frames (default 30) run first and are not counted, because the first frames load assets. Use `input` (an input replay) to reach the heavy part of the game. The profiler only measures: game.state, replays and saves are identical with it on. The editor's play sessions record the same section in play.report, and View > Profiler shows it live. Example: {"frames":300,"input":"replays/play.json"}.

| Argument | Type | Required | Description |
|---|---|---|---|
| `frames` | integer | no | How many frames to profile (fixed step), after the warm-up. Default 300. |
| `warmup` | integer | no | Frames to run first and leave out of the numbers (assets load, caches fill). Default 30. |
| `scene` | string | no | Start scene (default: the project's mainScene). |
| `input` | string | no | Project-relative input replay JSON applied during the run. |

## physics

### `physics.raycast`

Cast a ray against colliders (2D segment or 3D ray) and return the first hit.

2D: {from:[x,y], to:[x,y]}. 3D: {dimension:"3d", origin:[x,y,z], direction:[x,y,z], maxDistance}. Options, the same as physics.shape_cast and the script API physics.raycast(a, b, {mask, ignore, ignoreTriggers}): mask = collision layer bit mask (bit i = layer i, -1 = all layers); ignore = id (or name) of an entity whose colliders, and its children's, are skipped (usually the caster, so a ray starting at a body's edge does not hit the body itself); ignoreTriggers (default true) skips trigger colliders, false hits them too. A collider that contains the ray origin is always skipped. Result: {hit:false} or {hit:true, entity, point, normal, distance}. Example: physics.raycast {"from":[0,300],"to":[0,-300],"ignore":"player","ignoreTriggers":false}

| Argument | Type | Required | Description |
|---|---|---|---|
| `dimension` | string ["2d","3d"] | no |  Default "2d". |
| `from` | array | no | 2D start [x,y]. |
| `to` | array | no | 2D end [x,y]. |
| `origin` | array | no | 3D origin [x,y,z]. |
| `direction` | array | no | 3D direction. |
| `maxDistance` | number | no |  Default 1000. |
| `mask` | integer | no | Collision layer mask: bit i = layer i; -1 hits every layer. Default -1. |
| `ignore` | string | no | Entity id or name whose colliders (and its children's) are skipped, usually the caster. |
| `ignoreTriggers` | boolean | no | Skip trigger colliders; false hits them too. Default true. |

### `physics.shape_cast`

Sweep a circle, sphere or box from one point to another and return the first collider it touches.

Like physics.raycast, but the shape has size: use it to ask whether a character fits or how far a box can move before it hits something. 2 numbers in from/to = 2D, 3 numbers = 3D. shape: 2D {"shape":"circle","radius":8} or {"shape":"box","size":[16,24]}; 3D {"shape":"sphere","radius":0.5} or {"shape":"box","size":[1,2,1]} (2D pixels, 3D meters, full sizes). The shape is centred on the cast position and axis-aligned. Result: {hit:false} or {hit:true, entity, point, normal, distance}: distance is how far the CENTRE travels before contact, point the contact point, normal the hit surface's normal (pointing back at the shape). Colliders the shape already overlaps at `from` are skipped (like a ray starting inside one); a collider it only touches blocks the cast only if it moves towards it. Options as for physics.raycast: mask; ignore = id of an entity whose colliders (and its children's) are skipped, usually the caster; triggers are skipped unless ignoreTriggers=false. Example: physics.shape_cast {"shape":{"shape":"box","size":[32,48]},"from":[0,100],"to":[0,-300],"ignore":"player"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `shape` | object | yes | 2D: {shape:"circle",radius} or {shape:"box",size:[w,h]}. 3D: {shape:"sphere",radius} or {shape:"box",size:[x,y,z]}. |
| `from` | array | yes | Start of the shape's centre, [x,y] (2D) or [x,y,z] (3D). |
| `to` | array | yes | End of the shape's centre, same dimension as from. |
| `mask` | integer | no | Collision layer mask: bit i = layer i; -1 hits every layer. Default -1. |
| `ignore` | string | no | Entity id or name whose colliders (and its children's) are skipped, usually the caster. |
| `ignoreTriggers` | boolean | no | Skip trigger colliders; false hits them too. Default true. |

## platform

### `platform.add_backend` (modifies state)

Since 0.2.0.

Set up a store backend for this game: its plugin, its build and what the store needs.

One call instead of the manual steps of docs/PLATFORM.md ("Store backends"): writes the backend's plugin from its template (project.new_plugin with template = backend) unless factoria.json already declares it, builds it for this computer with CMake, and adds what that store needs. steam: the Steamworks plugin (achievements, stats, leaderboards, Cloud saves, DLC purchases, overlay, rich presence): writes it, builds it for this computer, copies Valve's redistributable libraries from the Steamworks SDK ("sdk": its folder or .zip) next to it for Windows, macOS and Linux, and writes steam_appid.txt ("appId", default Valve's test app 480) for development. apple: the StoreKit 2, Game Center and iCloud plugin for iOS and macOS (Swift: it builds on a Mac with Xcode). googleplay: the Google Play Billing, Play Games Services and Play Integrity plugin for Android (a C bridge and a Java module; it builds with the Android SDK's NDK). admob: the AdMob ads plugin for Android and iOS: Google's consent form (UMP), App Tracking Transparency on iOS and rewarded ads. It offers only the "ads" service, so it works next to the store backend of the game. Android: a C bridge and a Java module (built with the Android SDK's NDK). iOS: Swift (built on a Mac with Xcode against Google's iOS SDK: "sdk", its zip or folder). macOS has no AdMob SDK: there the game has no ads. Run it again after a change: it keeps what is there. Returns {backend, folder, done[], nextSteps[]}: nextSteps lists what only a person can do (store dashboards, accounts). factoria.json is patched, not rewritten: only the plugins.<backend> key is added, and the other keys, their order and the layout stay as they are. With `dryRun` true nothing is written, built or copied: the result is {backend, dryRun: true, folder, files[] (what it would write), keys[] (the factoria.json keys it would write), wouldDo[], nextSteps[]}. An argument that does not exist is an error with a "did you mean" (backend-specific ones like sdk or appId are listed above and are accepted for every backend). Example: {"backend": "steam", "appId": 480}.

| Argument | Type | Required | Description |
|---|---|---|---|
| `sdk` | string | no | (steam) The Steamworks SDK: its folder, or the steamworks_sdk_*.zip from partner.steamgames.com/downloads/list (a free Steamworks account). Valve's redistributable libraries are copied from it next to the plugin. Without it they are not copied: nextSteps says where to put them. Relative paths start in the project folder. (admob) Google's Mobile Ads SDK for iOS: its folder or the GoogleMobileAdsSdkiOS-*.zip from developers.google.com/admob/ios/quick-start. GoogleMobileAds.xcframework and UserMessagingPlatform.xcframework are copied from it into the plugin's ios/frameworks/ (git ignores them). Without it iOS is not built unless they are there already. Relative paths start in the project folder. |
| `appId` | integer | no | (steam) Your game's Steam app id, written to steam_appid.txt for development. Without it an existing steam_appid.txt is kept, else the file gets 480, Valve's test app (Spacewar), which any Steam account can run. |
| `appleSlices` | array | no | apple: which libraries to build: macos (the .dylib of a Mac app), iphoneos (an iPhone or iPad) and iphonesimulator (the iOS Simulator). Default: all three. |
| `appleBuild` | boolean | no | apple: false only writes the plugin and declares it, without building (any computer); build it later on a Mac with Xcode: cmake -S plugins/apple -B plugins/apple/build && cmake --build plugins/apple/build. Default true. |
| `playGamesId` | any | no | googleplay: the Play Games Services project id (digits: Play Console > Play Games Services > Setup and management > Configuration), written to android/src/main/res/values/games-ids.xml. Without it the backend offers purchases, the store page and Play Integrity, and no achievements, leaderboards or cloud saves. Kept as it is when not passed; "" turns Play Games off. Export again after changing it. |
| `googleplayBuild` | boolean | no | googleplay: false only writes the plugin and declares it, without building (any computer); build it later where the Android NDK is installed. Default true. |
| `admobBuild` | boolean | no | admob: false only writes the plugin and declares it, without building (any computer); build it later where the Android NDK (Android) or Xcode (iOS) is installed. Default true. |
| `admobPlatforms` | array | no | admob: the platforms the plugin is declared and built for. Default: android and ios. The iOS part is built only on a Mac. |
| `backend` | string ["steam","apple","googleplay","admob"] | yes | The store backend to set up; it is also the plugin's name. |
| `dryRun` | boolean | no | true = write, build and copy nothing: list the files and factoria.json keys it would write (files, keys) and the steps (wouldDo). Default false. |

### `platform.emit` (modifies state)

Since 0.2.0.

Send an event to the game as the store would: a purchase, the overlay opening or closing, a sign-in change.

`event` is "purchase" ({productId, status?: "purchased" | "pending" | "cancelled" (default purchased), transactionId?, receipt?}; a purchased one also records an unfinished transaction, made up when not given), "overlay" ({open: bool}) or "player" ({id?, name?, signedIn}). Scripts get it through platform.on(event, fn) at the start of the next frame (game.step). Fails when the game runs a real store backend. Example: platform.emit {"event":"overlay","data":{"open":true}}

| Argument | Type | Required | Description |
|---|---|---|---|
| `event` | string ["purchase","overlay","player"] | yes | The event name. |
| `data` | object | no | The event's data. Default {}. |

### `platform.reset` (modifies state)

Since 0.2.0.

Reset the fake platform backend: nothing unlocked, bought or saved, no scripted answers, signed in, an empty request log.

Also numbers transactions from fake-1 and integrity tokens from fake-integrity-1 again, and forgets the answer of platform.ads.setUnderAge (the game asks the age again). Pending requests are not cancelled. Fails when the game runs a real store backend (the message says which and why). Tests start every file with a fresh fake already; use this between tests that share state. Example: platform.reset {}

### `platform.respond` (modifies state)

Since 0.2.0.

Script the next answer(s) the fake platform backend gives to a method: an error, an exact result, or a change to the default.

`method` is a platform method such as "purchases.buy" (docs/PLATFORM.md lists them all). `answer` is one of {"error": "network", "message"?, "hint"?} to reject (codes: unavailable, notSignedIn, notAllowed, unknownId, network, failed), {"result": value} to resolve with exactly that value, or any other object, which is merged into the default result: {"status": "cancelled"} cancels a purchase (and buys nothing). Answers are used first in, first out, one per request; `times` queues the same answer several times. Fails when the game runs a real store backend. Example: platform.respond {"method":"purchases.buy","answer":{"status":"cancelled"}}

| Argument | Type | Required | Description |
|---|---|---|---|
| `method` | string | yes | The platform method, e.g. "purchases.buy", "achievements.unlock", "cloud.save". |
| `answer` | object | yes | {error, message?, hint?} \| {result} \| an object merged into the default result. |
| `times` | integer | no | How many requests get this answer. Default 1. |

### `platform.revoke` (modifies state)

Not released yet (on main after 0.2.0).

Take a purchase back in the fake platform backend, as a refund does, and send the game the event a real store would.

The product leaves purchases.restore() and its unfinished transaction is dropped; the game gets a "purchase" event {status: "revoked", productId, transactionId, receipt} at the start of the next frame (game.step), which platform.on("purchase", fn) listeners receive. Fails when the player owns no such product (the message lists the owned ones) or when the game runs a real store backend. Example: platform.revoke {"productId":"remove_ads"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `productId` | string | yes | The catalog id of the product to take back, e.g. "remove_ads". |

### `platform.set_ad` (modifies state)

Not released yet (on main after 0.2.0).

Script what the fake platform backend's test ad does: watched to the end, closed early, no ad to show, or consent refused.

`outcome` decides how every ads.showRewarded() ends until changed (and platform.reset): "watched" (the default: {rewarded: true}), "closedEarly" ({rewarded: false, reason: "closedEarly"}), "noFill" (no ad: ads.available() is false and showRewarded gives reason "noFill") or "consentRefused" (also sets gdpr and tracking to "denied"; reason "consentRefused"). `gdpr` ("granted", "denied", "notRequired", "unknown") and `tracking` ("authorized", "denied", "notDetermined", "restricted", "notRequired") are what ads.consent() answers; a denied gdpr stops every ad. `privacyOptions` ("required", "notRequired", "unknown") is what ads.consent() answers for the privacy options form: with "required", platform.ads.privacyOptions() "shows" the form. Give any of them. platform.state's fake.ads counts the ads shown and rewarded and the privacy forms shown. Fails when the game runs a real store backend. Example: platform.set_ad {"outcome":"closedEarly"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `outcome` | string ["watched","closedEarly","noFill","consentRefused"] | no | How the next ads end. |
| `gdpr` | string ["granted","denied","notRequired","unknown"] | no | What the GDPR (UMP) sheet answered. |
| `tracking` | string ["authorized","denied","notDetermined","restricted","notRequired"] | no | What the tracking (ATT) sheet answered. |
| `privacyOptions` | string ["required","notRequired","unknown"] | no | Whether the consent form for changing ad choices is required (ads.consent privacyOptions). |

### `platform.set_fake` (modifies state)

Since 0.2.0.

Change how the fake platform backend behaves: signed in or out, and how many frames it holds its answers.

`signedIn: false` makes every method but player.signIn answer notSignedIn (and sends a `player` event); `delayFrames: n` holds each answer for n engine frames (0, the default, answers at once), so a test can look at the "waiting" state of a screen and game.step() until the answer arrives. Give any of them. `backend: "none"` makes the fake behave as the none backend (platform.has false for every service, every call rejects `unavailable`, signIn answers signed out) until platform.reset. Fails when the game runs a real store backend. Example: platform.set_fake {"delayFrames":2}

| Argument | Type | Required | Description |
|---|---|---|---|
| `signedIn` | boolean | no | false: the player is not signed in. |
| `backend` | string ["fake","none"] | no | "none": behave as the none backend until platform.reset. |
| `delayFrames` | integer | no | Frames each answer is held (0 = at once). |

### `platform.state`

Since 0.2.0.

Show which platform backend runs, its services, the player, the declared ids and, for the fake backend, everything it holds.

Returns {backend, why, adsBackend, adsWhy, audience, underAge, services, player: {id, name, signedIn}, catalog: {achievements, stats, leaderboards, products, placements} (the ids factoria.json "platform" declares), pending (requests waiting for an answer), fake?} where `fake` (only when the backend is the fake) is {signedIn, delayFrames, frame, achievements: {id: {unlocked, progress}}, stats: {id: value}, leaderboards: {id: best} (a daily or weekly board: "id@periodKey"), cloud: {key: text}, owned: [productId], unfinished: [{transactionId, productId, receipt}], presence: {text, data}, ads: {outcome, gdpr, tracking, shown, rewarded}, scripted: {method: answers queued}, held, calls: [{seq, frame, method, args, ok, result | error, scripted?}], callsDropped}. `calls` is every request the game made, with the arguments the backend got (store ids included) and how it was answered: assert on it after game.step. `adsBackend` is the backend that answers ads.* (an ads plugin such as admob, the store backend when it offers ads, or "none") and `adsWhy` says why; `audience` is factoria.json platform.ads.audience and `underAge` what platform.ads.setUnderAge answered (true for a children's game, null if not asked). Example: platform.state {}

## play

### `play.report`

What happened while the user played: perf, spikes, warnings/errors, their problem marks and screenshots.

Call it when the user says they played the game and saw problems (slow, ugly UI, bugs). Returns the session.json content (perf: avg/p95/max frame ms and frames over 16.7/33 ms; profile: where the time went, per engine system, per script behaviour class (ms and calls per frame, slowest first), GPU ms or null + reason, memory; spikes: slowest frames with entity count and render stats; logs: warnings and errors; marks: frame, time, note and screenshot path, 1-based `n`), `replay` (the input file, absolute path) and `replayHow`. The result carries ONE picture ($image): the screenshot of mark `mark` (default 1); call again with mark 2, 3... to see the others. `session` defaults to the latest (see play.sessions). Example: play.report {"mark":2}

| Argument | Type | Required | Description |
|---|---|---|---|
| `session` | string | no | Session folder name from play.sessions. Default: the latest. |
| `mark` | integer | no | Which mark's screenshot to attach as the picture. Default 1. |

### `play.sessions`

List the recent play sessions recorded by the editor (Play .. Stop), newest first.

Each session is a folder .factoria/sessions/<yyyymmdd-hhmmss>/ written when the user pressed Stop in the editor. Rows have a short summary: scene, duration, frame time p95/max, number of warnings/errors and the user's marks (notes). Call play.report {session} for the details and screenshots. Example: play.sessions {"max":5}

| Argument | Type | Required | Description |
|---|---|---|---|
| `max` | integer | no | How many sessions to list. Default 10. |

## scene

### `prefab.save` (modifies state)

Save an entity of the running world, with its children, as a prefab file.

Writes {"format":"factoria.prefab/1","entity":{...}} in the canonical compact layout (the one scene.save and scene.format write), ready to commit and to instantiate with scene.spawn {"prefab":path}, a scene entity {"prefab":path} or a scene.import_ascii legend. `id` is the id (or name) of an entity of the running world; the whole tree below it is saved with every component's non-default serialized fields (runtime state such as velocities and animation time is not). A prefab describes the reusable thing, not this instance, so the file does NOT carry: the ids (every instantiation gets fresh ones; an id stays only where another entity of the saved tree points at it through an Entity field, so those references survive); the root's Transform.position (where the instance happens to stand: the spawn call, the scene entity or the legend places each new instance; children keep their positions relative to the root; rotation and scale are kept); tags starting with 'tilemap:' (scene.import_ascii adds them to the objects it places, and a prefab carrying one would be destroyed when that map is re-imported); Entity fields pointing at an entity outside the saved tree (they would dangle). An entity created from a prefab saves fully expanded (no `prefab` key). To keep the exact position, save the whole world with scene.save instead. `path` is project-relative (or absolute inside the project), must end in .prefab.json and normally lives in prefabs/. An existing file is NOT replaced unless `overwrite` is true. Returns {path, entity (id of the saved entity in the running world), children (number of saved descendants), overwritten, notes?}; `notes` lists what was left out of the file when something noteworthy was. Errors name the id with did-you-mean suggestions or the path rule with a corrected name. Example: prefab.save {"id":"enemy_3","path":"prefabs/enemy.prefab.json"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `id` | string | yes | Id (or name) of the entity to save; its children are saved with it. |
| `path` | string | yes | Project-relative output path ending in .prefab.json, e.g. prefabs/enemy.prefab.json. |
| `overwrite` | boolean | no | Replace the file when it already exists. Without it an existing file is an error. Default false. |

## project

### `project.add_menu_kit` (modifies state)

Not released yet (on main after 0.2.0).

Copy the menu kit (main menu, options, pause, loading screen, ...) into the game and merge its strings into the locales.

The menu kit of docs/MENUS.md (templates/menus/ in the FactorIA install): `parts` picks what to copy, the files go to the same paths in the game (scripts/, scenes/, prefabs/ui/, tests/recipe.test.js) and the kit's strings are merged into locales/<language>.json for every language of factoria.json "localization" (added when the game has none). Scenes and prefabs are written in the canonical layout of scene.format. Parts that others need come along (the main menu needs core, options, credits, shop and ageGate) and are listed in `requiredBy`. A kit file the game already has and has changed is NOT touched unless `overwrite` is true: it is listed in `skipped`; a file that is the same is listed in `unchanged`, so running the command twice changes nothing. String keys the game already has are never replaced, with or without `overwrite`; only missing ones are added. A language the kit has no texts for gets the English ones. The "pause" part also adds the input action "pause" to factoria.json when it is missing. Returns {parts[], requiredBy{}, added[], unchanged[], overwritten[], skipped[{file,reason}], locales[{file,created,merged[],skipped[]}], settings[], nextSteps[]}. Examples: {} (all parts), {"parts":["pause"]}, {"parts":["main-menu","loading"],"overwrite":true}.

| Argument | Type | Required | Description |
|---|---|---|---|
| `parts` | array | no | Which parts to add; default all. Parts and what they copy: core: Shared by every menu: the player's settings saved in storage (scripts/settings.js), the stack of panels that open over each other (scripts/ui/menu_stack.js), read-aloud for focused widgets (scripts/ui/read_aloud.js) and the menu.* strings.; options: The options panel: video, a colour filter, audio per bus, controls (rebinding) and language, saved between runs (prefabs/ui/options.prefab.json, scripts/ui/options.js).; credits: The credits panel that lists the software inside the runtime (scripts/ui/credits.js).; shop: The shop panel for in-app purchases (scripts/ui/shop.js) and the behaviour that pauses a level while the store's overlay is open (scripts/store_events.js). Needs the products in factoria.json "platform" (docs/PLATFORM.md).; ageGate: The age gate for a game whose ads reach children and adults (factoria.json platform.ads.audience "mixed"): a neutral birth-year screen (prefabs/ui/age_gate.prefab.json, scripts/ui/age_gate.js) that tells the ad network whether the player is under the age of consent with platform.ads.setUnderAge(). The main menu opens it once, before any ad; its tests/age_gate.test.js checks it.; main-menu: The title screen: scenes/menu.scene.json (Play, Options, Credits, Shop, Quit, with the options, credits, shop and age gate panels in it), scripts/main_menu.js, and tests/recipe.test.js, the kit's test, which drives the menu with a gamepad only. Needs core, options, credits, shop and ageGate: the scene uses their scripts and prefab.; pause: The pause menu (prefabs/ui/pause.prefab.json, scripts/pause_menu.js): Resume, Options, Main menu. Put one entity with scripts/pause_menu.js in every level; adds the "pause" action to factoria.json when the game has none.; loading: The loading screen (scenes/loading.scene.json, scripts/loading.js): the main menu's Play button goes through it to the first level.; keyboard: The on-screen keyboard for a player without a physical one (prefabs/ui/keyboard.prefab.json, scripts/ui/keyboard.js): put one entity with the script in every scene that has a TextField.; dialogue: Subtitles for spoken lines and hints: say(key, {sound, speaker}) in scripts/dialogue.js, drawn by a Captions entity. Its strings are the example lines captions.* (replace them with the game's own). |
| `overwrite` | boolean | no | Replace a kit file the game has changed (a file that is the same is left alone). Without it that file is left as it is and listed in `skipped`. String keys the game has are never replaced. Default false. |

### `project.create` (modifies state)

Create a new game project from a template.

Creates `dir` (relative to the server's working directory unless absolute) with factoria.json, a scene, scripts, a test, AGENTS.md, ENGINE_FEEDBACK.json and the real types/factoria.d.ts. Afterwards start `factoria mcp --project <dir>` to work on it. Example: {"dir":"my-game","template":"2d-platformer","name":"My Game"}.

| Argument | Type | Required | Description |
|---|---|---|---|
| `dir` | string | yes | Target folder (created; must be empty or new). |
| `template` | string | no | 2d-empty, 2d-platformer or 3d-empty (see project.templates). Default "2d-empty". |
| `name` | string | no | Display name (default: folder name). |
| `id` | string | no | Reverse-DNS id, e.g. com.example.mygame. |

### `project.export` (modifies state)

Since 0.1.2.

Package the game for a platform: a desktop bundle, an Android APK/AAB, an iOS project, or a web page (HTML5).

Validates the project (factoria.json, name, mainScene, reverse-DNS id, the icon and export settings) and writes a fresh <out>/<game-slug>-<platform>/ folder (deleted and recreated on every call, but only when it is empty or an export wrote it: every export leaves a .factoria-export file at its top, and any other existing folder of that name is an error that says how to proceed, never deleted; the project itself is not modified). linux/windows/macos: the game plus the factoria_player runtime found next to the running factoria binary, so exporting for another OS than this machine's fails with a hint. android: a complete Gradle project that is then BUILT with its own Gradle wrapper (needs a JDK 17+ and the Android SDK, found automatically; the first build downloads Gradle and the Android Gradle plugin, so it takes minutes and needs network): `format` "apk" (default) or "aab" (Google Play bundle) leaves <slug>[-debug].apk/.aab next to the project and reports it as `artifact`; "gradle" only writes the project and builds nothing. `release` builds the release variant (signed with export.android.signing; without a keystore it is an error unless `allowDebugKey` is true); on linux, windows and macos it packs the whole game into one archive, game.pak, next to the executable (no game/ folder, no loose scripts: they become bytecode unless export.scriptBytecode is false) and reports it as `pack` with the packed paths in `packed`. ios: the game plus an Xcode/CMake project and build_ios.sh. Android and iOS have a mode, reported as `mode`: "prebuilt" (the engine is the ready-made player in the mobile/ folder next to the factoria binary of the FactorIA download: no engine source, and for Android no NDK or CMake) or "source" (the engine is compiled from a source checkout, chosen by $FACTORIA_ENGINE_DIR or when factoria runs from a development build); with no players and no checkout the error says what to do. A failed Gradle build is an error that quotes what went wrong and where the log is (<out>/<slug>-android/build.log); the Gradle project stays on disk. linux with `format` "appimage" also builds the whole game as one <out>/<slug>-linux/<slug>-x86_64.AppImage (reported as `artifact`; needs Linux x86_64 or WSL and the tools of `setup.install` component appimage; the folder export stays). web: <slug>-web/ holds index.html (the loading page), factoria_player.js and factoria_player.wasm (the Emscripten player, found with `player`, else next to the factoria binary in web/, else installed by `setup.install` component players with platforms ["web"], else a web build of the engine source) and game.pak (the whole game, scripts as bytecode, always, whatever `release` says), and <out>/<slug>-web.zip next to the folder holds the same with index.html at its root: upload it to itch.io as an HTML5 game (`artifact`, format "zip"; `mode` says where the player came from: explicit, package, installed or build). windows with `format` "msix" (or export.windows.format) also writes <out>/<slug>-windows.msix next to the folder, the package of the Microsoft Store, from any computer (reported as `artifact`, format "msix"; identity in export.windows.msix; sign it with `sign.windows`, upload it with `publish.microsoft`). A browser needs the folder served over http, not opened as a file (nextSteps has the command). macOS: sign and notarize the exported app with `sign.macos`. Every export also writes FACTORIA_NOTICES.txt, the licenses of the engine code inside the game, where it ships with it (`notices`). Returns {outputDir, mode (android/ios/web), format and artifact (android, web), pack (web too), notices, files[], nextSteps[], warnings[]}; nextSteps lists what to do next (e.g. the adb install command). dryRun: true runs every check and writes nothing (no Gradle either): it returns {platform, outputDir (the folder an export would replace), mode, format, artifact (the file a build would write) and toolchain (android: the JDK and SDK found and where from), player (desktop), warnings[]} or the error the export would give (e.g. no JDK installed). Details: docs_read {"name":"exporting"}. Examples: {"platform":"windows","release":true}, {"platform":"android","format":"aab","release":true}.

| Argument | Type | Required | Description |
|---|---|---|---|
| `platform` | string | no | linux, windows, macos, android, ios or web (aliases win, mac, osx, html5 also work). web: a folder with index.html, the web player and game.pak, plus <slug>-web.zip next to it for itch.io. Default: the machine running factoria. |
| `out` | string | no | Parent folder of the export, relative to the project folder and inside it. Default: build/export. |
| `format` | string ["apk","aab","gradle","appimage","msix","folder"] | no | Windows: msix also writes <slug>-windows.msix next to the export folder, the Microsoft Store package (any host; identity in export.windows.msix); folder (the default unless export.windows.format says otherwise) writes only the folder. Android: apk (an installable app, the default unless export.android.format says otherwise), aab (the Google Play bundle) or gradle (only the Gradle project, nothing is built and no JDK or SDK is needed); apk and aab run Gradle and need a JDK 17+ and the Android SDK. Linux: appimage also builds <slug>-x86_64.AppImage, the whole game as one file (needs Linux x86_64 or WSL, and `setup.install` component appimage once). Other platforms ignore it. |
| `release` | boolean | no | Android: build the release APK/AAB (signed with export.android.signing and the keystore passwords from FACTORIA_ANDROID_KEYSTORE_PASSWORD / FACTORIA_ANDROID_KEY_PASSWORD or ~/.factoria/export.json; without a keystore it is an error, see allowDebugKey). Desktop (linux, windows, macos): the game ships as ONE archive, game.pak, instead of the game/ folder, with the scripts compiled to bytecode unless export.scriptBytecode is false in factoria.json. iOS: only changes the build commands of the iOS script. Default false. |
| `allowDebugKey` | boolean | no | Android release build without a keystore (no export.android.signing in factoria.json): sign with the debug key instead of failing. Fine for trying the build on your own device; Google Play rejects such an app, so never upload it. Create a real keystore for the store (keytool -genkeypair, or the editor's Platform settings > Android). Default false. |
| `allowPlayerMismatch` | boolean | no | Desktop (linux, windows, macos): bundle the factoria_player even when it was built from another commit than this factoria (its build fingerprint differs or is missing). By default that export stops with an error, because an old player may lack what the game uses (components, script API) or fail to start; the CLI flag is --allow-player-mismatch. Rebuild both from one checkout instead when you can. Default false. |
| `dryRun` | boolean | no | Only check whether the export can run (project, player or mobile mode, output folder): returns the plan or the error, writes nothing. Default false. |

### `project.info`

Show the project settings, input actions, current scene, scenes and scripts.

Returns the parsed factoria.json plus {currentScene, scenes[], scripts[], prefabs[], sceneErrors}. Example: project.info {}

### `project.new_ci_workflow` (modifies state)

Since 0.2.0.

Write a GitHub Actions workflow that validates, tests and exports the game on every push.

Writes .github/workflows/factoria.yml into the game's folder. On every push to main or master and every pull request it installs FactorIA on an Ubuntu 24.04 runner (the release package of the SAME version as this factoria, checked against the SHA-256 GitHub lists; a build from source has no release of its own, so it follows the newest one and warns), installs the OpenGL/X11/Xvfb libraries, runs `factoria validate` and `factoria test` under xvfb-run, downloads the other players (`factoria setup players`), exports the game for Linux and Windows, and on a macOS runner for macOS, and uploads the exports as workflow artifacts (tar.gz; the Windows one is a zip). It never overwrites a file that differs unless `overwrite` is true (an identical file is left alone). Project templates do not carry the file: call this when the game goes on GitHub. A game in a subfolder of the repository: GitHub reads workflows only from the repository root, so write it with `workingDirectory` set to that folder and move the file to <repo>/.github/workflows/. Returns {path, written, dryRun, version, repo, platforms[], workflow (the YAML), warnings[], nextSteps[]}. Details: docs_read {"name":"exporting"}, "CI for your game". Examples: {}, {"platforms":["linux","windows"],"dryRun":true}, {"workingDirectory":"games/my-game","overwrite":true}.

| Argument | Type | Required | Description |
|---|---|---|---|
| `platforms` | array | no | Which exports the workflow makes: linux, windows, macos (aliases win, mac, osx also work). Default: all three. |
| `path` | string | no | The workflow file, relative to the project: .github/workflows/<name>.yml. Default: .github/workflows/factoria.yml. |
| `workingDirectory` | string | no | The game's folder relative to the repository root when factoria.json is not at the root of the repository. Default ".". |
| `version` | string | no | The FactorIA release the workflow downloads: "latest" or a version such as 0.1.6. Default: the version of this factoria (a build from source: latest, with a warning). |
| `overwrite` | boolean | no | Replace the file when it exists and differs. Without it that is an error. Default false. |
| `dryRun` | boolean | no | Return the workflow and what would happen; write nothing. Default false. |

### `project.new_plugin` (modifies state)

Since 0.1.6.

Create a native plugin (C/C++) for this game and declare it in factoria.json.

Writes a plugin folder (default plugins/<name>, or `path`: project-relative, absolute, or with ${VARIABLE} parts for a private folder outside the repository) holding src/plugin.c, include/fa_plugin.h (the whole C API), CMakeLists.txt, README.md and android/ (the Gradle module of its Android build), and adds "plugins": {"<name>": {"path", "platforms"}} to factoria.json (`platforms` defaults to this computer's). The plugin adds the script function plugins.<name>.add(a, b) and the command <name>.info: build it with CMake (nextSteps), then `factoria run` loads it. `template` (default "basic") picks another starting point: a platform backend for a store (the folders of platforms/plugins/ in the engine; docs/PLATFORM.md, "Writing a backend"). The name: lower-case letters, digits and underscores, not an engine area (scene, game, ...). Fails when factoria.json already declares the plugin or the folder is not empty. Only that key of factoria.json changes: the other keys, their order and the layout stay as they are. With `dryRun` true nothing is written: the result lists the `files` and the `keys` of factoria.json it would write. An argument that does not exist is an error with a "did you mean". Returns {folder, files[], keys[], plugin, nextSteps[], dryRun?}. Details: docs_read {"name":"extending"} (section G). Example: {"name": "example"}.

| Argument | Type | Required | Description |
|---|---|---|---|
| `name` | string | yes | The plugin's name: scripts call plugins.<name>.<function>() and its commands are <name>.<verb>. |
| `template` | string | no | What to start from: "basic" (an example command and function) or a store backend template shipped with the engine (the folders of platforms/plugins/: they answer the game's platform.* calls, docs/PLATFORM.md). An unknown name lists the available ones. Default "basic". |
| `path` | string | no | Its folder (default plugins/<name>): project-relative, absolute, or with ${VARIABLE} parts. |
| `platforms` | array | no | The platforms it will be built for (default: this computer's). |
| `dryRun` | boolean | no | true = write nothing: list the files and the factoria.json keys it would write. Default false. |

### `project.templates`

List the project templates `project.create` can start from.

Returns [{name, description, dimension}]. Example: {}.

### `project.test` (modifies state)

Run the project's JavaScript tests (tests/*.test.js) headless and return the report.

Tests run inside this engine instance and change the world; reload the scene afterwards (scene.reload). `files` runs only those test files: project-relative paths, folders or globs such as tests/ui*.test.js (a path that is not a *.test.js file is an error that says what to pass). Example: project.test {"filter":"player","files":["tests/saves.test.js"]}

| Argument | Type | Required | Description |
|---|---|---|---|
| `filter` | string | no | Only run test cases whose name contains this. |
| `files` | array | no | Test files, folders or globs, project-relative (default: every tests/**/*.test.js). |

### `project.validate`

Check the whole project for errors: project file, scenes, assets, input bindings, scripts, feedback file.

Run after every batch of edits. Returns {ok, errors[], warnings[]}; each issue has file, JSON pointer, message and a fix hint. Checks every *.scene.json and *.prefab.json of the project, wherever it is kept (scenes/, prefabs/, levels/...; folders starting with '.', node_modules and a top-level build/ are skipped, like scene.format). Loads every scene, and every prefab on its own, into a temporary world, so it does not disturb a running game; anything the loader refuses is an error with the JSON pointer, e.g. an unknown field or a value outside a field's range ("Field 'sides': value 200 is outside the allowed range 3..64"; the offending field keeps its default, nothing is clamped). Scene and prefab files whose whitespace differs from what scene.save writes are valid: they give ONE entry in `notes` (informational, not a warning; optional fix: scene.format). The result has `ok`, `errors`, `warnings`, `notes`, `scenesChecked`, `scriptsChecked`, `materialsChecked`. It reports a .json that a script imports and that is not valid JSON once, as that file with line and column. Example: {} Warns about Script.props keys that do not exist on the behaviour, and about behaviour methods that look like misspelled lifecycle hooks (update() or onupdate() instead of onUpdate()).

## publish

### `publish.appstore` (modifies state)

Since 0.2.0.

Upload the iOS build (.ipa) or the Mac App Store package (.pkg) to App Store Connect (xcrun altool, macOS only).

Runs `xcrun altool --upload-package <ipa> --type ios --apple-id <id> --bundle-id <id of factoria.json> --bundle-version <export.ios.buildNumber> --bundle-short-version-string <version> --apiKey <key id> --apiIssuer <issuer id>`. The .ipa is NOT made by `factoria export --platform ios` (that writes an Xcode project): archive it in Xcode (Product > Archive, Distribute App > App Store Connect > Export) and save it as build/export/<game-slug>.ipa, or pass `artifact`. Needs: factoria.json publish.appstore {appleId} (the number of the app in App Store Connect) and id (the bundle id), Xcode (xcrun: PATH, FACTORIA_XCRUN, or publish.xcrun of ~/.factoria/export.json), macOS (other computers get a teaching error; dryRun works anywhere), and an App Store Connect API key (role App Manager): FACTORIA_APPSTORE_API_KEY = path of AuthKey_<KeyID>.p8, FACTORIA_APPSTORE_API_KEY_ID, FACTORIA_APPSTORE_API_ISSUER (FACTORIA_NOTARY_API_KEY / _KEY_ID / _ISSUER of sign.macos also work). The key stays a file outside the project: nothing of it is written, shown or logged. After the upload App Store Connect processes the build, then it shows in TestFlight. Returns {store, dryRun, uploaded, version, tool, uploads[{platform, folder, destination, files, bytes, uploaded}], steps[{title, command, commandLine, files, ran, exitCode}], exitCode, log, warnings[], nextSteps[]}; a failed altool is an error whose data is that report. The Mac App Store works the same way with the signed package sign.macos {"distribution":"appStore"} writes (build/export/<game-slug>-macos.pkg): `artifact` ending in .pkg, or `platforms: ["macos"]`, runs altool with `--type macos` and export.macos.buildNumber; with both an .ipa and a .pkg in build/export, `platforms` or `artifact` says which. Examples: {"dryRun":true}, {"artifact":"build/export/space-dodge.ipa"}, {"platforms":["macos"],"dryRun":true}. Details: docs_read {"name":"exporting"}.

| Argument | Type | Required | Description |
|---|---|---|---|
| `artifact` | string | no | The .ipa or .pkg to upload, relative to the project. A .pkg is the Mac App Store package (sign.macos distribution appStore writes build/export/<game-slug>-macos.pkg); anything else is an .ipa. Default: the .pkg if it exists and no .ipa does, else build/export/<game-slug>.ipa, else the newest .ipa in build/export. Xcode writes the .ipa (Product > Archive, Distribute App > App Store Connect > Export); `factoria export --platform ios` only writes the Xcode project. |
| `platforms` | array | no | Which build to upload when `artifact` does not say: ["ios"] the .ipa, ["macos"] the Mac App Store .pkg of sign.macos. Default: the one that exists. |
| `out` | string | no | Folder that holds the build, relative to the project (the `out` of project.export). Default: build/export. |
| `dryRun` | boolean | no | Write the build files into .factoria/publish/<store>/ and return the exact command line, what would be uploaded where and the warnings; start nothing and send nothing. A missing uploader, secret or id is a warning and the plan is still returned. Secrets are never in the result. Default false. |

### `publish.epic` (modifies state)

Since 0.2.0.

Upload the desktop exports to the Epic Games Store (BuildPatchTool UploadBinary, one artifact per platform).

Runs BuildPatchTool -mode=UploadBinary once per platform with -BuildRoot the export folder, -CloudDir under .factoria/publish/epic/cloud, -BuildVersion the game's version and -AppLaunch the game's executable. Needs factoria.json publish.epic {organizationId, productId, clientId, artifacts: {windows: <artifact id>, ...}}, BuildPatchTool (PATH, FACTORIA_BUILDPATCHTOOL, or publish.buildPatchTool of ~/.factoria/export.json) and the client secret in the environment variable FACTORIA_EPIC_CLIENT_SECRET: it is passed by name (-ClientSecretEnvVar), so it is never on a command line, in the result or in the log. Epic accepts each BuildVersion once per artifact: raise the version for every upload. The export's .factoria-export and AI_CONTENT_DISCLOSURE.md are not uploaded. Returns {store, dryRun, uploaded, version, tool, uploads[{platform, folder, destination, files, bytes, uploaded}], steps[{title, command, commandLine, files, ran, exitCode}], exitCode, log, warnings[], nextSteps[]}; a failed BuildPatchTool is an error whose data is that report. Examples: {"dryRun":true}, {"platforms":["windows"]}. Details: docs_read {"name":"exporting"}.

| Argument | Type | Required | Description |
|---|---|---|---|
| `platforms` | array | no | Which exports to upload: windows, macos, linux (aliases win, mac, osx also work). Default: every one that has an export folder and is set up for this store in factoria.json; the ones without are skipped with a warning. |
| `out` | string | no | Parent folder of the exports, relative to the project (the `out` of project.export). Default: build/export, where the exports are <game-slug>-<platform>. |
| `folders` | object | no | Upload another folder for a platform, relative to the project: {"windows": "dist/win"}. Takes precedence over `out`. |
| `dryRun` | boolean | no | Write the build files into .factoria/publish/<store>/ and return the exact command lines, what would be uploaded where and the warnings; start nothing and send nothing. A missing uploader, secret or id is a warning and the plan is still returned. Secrets are never in the result. Default false. |

### `publish.gog` (modifies state)

Since 0.2.0.

Upload the desktop exports to GOG (Galaxy Pipeline Builder build-game, one project file per platform).

Writes gog-<platform>.json (the Pipeline Builder project: the export folder as the depot, the game's executable as the primary task) into .factoria/publish/gog/ and runs `GOGGalaxyPipelineBuilder build-game <json> --ignore_list <file> --version <version>` once per platform. Needs factoria.json publish.gog {productId, clientId?, languages?}, Pipeline Builder (PATH, FACTORIA_GOG_PIPELINE_BUILDER, or publish.galaxyPipelineBuilder of ~/.factoria/export.json) and a sign-in: the credentials it cached, or FACTORIA_GOG_USERNAME and FACTORIA_GOG_PASSWORD (the password is then an argument of the process while it runs; it is redacted everywhere FactorIA shows anything). The upload is not published: do that in the GOG Developer Portal. The export's .factoria-export and AI_CONTENT_DISCLOSURE.md are not uploaded. Returns {store, dryRun, uploaded, version, tool, uploads[{platform, folder, destination, files, bytes, uploaded}], steps[{title, command, commandLine, files, ran, exitCode}], exitCode, log, warnings[], nextSteps[]}; a failed run is an error whose data is that report. Examples: {"dryRun":true}, {"platforms":["windows"],"branch":"testing"}. Details: docs_read {"name":"exporting"}.

| Argument | Type | Required | Description |
|---|---|---|---|
| `platforms` | array | no | Which exports to upload: windows, macos, linux (aliases win, mac, osx also work). Default: every one that has an export folder and is set up for this store in factoria.json; the ones without are skipped with a warning. |
| `out` | string | no | Parent folder of the exports, relative to the project (the `out` of project.export). Default: build/export, where the exports are <game-slug>-<platform>. |
| `folders` | object | no | Upload another folder for a platform, relative to the project: {"windows": "dist/win"}. Takes precedence over `out`. |
| `dryRun` | boolean | no | Write the build files into .factoria/publish/<store>/ and return the exact command lines, what would be uploaded where and the warnings; start nothing and send nothing. A missing uploader, secret or id is a warning and the plan is still returned. Secrets are never in the result. Default false. |
| `branch` | string | no | GOG branch to put the build on (Pipeline Builder --branch). Default: none, the build is only uploaded. 'master' is refused: Pipeline Builder cannot publish to it. |

### `publish.googleplay` (modifies state)

Since 0.2.0.

Upload the release Android App Bundle (.aab) to Google Play (fastlane supply).

Runs `fastlane supply --aab <aab> --track <track> --release_status <draft|completed> --package_name <id of factoria.json> --json_key <service account key>` on the bundle `factoria export --platform android --format aab --release` writes (build/export/<game-slug>-android/<game-slug>.aab), or on `artifact`. A bundle signed with the debug key (no export.android.signing keystore, or a -debug.aab) is refused: Google Play rejects it. Needs: id (the package name), optionally factoria.json publish.googleplay {track (default internal), releaseStatus (draft, the default, or completed), changelogs: {"en-US": "store/whats-new-en.txt"} (files of up to 500 characters, uploaded as the release notes)}, fastlane (PATH, FACTORIA_FASTLANE, or publish.fastlane of ~/.factoria/export.json), and a Google Cloud service account JSON key with access to the app in the Play Console: its path in FACTORIA_GOOGLEPLAY_JSON_KEY (SUPPLY_JSON_KEY also works); the key is never copied, written, shown or logged. The first bundle of a new app must be uploaded by hand in the Play Console; this command works from the second one. Returns {store, dryRun, uploaded, version, tool, uploads[{platform, folder, destination, files, bytes, uploaded}], steps[{title, command, commandLine, files, ran, exitCode}], exitCode, log, warnings[], nextSteps[]}; a failed fastlane is an error whose data is that report. Examples: {"dryRun":true}, {"track":"beta","releaseStatus":"completed"}. Details: docs_read {"name":"exporting"}.

| Argument | Type | Required | Description |
|---|---|---|---|
| `artifact` | string | no | The .aab to upload, relative to the project. Default: build/export/<game-slug>-android/<game-slug>.aab, which `factoria export --platform android --format aab --release` writes. |
| `out` | string | no | Folder that holds the build, relative to the project (the `out` of project.export). Default: build/export. |
| `dryRun` | boolean | no | Write the build files into .factoria/publish/<store>/ and return the exact command line, what would be uploaded where and the warnings; start nothing and send nothing. A missing uploader, secret or id is a warning and the plan is still returned. Secrets are never in the result. Default false. |
| `track` | string | no | Release track: internal, alpha, beta, production or the name of a closed testing track. Default: publish.googleplay.track, else internal. |
| `releaseStatus` | string ["draft","completed"] | no | draft: the release waits in the Play Console until you roll it out; completed: it rolls out at once. Default: publish.googleplay.releaseStatus, else draft. A new app that was never published accepts only draft. |

### `publish.itch` (modifies state)

Since 0.2.0.

Upload the desktop exports to itch.io (butler push, one channel per platform).

Runs `butler push <export folder> <user>/<game>:<channel> --userversion <version>` once per platform; the user/game comes from factoria.json publish.itch.game, the channel from publish.itch.channels (default windows, mac, linux) and the version from the game's version. Needs butler (PATH, FACTORIA_BUTLER, or publish.butler of ~/.factoria/export.json) signed in: run `butler login` once, or set BUTLER_API_KEY (never put it in the project). The export's .factoria-export and AI_CONTENT_DISCLOSURE.md are not uploaded. Returns {store, dryRun, uploaded, version, tool, uploads[{platform, folder, destination, files, bytes, uploaded}], steps[{title, command, commandLine, files, ran, exitCode}], exitCode, log, warnings[], nextSteps[]}; a failed butler is an error whose data is that report (platforms before it were uploaded). Examples: {"dryRun":true}, {"platforms":["windows","linux"]}. Details: docs_read {"name":"exporting"}.

| Argument | Type | Required | Description |
|---|---|---|---|
| `platforms` | array | no | Which exports to upload: windows, macos, linux (aliases win, mac, osx also work). Default: every one that has an export folder and is set up for this store in factoria.json; the ones without are skipped with a warning. |
| `out` | string | no | Parent folder of the exports, relative to the project (the `out` of project.export). Default: build/export, where the exports are <game-slug>-<platform>. |
| `folders` | object | no | Upload another folder for a platform, relative to the project: {"windows": "dist/win"}. Takes precedence over `out`. |
| `dryRun` | boolean | no | Write the build files into .factoria/publish/<store>/ and return the exact command lines, what would be uploaded where and the warnings; start nothing and send nothing. A missing uploader, secret or id is a warning and the plan is still returned. Secrets are never in the result. Default false. |

### `publish.microsoft` (modifies state)

Not released yet (on main after 0.2.0).

Upload the Windows MSIX package to the Microsoft Store (msstore publish).

Runs `msstore reconfigure --tenantId ... --sellerId ... --clientId ... --clientSecret ...` and then `msstore publish <folder of the msix> --inputFile <msix> --appId <product id> [--noCommit]` (the Microsoft Store Developer CLI) on the package `factoria export --platform windows --format msix` writes (build/export/<game-slug>-windows.msix), or on `artifact`. Upload it UNSIGNED: the Store signs it. Needs: the app reserved in Partner Center with its first submission made by hand, factoria.json publish.microsoft {productId} (Partner Center > your app > Product identity > Store ID, 12 characters) and export.windows.msix {identityName, publisher, publisherDisplayName} copied from the same page (a package with another identity is refused), msstore (PATH, FACTORIA_MSSTORE, or publish.msstore of ~/.factoria/export.json; it needs the .NET runtime) and the Partner Center credentials of an Azure AD application with the Manager role in the environment variables FACTORIA_MSSTORE_TENANT_ID, FACTORIA_MSSTORE_SELLER_ID, FACTORIA_MSSTORE_CLIENT_ID and FACTORIA_MSSTORE_CLIENT_SECRET (never factoria.json; the secret is redacted in every result and log; msstore keeps the credentials in its own settings after reconfigure). `releaseStatus` draft (the default) adds --noCommit, so the submission waits in Partner Center; completed submits it for certification. Every submission needs a higher "version" in factoria.json. Returns {store, dryRun, uploaded, version, tool, uploads[{platform, folder, destination, files, bytes, uploaded}], steps[{title, command, commandLine, files, ran, exitCode}], exitCode, log, warnings[], nextSteps[]}; a failed msstore is an error whose data is that report. Examples: {"dryRun":true}, {"releaseStatus":"completed"}. Details: docs_read {"name":"exporting"}.

| Argument | Type | Required | Description |
|---|---|---|---|
| `artifact` | string | no | The .msix to upload, relative to the project. Default: build/export/<game-slug>-windows.msix, which `factoria export --platform windows --format msix` writes. Upload it unsigned: the Store signs it. |
| `out` | string | no | Folder that holds the build, relative to the project (the `out` of project.export). Default: build/export. |
| `dryRun` | boolean | no | Write the build files into .factoria/publish/<store>/ and return the exact command line, what would be uploaded where and the warnings; start nothing and send nothing. A missing uploader, secret or id is a warning and the plan is still returned. Secrets are never in the result. Default false. |
| `releaseStatus` | string ["draft","completed"] | no | draft: msstore publish --noCommit, the submission is prepared in Partner Center and waits for you to submit it; completed: it is also submitted for certification. Default: draft. |

### `publish.steam` (modifies state)

Since 0.2.0.

Upload the desktop exports to Steam (steamcmd, one depot per platform).

Uploads the folders project.export wrote (build/export/<game-slug>-windows, -macos, -linux) as a SteamPipe build: writes app_build_<appid>.vdf and one depot_build_<depot>.vdf per platform (the content root is the export folder) into .factoria/publish/steam/ and runs `steamcmd +login <account> +run_app_build <vdf> +quit`. Needs: the game's app id in steam_appid.txt, factoria.json publish.steam {account, depots: {windows: <id>, ...}}, steamcmd (PATH, FACTORIA_STEAMCMD, or publish.steamcmd of ~/.factoria/export.json), and a steamcmd login done once by hand (it keeps the password and the Steam Guard approval; this command never takes or stores a password). `branch` sets the build live on a beta branch; the default branch is never touched. The build description is the game's name and its factoria.json version. The export's .factoria-export and AI_CONTENT_DISCLOSURE.md are not uploaded. Returns {store, dryRun, uploaded, version, tool, uploads[{platform, folder, destination, files, bytes, uploaded}], steps[{title, command, commandLine, files, ran, exitCode}], exitCode, log, warnings[], nextSteps[]}; a failed steamcmd is an error whose data is that report. Examples: {"dryRun":true}, {"platforms":["windows"],"branch":"beta"}. Details: docs_read {"name":"exporting"}.

| Argument | Type | Required | Description |
|---|---|---|---|
| `platforms` | array | no | Which exports to upload: windows, macos, linux (aliases win, mac, osx also work). Default: every one that has an export folder and is set up for this store in factoria.json; the ones without are skipped with a warning. |
| `out` | string | no | Parent folder of the exports, relative to the project (the `out` of project.export). Default: build/export, where the exports are <game-slug>-<platform>. |
| `folders` | object | no | Upload another folder for a platform, relative to the project: {"windows": "dist/win"}. Takes precedence over `out`. |
| `dryRun` | boolean | no | Write the build files into .factoria/publish/<store>/ and return the exact command lines, what would be uploaded where and the warnings; start nothing and send nothing. A missing uploader, secret or id is a warning and the plan is still returned. Secrets are never in the result. Default false. |
| `account` | string | no | Steam account that uploads (the builder account, with the 'Edit App Metadata' permission). Default: publish.steam.account of factoria.json. Its password is never stored: steamcmd keeps the login. |
| `appId` | integer | no | Steam app id. Default: the number in steam_appid.txt of the project (not 480, Valve's test app). |
| `branch` | string | no | Beta branch to set the build live on after the upload. Default: publish.steam.branch, else none. 'default' is refused: Steam sets that one by hand. |

## scene

### `scene.ascii_edit` (modifies state)

Since 0.2.0.

Edit the ASCII map of a level file (a scene.import_ascii args file) with operations instead of rewriting rows, then rebuild the level.

`file` is a project-relative JSON file holding scene.import_ascii arguments (at least `rows`; its legend is `legend` merged over `legendFrom`). `ops` run in order, all-or-nothing (an error names the op, e.g. ops[2], and nothing is written). Columns and rows are 0-based, row 0 = TOP, like import_ascii. Ops: {op:'fill', rect:[col,row,w,h], glyph}; {op:'replace', from, to, rect?} (whole map without rect); {op:'insertColumns', at, count, glyph?} (without glyph the new columns repeat the column left of `at` (column 0 when at = 0) with every glyph that spawns an object turned into '.', so the ground continues and nothing is duplicated); {op:'deleteColumns', at, count}; {op:'put', col, glyph, row} or {op:'put', col, glyph, above:h} = h rows above the ground of that column (1 = standing on it; ground = the topmost cell whose glyph is a tile in the file's tilemap.solidTiles, else the Tilemap of the scene the file builds). A glyph that is not '.', ' ' or in the legend is refused with suggestions. The edited `rows` are written back to `file` (one row per line, every other key and the key order kept). With `rebuild` (default true) and a `path` in the file, the level is then rebuilt exactly like `factoria call scene.import_ascii @file` and its result is merged into this one (`spawned` lists id, glyph and cell [col,row] of every object). `dryRun` writes nothing and returns the edited `rows` (and the import's dry run). Returns {file (written unless dryRun), width, height, ops (applied), changedCells (cells whose glyph changed; inserted/deleted columns count all their cells), dryRun, rows? (dryRun)} plus the import result when it ran (its `path` and `saved` name the scene file). Example: scene.ascii_edit {"file":"levels/1-1.json","ops":[{"op":"put","col":40,"glyph":"o","above":1},{"op":"insertColumns","at":60,"count":5}]}

| Argument | Type | Required | Description |
|---|---|---|---|
| `file` | string | yes | Project-relative JSON file with scene.import_ascii arguments (rows, legend/legendFrom, tilemap, path...). |
| `ops` | array | yes | Operations applied in order, all-or-nothing. fill {rect:[col,row,w,h], glyph}; replace {from, to, rect?}; insertColumns {at, count, glyph?}; deleteColumns {at, count}; put {col, glyph, row \| above}. 0-based, row 0 = top. |
| `rebuild` | boolean | no | Rebuild the level with scene.import_ascii on the edited file when it has a `path`. Default true. |
| `dryRun` | boolean | no | Write nothing; return the edited rows (and the import's dry run). Default false. |

### `scene.destroy` (modifies state)

Destroy an entity and its children.

Destruction is applied immediately when called outside a frame. Example: scene.destroy {"id":"coin_3"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `id` | string | yes | Entity id (or name). |

### `scene.format` (modifies state)

Rewrite scene and prefab files in the canonical compact layout, without loading them.

Parses every *.scene.json and *.prefab.json file and writes it back exactly as the engine writes scenes (2-space indent, short arrays of numbers and strings on one line, long ones wrapped at about 100 columns, a Tilemap's `tiles` one map row per line). Run it after editing scenes or prefabs by hand so diffs stay small and the maps stay readable. Only whitespace changes: values and key order are kept, and every file is read back and compared with the original data before it is written. Nothing is loaded into the running world, so nothing else changes (files that already have the canonical layout are not touched). `paths` lists files (names ending in .scene.json or .prefab.json) or folders (searched recursively), project-relative; without `paths` the command writes NOTHING and fails (code paths_required) saying how many files would change and the first ones; `all` true formats the whole project (skipping folders that start with '.', node_modules and a top-level build/). With `check` true nothing is written: the files that are not canonical are listed (the whole project when `paths` is absent; use it in CI or to review). A file that is not valid JSON is reported in `errors` with its file, line and column and skipped; the other files are still processed. Returns {formatted: [paths], unchanged: n, errors: [{file, line?, column?, message, hint?}], notes?}, or with `check`: {notCanonical: [paths], unchanged: n, errors, notes?}. With `check` and `strict` the command FAILS (error code not_canonical, the message lists the files, the hint says to run scene.format without `check`) when any file is not canonical: `factoria call` exits non-zero, so a CI step can gate on it. project.validate lists the non-canonical ones in one informational note (not a warning). Example: scene.format {"paths":["prefabs"],"check":true}

| Argument | Type | Required | Description |
|---|---|---|---|
| `paths` | array | no | Scene/prefab files or folders (recursive), project-relative. Needed to write: without it (and without all or check) the command fails and writes nothing. |
| `all` | boolean | no | true = format every *.scene.json and *.prefab.json of the project (instead of paths). Writing the whole project always takes this or paths. Default false. |
| `check` | boolean | no | true = write nothing, only list (notCanonical) the files whose layout differs from the canonical one (the whole project when paths is absent). Default false. |
| `strict` | boolean | no | With check: fail with error code not_canonical when any file is not canonical, instead of only listing it. Ignored without check. Default false. |

### `scene.get_entity`

Get one entity with every component field (including defaults and runtime values).

Accepts the entity id or its name. Example: scene.get_entity {"id":"player"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `id` | string | yes | Entity id (or name). |

### `scene.import_ascii` (modifies state)

Build a Tilemap level and the objects standing on it (coins, enemies, spawn points) from ASCII rows and a legend.

Author a tile level as text. `rows` is the map, one string per row, ONE CHARACTER PER TILE, row 0 = the TOP row (all rows the same length). `legend` maps each character to a tile index (integer) or to an object: {"tile"?: int, "prefab"?: "prefabs/x.prefab.json", "id"?: "player", "overrides"?: {component patches}, "offset"?: [dx, dy]}. '.' and ' ' are empty tiles unless the legend defines them. A glyph with a `tile` draws that tile; with a `prefab` it also spawns the prefab at the CENTRE of its cell (a glyph may have both; a prefab-only glyph leaves the tile empty). `overrides` patch the prefab's components per glyph; `offset` shifts the object (world units) from the cell centre. The tilemap is the entity `entity` (default "tilemap"): created when missing, updated when it exists; `tilemap` sets its Tilemap fields (tileset, tileSize, columns, solidTiles, color, layer; columns is optional: left at 0 it is derived from the tileset width / tileSize.x). Its position is the map's TOP-LEFT corner (+Y up, like Tilemap everywhere); pass `position` (+ `anchor`: top-left, bottom-left or center) to place it, e.g. anchor bottom-left at [0,0] puts the level's floor at y=0. Objects are ordinary top-level entities that save with the scene; ids are `id` from the legend (unique objects such as "player") or generated in row-major order as <prefab name>_<n> (coin_1, coin_2...); every object is tagged "tilemap:<entity>". With `replace` (default true) the objects of earlier imports into the same tilemap are destroyed first, so re-importing an edited map does not duplicate them. `legendFrom` names a JSON file with a legend shared by several maps (e.g. "levels/legend.json"); it is merged under `legend` (the map's own entry wins for a glyph) and its unused entries are not warned about. TWO WAYS TO USE IT. (1) With `path` it edits that scene FILE and nothing else: the file (or `from`, a base scene to start from; a missing `path` without `from` starts as an empty scene) is loaded into a scratch world, the map is imported into it and the result is written to `path` in the canonical layout of scene.save. The running world, audio, physics and scripts are not touched, so it is safe to call from a tool or a one-shot `factoria call` and the file can be rebuilt as often as needed. The file keeps PREFAB REFERENCES instead of expanding prefabs: each legend object is written as {"id", "prefab", "tags", "components": {the legend overrides + Transform.position}} and the prefab entries of the base scene stay as they are, so editing a prefab file changes every level without importing again and level files stay small (a scene loaded into the world still expands them). An entity that `edits` touches, or a base prefab entry without an `id`, is written expanded. `dryRun` writes nothing and returns the scene JSON in `scene`. `edits` (file mode only) patches components of that scene's entities right after the map is imported and before the write, e.g. the camera and sky colour of a base scene: {"<entity id>": {"<Component>": {field: value}}}, each entry exactly scene.set_component (a missing component is added, only the given fields change, and a value outside a field's range is refused; Script.props is replaced as a whole unless the edit has "$merge": true next to its fields, e.g. {"level": {"Script": {"$merge": true, "props": {"levelIndex": 3}}}}, which merges the given props into the current ones as an RFC 7386 JSON merge-patch: other props stay, null deletes one); a wrong entity, component or field fails the call naming it, with suggestions, and writes nothing. If the file has load errors the call fails instead of dropping them. (2) Without `path` it changes the RUNNING world (like scene.spawn); `save` then also writes the current scene file like scene.save, so it needs a scene you chose (--scene or scene.load): when the running scene is only the project's mainScene loaded by default, `save` is refused (error unsafe_save) instead of overwriting it. With `path`, `save` is ignored: the file is always written. Nothing is changed when an argument is wrong: errors name the row/column, the glyph, the legend and suggestions. Returns {tilemap, created, width, height, tileCount, spawned:[{id, prefab, glyph, cell:[col,row], position:[x,y]}], removed, tag, warnings, notes?, saved?} plus, with `path`, {path, from (the file it started from, null = empty scene), entityCount, dryRun, scene? (dryRun)}. Example: scene.import_ascii {"rows":["..........","...o..o...",".P......o.","##########"],"legend":{"#":0,"o":{"prefab":"prefabs/coin.prefab.json"},"P":{"prefab":"prefabs/player.prefab.json","id":"player"}},"tilemap":{"tileset":"assets/tiles.png","tileSize":[32,32],"solidTiles":[0]},"anchor":"bottom-left","position":[0,0],"path":"scenes/level1.scene.json","from":"levels/base.scene.json"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `rows` | array | yes | The map: one string per row, one character per tile, row 0 = TOP row, all rows the same length. |
| `legend` | object | no | Glyph -> tile index (integer, -1 = empty) or {tile?: int, rotate?: 0\|90\|180\|270 (clockwise), flipX?: bool, flipY?: bool, prefab?: 'prefabs/x.prefab.json', id?: 'player', overrides?: {Component: {fields}}, offset?: [dx, dy]}. '.' and ' ' mean empty unless defined here. |
| `legendFrom` | string | no | Project-relative JSON file with a SHARED legend (e.g. levels/legend.json: {"#": 0, "o": {"prefab": "prefabs/coin.prefab.json"}}), merged UNDER `legend`: the map's own entries win for the same glyph. Entries only the shared file defines are not warned about when unused. `legend` may then be omitted. |
| `tilemap` | object | no | Tilemap field values (tileset, tileSize, columns, solidTiles, color, layer) applied to the new or existing tilemap. The grid itself comes from rows/legend. |
| `entity` | string | no | Id of the tilemap entity: created if missing, updated if it exists. Default "tilemap". |
| `replace` | boolean | no | Destroy the objects spawned by earlier imports into this tilemap (tag tilemap:<entity>) first, so re-importing does not duplicate them. false keeps them. Default true. |
| `path` | string | no | File mode: project-relative scene file (e.g. scenes/level1.scene.json) to edit. It is loaded into a scratch world, the map is imported into it and it is written back; the running world is not touched. Does not exist yet (and no `from`): starts as an empty scene. Writable places only (not .factoria/ except .factoria/tmp/). |
| `from` | string | no | File mode (needs `path`): scene file to start from instead of `path`, e.g. a base scene with settings, camera and HUD but no map. `path` is then replaced by the result. Must exist. |
| `dryRun` | boolean | no | File mode (needs `path`): write nothing and return the resulting scene JSON in `scene`. Default false. |
| `edits` | object | no | File mode (needs `path`): {entity id: {Component: {field: value}}} applied to the scene after the map is imported and before it is written, each entry like scene.set_component (e.g. {"camera": {"Camera": {"clearColor": [0.5, 0.7, 0.9, 1]}}}). Add "$merge": true inside a component's entry to MERGE Script.props (RFC 7386: other props stay, null deletes a key) instead of replacing it: {"level": {"Script": {"$merge": true, "props": {"levelIndex": 3}}}}. A wrong entity/component/field fails and nothing is written. |
| `save` | boolean | no | Running-world mode: also write the current scene file (like scene.save). Refused when the running scene is only the default mainScene (no --scene, no scene.load): pass `path` instead. Ignored when `path` is given. Default false. |
| `position` | array | no | [x, y] (or [x, y, z]) world position of the map's anchor point. Default: a new tilemap sits at [0,0] (its top-left corner); an existing one stays where it is. |
| `anchor` | string ["top-left","bottom-left","center"] | no | Which point of the map is placed at `position` (assumes an unrotated map). Default top-left, the Tilemap entity's own origin. |

### `scene.list_entities`

List entities (id, name, tags, components) with optional filters.

Filters: name (substring, case-insensitive), tag (exact), component (name). limit defaults to 100. Use scene.get_entity for full data. Example: scene.list_entities {"tag":"enemy","limit":20}

| Argument | Type | Required | Description |
|---|---|---|---|
| `name` | string | no | Substring of the entity name or id. |
| `tag` | string | no | Only entities having this tag. |
| `component` | string | no | Only entities having this component, e.g. RigidBody2D. |
| `limit` | integer | no | Maximum entities returned. Default 100. |

### `scene.load` (modifies state)

Replace the running scene with a scene file.

Loads immediately (outside a frame) or at the end of the current frame. Like scene.reload it first re-reads script modules and factoria.json input actions that changed on disk and clears script errors. Load problems are returned in `messages`. Example: scene.load {"path":"scenes/level2.scene.json"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | Project-relative scene path. |

### `scene.reload` (modifies state)

Reload the current scene from disk (discards runtime changes).

Resets the world to the saved scene file. Also re-reads what changed on disk: script modules (and the modules importing them), factoria.json input actions, fixedHz and deadzone; script errors are cleared. Example: scene.reload {}

### `scene.remove_component` (modifies state)

Remove a component from an entity.

Transform and EntityInfo cannot be removed. Example: scene.remove_component {"id":"player","component":"Script"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `id` | string | yes |  |
| `component` | string | yes |  |

### `scene.save` (modifies state)

Save the running world to a scene file (current scene path by default).

Writes canonical scene JSON (only non-default fields, except settings.gravity2D and settings.gravity3D, which are always written so the file shows the gravity the level uses). Files inside .factoria/ belong to the engine and its tools: only the scratch folder .factoria/tmp/ may be written there (the same rule as fs.write and fs.delete). To change a scene FILE without touching the running world use scene.import_ascii with `path`. Example: scene.save {"path":"scenes/snapshot.scene.json"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `path` | string | no | Project-relative output path. Default: the current scene. |

### `scene.set_component` (modifies state)

Add a component to an entity (if missing) and set the given fields.

`fields` is a partial object; unspecified fields keep their value. A value outside a field's range (see api.components) is refused, and a bad field changes nothing: errors name the field, the allowed values and the range. A field with free-form JSON content (Script.props) is REPLACED as a whole by default; with `merge` true `fields` is an RFC 7386 JSON merge-patch instead: an object for such a field is merged into the current one recursively (keys you do not mention stay, a null value deletes the key), and a null for any other field resets it to its default. Example: scene.set_component {"id":"player","component":"Sprite","fields":{"color":"red"}}; change one prop and keep the rest: scene.set_component {"id":"level","component":"Script","fields":{"props":{"levelIndex":3,"oldProp":null}},"merge":true}

| Argument | Type | Required | Description |
|---|---|---|---|
| `id` | string | yes | Entity id (or name). |
| `component` | string | yes | Component name, e.g. Transform, Sprite, RigidBody2D. |
| `fields` | object | no | Field name -> value. |
| `merge` | boolean | no | true = read `fields` as an RFC 7386 JSON merge-patch: objects (Script.props) merge into the current value recursively, null deletes a key (or resets a plain field to its default). false = every given field is replaced as a whole. Default false. |

### `scene.set_parent` (modifies state)

Since 0.2.0.

Move an entity under another entity, or to the top level of the scene.

`parent` null or "" makes it a root. By default (`keepWorldTransform` true) the entity stays where it is on screen: its local Transform is recomputed for the new parent; with false the local Transform is kept, so the entity moves with the new parent. The entity becomes the LAST child of its new parent unless `index` says where: 0 = first; it counts the new parent's other children, so moving within the same parent works (index 0 on the last child makes it first); an index below 0 or above the number of other children is refused, and `index` needs a parent (top-level order is creation order). Scene files keep the order. A parent that is the entity itself or one of its children is refused (a cycle). Example: scene.set_parent {"id":"coin_3","parent":"chest"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `id` | string | yes | Entity id (or name) to move. |
| `parent` | any | no | New parent's id (or name); null or empty = top level. |
| `keepWorldTransform` | boolean | no | true = keep the world position, rotation and scale (the local Transform changes); false = keep the local Transform. Default true. |
| `index` | integer | no | Place among the new parent's other children (0 = first). Omitted = last. Needs a parent. |

### `scene.spawn` (modifies state)

Create an entity from entity JSON, or instantiate a prefab at a position.

Either pass entity JSON ({name, id?, tags?, components:{...}}) or {prefab, position?}. Optional parent id. Returns the created entity (with defaults) plus load messages. Example: scene.spawn {"name":"Coin","components":{"Transform":{"position":[100,50,0]},"Shape2D":{"shape":"circle","size":[20,20],"color":"gold"}}}  or  scene.spawn {"prefab":"prefabs/enemy.prefab.json","position":[300,0]}

| Argument | Type | Required | Description |
|---|---|---|---|
| `prefab` | string | no | Project-relative prefab path to instantiate. |
| `position` | array | no | [x, y] or [x, y, z] world position (Transform.position). |
| `entity` | object | no | Entity JSON; alternatively put its fields (name, components...) at top level. |
| `parent` | string | no | Parent entity id. |
| `index` | integer | no | Place among the parent's children (0 = first, up to their count). Omitted = last. Needs parent. |
| `overrides` | object | no | With prefab: patches for the prefab's children, keyed by child id, name or path (see docs/MENUS.md). |
| `name` | string | no |  |
| `id` | string | no |  |
| `tags` | array | no |  |
| `components` | object | no | Component name -> field object. |

## screen

### `screen.set_safe_area` (modifies state)

Since 0.2.0.

Pretend the device has a notch, rounded corners or system bars (a notched phone, headless).

The safe area is the part of the screen a notch, rounded corners and the system bars of a phone leave free; items with `safeArea: true` are anchored to it and screen.safeArea in scripts reports it. A real phone reports it by itself; a headless run, a test or the editor has none (the whole screen), so this sets one to check a layout: either a `profile` ("phone-portrait": notch at the top and home indicator at the bottom; "phone-landscape": notch on a side; "none"), as fractions of the design size, or insets in design pixels from each edge (`left`, `top`, `right`, `bottom`, default 0). Take a game.step and a game.screenshot to see the result. A windowed run on a phone overwrites it every frame with the device's real value. Example: screen.set_safe_area {"profile":"phone-portrait"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `profile` | string | no | none, phone-portrait or phone-landscape. Replaces left/top/right/bottom. |
| `left` | number | no | Design pixels covered at the left edge. Default 0. |
| `top` | number | no | Design pixels covered at the top edge. Default 0. |
| `right` | number | no | Design pixels covered at the right edge. Default 0. |
| `bottom` | number | no | Design pixels covered at the bottom edge. Default 0. |

## script

### `script.errors`

List script errors (load/runtime) and scene load problems.

Cleared by scene.load, scene.reload and script.reload. Example: script.errors {}

### `script.eval` (modifies state)

Evaluate JavaScript in the running game context (REPL) and return the value.

The last expression is returned as JSON. Example: script.eval {"code":"world.find('player').get('Transform').position"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `code` | string | yes | JavaScript source. |

### `script.reload` (modifies state)

Re-import script modules edited on disk and restart the behaviours (the world is kept).

scene.load and scene.reload already re-import every module whose file changed (by modification time) and clear the script errors; use this to do the same without reloading the scene (entity state is kept, onStart runs again), or with `force` to re-import every module even if no file changed. Example: script.reload {}

| Argument | Type | Required | Description |
|---|---|---|---|
| `force` | boolean | no | Re-import all modules, not only the changed ones. Default false. |

### `script.trace`

Since 0.2.0.

Debug scripts: run the game headless and record the stack, locals and watch expressions each time chosen lines run.

The way to find out WHY a script misbehaves without an IDE. Runs the project headless for `frames` fixed steps (a second engine in this process, fake platform, in-memory storage, fixed dt: the same input gives the same answer) with the scripts instrumented, and at each traced line records what is there instead of stopping. A point is {file, line, condition?, watch?, log?}: `file` a project-relative script, `line` a line that starts a statement (an error names the nearest ones when it does not), `condition` a JavaScript expression that must be true for the point to record, `watch` expressions evaluated at every hit, `log` a message with {expression} parts that turns the point into a logpoint (it writes into `logs` and records no hit; cheaper than a hit with locals). Returns {hits: [{point (index in points), frame (0-based fixed frame), file, line, function (e.g. Player.onUpdate), stack (innermost first, "fn file:line"), locals: {name: value}, watch: {expression: value}}], logs: [{frame, file, line, text}], errors (script errors raised during the run, scene problems, conditions that threw), framesRun, truncated}. Values are JSON: numbers, strings and booleans as such; objects are expanded `depth` levels (0 = a short preview string, 1 = the fields as JSON with nested objects as previews); an expression that throws gives "<error: ...>". After `maxHits` hits of a point it stops recording and `truncated` is true. A point in code that never runs gives no hits (check `scene` and `input`). Debugging slows the scripts 2-4x. See docs/DEBUGGING.md. Example: {"points":[{"file":"scripts/player.js","line":17,"condition":"dt > 0","watch":["this.body.velocity"]}],"frames":120,"maxHits":5}.

| Argument | Type | Required | Description |
|---|---|---|---|
| `points` | array | yes | The lines to trace. |
| `frames` | integer | no | How many fixed frames to run. Default 300. |
| `input` | string | no | Project-relative input replay JSON (a recorded session, play.report gives the path) applied during the run. |
| `scene` | string | no | Start scene (default: the project's mainScene). |
| `maxHits` | integer | no | Hits (or log lines) recorded per point; one more sets truncated and the point stops recording. Default 20. |
| `depth` | integer | no | How far objects in locals and watch are expanded into JSON (0 = previews only; nested objects beyond the depth are previews). An object shows at most 100 entries. Default 1. |

## setup

### `setup.install` (modifies state)

Since 0.1.4.

Install what an export needs: the Android JDK + SDK, the players of other platforms, CMake, the AppImage tools, sokol-shdc, the VS Code debugger extension, ffmpeg (or open Xcode's App Store page).

Downloads and installs one component into $FACTORIA_HOME (default ~/.factoria) and returns {component, changed, steps[], paths, nextSteps[], warnings[], seconds}; every step says whether it was installed or skipped because it was already there. It downloads hundreds of megabytes (setup.status says how many: installSizeMb) and can take minutes: ask the user before calling it. `android`: JDK 21 (Eclipse Temurin) and the Android SDK command-line tools, platform-tools, platform 36 and build-tools 35.0.0 (the SDK found on this computer is reused, except Unity Hub's), saved in ~/.factoria/export.json so `project.export` finds them. It REFUSES with error code `license_required` until acceptLicenses is true: the Android SDK license is a legal agreement between the user and Google, so show the user the text from setup.status (components[].licenses[].text) and set acceptLicenses ONLY after they have read it and said yes; never set it on your own. `players`: the factoria_player of the other desktop OSes plus the prebuilt mobile libraries, for exports to other platforms without building anything; from the GitHub release of this factoria's version (a development build ahead of the last release fails with code `no_release`); platforms narrows it (windows, linux, macos, mobile). `cmake`: CMake 3.31 from Kitware (macOS only, for iOS exports) unless 3.24+ is found; force installs it anyway. `xcode` (macOS): cannot be installed by a program: it opens Xcode's App Store page and returns the steps the user must do (some need their password). `appimage` (Linux x86_64): appimagetool 1.9.1 and the AppImage runtime from github.com/AppImage, about 16 MB, into $FACTORIA_HOME/tools/appimage. `shaders`: the pinned sokol-shdc (github.com/floooh/sokol-tools-bin, 8-12 MB depending on the computer) into $FACTORIA_HOME/tools/sokol-shdc/<commit>/, for source builds and editor-less setups; downloads of factoria carry it. `vscode`: copies the VS Code extension built into factoria (the script debugger, docs_read {"name":"debugging"}) to ~/.vscode/extensions/oxtailgames.factoria-<version>/ and to VS Code Insiders, VSCodium and Cursor when they exist, records the path of this factoria next to it and removes older versions; nothing is downloaded, so it is fast and safe to run without asking. `ffmpeg`: the static ffmpeg 6.0 build of github.com/eugeneware/ffmpeg-static (GPL, with libx264 and AAC; 19-28 MB depending on the computer) into $FACTORIA_HOME/tools/ffmpeg/<release>/, so `factoria run --record-video trailer.mp4` works without installing ffmpeg by hand; skipped when an ffmpeg is already found. Every download is checked against the publisher's checksum (error code `checksum_mismatch` installs nothing). Other error codes: network, cancelled, unsupported, invalid_argument, failed; the data of the error holds the steps done so far. Example: {"component":"android","acceptLicenses":true}.

| Argument | Type | Required | Description |
|---|---|---|---|
| `component` | string ["android","players","cmake","xcode","appimage","shaders","vscode","ffmpeg"] | yes | What to install: android (JDK + Android SDK), players (other platforms' factoria_player + mobile libraries), cmake (iOS export), xcode (guidance only), appimage (appimagetool + runtime for the Linux AppImage export; Linux x86_64 only), shaders (sokol-shdc, compiles custom materials), vscode (the script debugger extension for VS Code, Insiders, VSCodium and Cursor), ffmpeg (turns --record-video recordings into .mp4). |
| `acceptLicenses` | boolean | no | android: the user has read the Android SDK license (setup.status components[].licenses) and agreed to it. Without it the install refuses with license_required. Never set it without asking the user. Default false. |
| `platforms` | array | no | players: which players to install (default: every desktop OS but this one, plus the mobile libraries when this factoria has none next to it). "web" installs the web export's player (factoria_player.js + .wasm); every download carries it next to factoria, so it is only fetched when asked for. |
| `force` | boolean | no | android, cmake, players, ffmpeg: install again even when it is found (a JDK or CMake that is already there is used otherwise). Default false. |

### `setup.status`

Since 0.1.4.

Check what this computer has for exporting: the Android JDK and SDK, the players of other platforms, CMake, Xcode, the AppImage tools, sokol-shdc, the VS Code debugger extension, ffmpeg.

Returns {home, host, components[]}; each component is {id, title, state, details, paths, problems[], installSizeMb, licenses[], canInstall}. Components: `android` (JDK + Android SDK for APK/AAB exports), `players` (the factoria_player of the other desktop OSes and the prebuilt Android/iOS libraries, from the GitHub release of this factoria's version), `cmake` (3.24+, for the iOS export on a Mac), `xcode` (macOS: status only, it cannot be installed by a program) and `appimage` (appimagetool and the AppImage runtime, Linux x86_64 only: what `project.export` {platform: linux, format: appimage} builds an AppImage with) `shaders` (sokol-shdc, the shader compiler of custom materials: $SOKOL_SHDC, the one next to factoria or the pinned one under home/tools/sokol-shdc/) `vscode` (the FactorIA debugger extension in ~/.vscode/extensions and the other VS Code based editors' folders: installed when this factoria's version is there; docs_read {"name":"debugging"}) and `ffmpeg` (what `factoria run --record-video trailer.mp4` converts its recording to H.264 + AAC with: $FACTORIA_FFMPEG, "publish": {"ffmpeg"} of export.json, PATH or the one under home/tools/ffmpeg/). state is installed | missing | partial | unsupported (nothing to do on this computer). problems[] says what is missing and how to fix it; `setup.install` fixes everything except Xcode. `licenses` (android only, only while the Android SDK license is not accepted yet) holds {id, title, text}: the full license the user must read and agree to before `setup.install` with acceptLicenses. The only network request is the fetch of that license text (fetchLicenses false skips it). Everything installed lives under `home` ($FACTORIA_HOME, default ~/.factoria). Details: docs_read {"name":"exporting"}. Example: {"component":"android"}.

| Argument | Type | Required | Description |
|---|---|---|---|
| `component` | string ["android","players","cmake","xcode","appimage","shaders","vscode","ffmpeg"] | no | Only this component (default: all of them). |
| `fetchLicenses` | boolean | no | Download the Android SDK license text when the license is not accepted yet (a network request). false = skip it (a polling UI). Default true. |

## shader

### `shader.compile`

Since 0.2.0.

Compile a custom material's GLSL snippet for the dialects of some platforms and report errors with file, line and fixes.

Checks the material file (*.material.json, schemas/material.schema.json) and compiles its snippet with sokol-shdc, injected into the engine's mesh shader, for every shader dialect of the platforms asked (default: all six: hlsl5 for Windows, glsl430 for Linux, metal_macos, metal_ios and metal_sim for macOS and iOS, glsl300es for Android and web). Some errors exist in one dialect only (a gradient inside a loop is fine in GLSL and refused by HLSL), so compile for the platforms you ship. Returns {ok, material, dialects, errors: [{file, line, column, message, hint, source}], cached}: a snippet error is mapped to the line of your snippet, with the offending line in `source` and a fix in `hint` (an unknown field of Surface gets "did you mean albedo?", texture(waves, uv) gets the separate-sampler form); a mistake in the material file has a JSON `pointer` instead of a line. Fix the file and call again until ok, then look at the result with game.screenshot. Results are cached in .factoria/shader-cache by content, so an unchanged material compiles instantly. Needs sokol-shdc: the factoria downloads carry it next to factoria; otherwise `factoria setup shaders` installs it, or set SOKOL_SHDC. The snippet is GLSL 450 (Vulkan style) with no @ tags and no main: `void surface(in SurfaceInput i, inout Surface s)` is required, `void vertex(inout VertexData v)` optional. Params are globals named like the JSON keys; textures are sampled with texture(sampler2D(name, name_smp), uv); names starting with fa_ are the engine's. Example: {"material": "materials/water.material.json", "platforms": ["windows", "web"]}

| Argument | Type | Required | Description |
|---|---|---|---|
| `material` | string | yes | Project-relative path of the material, e.g. materials/water.material.json (the .material.json suffix may be left out). |
| `platforms` | array | no | Platforms whose shader dialects to compile for. Omit for all. |

## sign

### `sign.macos` (modifies state)

Since 0.2.0.

Sign, notarize and staple the exported macOS app (Developer ID), or sandbox and sign it as a .pkg for the Mac App Store.

Takes the app `project.export` wrote for macOS (build/export/<game-slug>-macos/<Name>.app) and makes it open on any Mac without Gatekeeper warnings: codesign of every native plugin library in Contents/Frameworks (deepest first) and then the app, with the hardened runtime and a secure timestamp (the export's <slug>.entitlements when `provisioningProfile` is given; the profile is embedded), codesign --verify --deep --strict, then `xcrun notarytool submit --wait` on a zip of the app (Apple's notary log is quoted when it refuses the app), `xcrun stapler staple`, spctl --assess, and finally a zip to share next to the export folder (<game-slug>-macos.zip). Needs a Mac (codesign, notarytool and stapler exist nowhere else): on another computer only `dryRun` works and a real run is an error that says so. `dryRun: true` checks everything and returns the exact command lines in steps[]. Identity: `identity` ("Developer ID Application: Your Name (TEAMID)"; `security find-identity -v -p codesigning` lists them), else FACTORIA_MACOS_SIGN_IDENTITY, else sign.macos.identity of ~/.factoria/export.json; "-" signs ad hoc (this Mac only, no notarization). Notarization logs in with the first of: a keychain profile (`keychainProfile`, FACTORIA_NOTARY_PROFILE, sign.macos.notaryProfile; saved once with `xcrun notarytool store-credentials`), an App Store Connect API key (`apiKey` file, `apiKeyId`, `apiIssuer`; or FACTORIA_NOTARY_API_KEY / _KEY_ID / _ISSUER), or an Apple ID (`appleId` + `teamId` or FACTORIA_APPLE_ID / FACTORIA_APPLE_TEAM_ID, and the app-specific password in FACTORIA_APPLE_APP_PASSWORD only). `distribution: "appStore"` prepares the Mac App Store submission instead: the app is sandboxed (com.apple.security.app-sandbox + the plugins' entitlements + export.macos.entitlements + the identifiers of the provisioning profile, which is required and embedded), signed with an "Apple Distribution" / "3rd Party Mac Developer Application" identity (`identity`, FACTORIA_MACOS_APPSTORE_IDENTITY or sign.macos.appStoreIdentity; "-" = a local ad hoc try of the sandbox), never notarized, wrapped by productbuild in <game-slug>-macos.pkg signed with `installerIdentity` (FACTORIA_MACOS_INSTALLER_IDENTITY or sign.macos.installerIdentity) and checked with pkgutil --check-signature; the result adds distribution, pkg, pkgSigned, installerIdentity, profile and the entitlements read back from the signature. publish.appstore uploads the .pkg. No password is ever an argument of this command, in factoria.json, in a result or in a log. `notarize` unset notarizes when there are credentials and a Developer ID identity (else only signs, with a warning); true makes missing credentials an error; false only signs. Returns {app, dryRun, identity, identityFrom, credentials, signed, verified, notarized, stapled, notarizationId, zip, distribution, [appStore: pkg, pkgSigned, installerIdentity, profile, entitlements], steps[{title, command, commandLine, ran, exitCode}], warnings[], nextSteps[]}. The export is replaced by the next project.export: sign again after every export. Details: docs_read {"name":"exporting"}. Examples: {"dryRun":true}, {"identity":"Developer ID Application: Ada Lovelace (ABCDE12345)","keychainProfile":"factoria-notary"}, {"identity":"-"}.

| Argument | Type | Required | Description |
|---|---|---|---|
| `app` | string | no | The .app to sign, relative to the project. Default: build/export/<game-slug>-macos/<Name>.app (the export of this game). |
| `out` | string | no | Parent folder of the export, relative to the project (the `out` of project.export). Default: build/export. |
| `identity` | string | no | The signing identity: the name of a 'Developer ID Application' certificate or its SHA-1 hash; "-" = ad hoc. Default: FACTORIA_MACOS_SIGN_IDENTITY, else sign.macos.identity of ~/.factoria/export.json. |
| `distribution` | string ["developerId","appStore"] | no | developerId = sign, notarize and zip for sharing outside the store; appStore = sandbox, sign for the Mac App Store and build the signed .pkg (needs provisioningProfile and installerIdentity, unless identity is "-"). Default "developerId". |
| `installerIdentity` | string | no | appStore: the '3rd Party Mac Developer Installer' / 'Mac Installer Distribution' certificate that signs the .pkg. Default: FACTORIA_MACOS_INSTALLER_IDENTITY, else sign.macos.installerIdentity of ~/.factoria/export.json. |
| `pkg` | string | no | appStore: where the .pkg goes, relative to the project. Default: next to the export folder, <game-slug>-macos.pkg. |
| `keychain` | string | no | A keychain file that holds the certificate (or the notary profile). Default: FACTORIA_MACOS_KEYCHAIN, else the user's keychains. |
| `provisioningProfile` | string | no | A .provisionprofile to embed in the app (needed for the capabilities the plugins ask for: Game Center, iCloud). With it the export's <slug>.entitlements are applied. Absolute path, or relative to the project. |
| `entitlements` | string | no | An entitlements file for the app. Default: the export's <slug>.entitlements, used only with a provisioningProfile. Absolute path, or relative to the project. |
| `notarize` | boolean | no | true = notarize (an error without a Developer ID identity and credentials); false = only sign; unset = notarize when credentials are found. |
| `keychainProfile` | string | no | notarytool keychain profile, saved with `xcrun notarytool store-credentials <name>`. Default: FACTORIA_NOTARY_PROFILE, else sign.macos.notaryProfile of ~/.factoria/export.json. |
| `apiKey` | string | no | App Store Connect API key file (AuthKey_<id>.p8), absolute or relative to the project. Default: FACTORIA_NOTARY_API_KEY. |
| `apiKeyId` | string | no | Key id of the API key. Default: FACTORIA_NOTARY_API_KEY_ID. |
| `apiIssuer` | string | no | Issuer id of a team API key (not needed for an individual key). Default: FACTORIA_NOTARY_API_ISSUER. |
| `appleId` | string | no | Apple ID for notarization. Default: FACTORIA_APPLE_ID (or APPLE_ID). The app-specific password is read from FACTORIA_APPLE_APP_PASSWORD only. |
| `teamId` | string | no | Apple Team ID (10 characters) for notarization with an Apple ID. Default: FACTORIA_APPLE_TEAM_ID (or APPLE_TEAM_ID). |
| `zip` | string | no | Where the zip to share goes, relative to the project. Default: next to the export folder, <game-slug>-macos.zip. |
| `dryRun` | boolean | no | Check everything and return the exact command lines in steps[]; sign and send nothing. Works on any computer. Default false. |

### `sign.windows` (modifies state)

Not released yet (on main after 0.2.0).

Sign the Windows MSIX package (and the exe) with a code-signing certificate, to install it outside the Microsoft Store.

Signs <out>/<game-slug>-windows.msix (what `project.export {"platform":"windows","format":"msix"}` writes) in place, and with `exe` the game's .exe of the export folder. A package for the Microsoft Store is uploaded UNSIGNED (Microsoft signs it), so this is for installing the package on a PC outside the Store (yours, a tester's) or for a game sold elsewhere. The certificate is a code-signing .pfx: `pfx`, else FACTORIA_WINDOWS_PFX, else sign.windows.pfx of ~/.factoria/export.json; its password ONLY in FACTORIA_WINDOWS_PFX_PASSWORD (never an argument, a file of the game, a result or a log). The subject of the certificate must equal the Publisher of the package (checked with openssl when it is installed). `testCertificate: true` (Windows) instead creates a self-signed certificate for the package's Publisher in your user certificate store, signs with it and saves the public part as <slug>-windows-test-certificate.cer: trust it once (Import-Certificate ... -CertStoreLocation Cert:\LocalMachine\TrustedPeople as Administrator) and `Add-AppxPackage -Path <the .msix>` installs the game (docs/EXPORTING.md, "Trying the package on your PC"). The tool: signtool.exe on Windows (FACTORIA_SIGNTOOL, else the newest Windows SDK, else PATH); osslsigncode on macOS and Linux (FACTORIA_OSSLSIGNCODE, else PATH; 2.9 or newer). Digest SHA-256 and an RFC 3161 time stamp (`timestampUrl`, default http://timestamp.digicert.com). `dryRun: true` checks everything and returns the exact command lines in steps[] on any computer. Returns {msix, exe, publisher, certificate, certificateFrom, tool, toolPath, timestampUrl, dryRun, signedMsix, signedExe, testCertificateFile, steps[{title, command, commandLine, ran, exitCode}], warnings[], nextSteps[]}. Signing again after every export is needed: the next project.export replaces the package. Examples: {"dryRun":true}, {"pfx":"C:/keys/code-signing.pfx"}, {"testCertificate":true}.

| Argument | Type | Required | Description |
|---|---|---|---|
| `msix` | string | no | The .msix to sign, relative to the project. Default: build/export/<game-slug>-windows.msix. |
| `out` | string | no | Parent folder of the export, relative to the project (the `out` of project.export). Default: build/export. |
| `exe` | boolean | no | Also sign the game's .exe in build/export/<game-slug>-windows/ (for a game shared as a folder or a zip). The package is not changed by it. Default false. |
| `pfx` | string | no | The code-signing certificate (.pfx), absolute or relative to the project. Default: FACTORIA_WINDOWS_PFX, else sign.windows.pfx of ~/.factoria/export.json. The password is read from FACTORIA_WINDOWS_PFX_PASSWORD only. |
| `testCertificate` | boolean | no | Windows only: create (or reuse) a self-signed certificate whose subject is the package's Publisher, sign with it and save its public part next to the package, to install the package on this PC. Default false. |
| `timestampUrl` | string | no | RFC 3161 time-stamp server. Default: http://timestamp.digicert.com. |
| `dryRun` | boolean | no | Check everything and return the exact command lines in steps[]; sign nothing. Works on any computer. Default false. |

## ui

### `ui.caption` (modifies state)

Since 0.2.0.

Show a subtitle line on the Captions component for a few seconds.

The same as `ui.caption(text, seconds, { key, speaker })` in a script: a line without a sound, drawn by the Captions component (docs/TEXT.md, "Captions") for `seconds` of the game clock; the newest Captions.maxLines lines show. With `key` (a localization key) the line is the translation and follows a language change. Without a Captions entity the line is only tracked and the log says so once. Example: ui.caption {"text":"Watch out!","seconds":2,"speaker":"Mara"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `text` | string | no | The line (the fallback when `key` is set and no string table has it). |
| `key` | string | no | Localization key of the line. |
| `speaker` | string | no | Name drawn before the line. |
| `seconds` | number | no | How long it shows, in game-clock seconds (default 3). |

### `ui.check_layout` (modifies state)

Since 0.2.0.

Load each screen in each language and text size and list every text that overflows its box, overlaps another text or leaves the screen.

For every scene (default: each scene with UI) and every case it loads the scene, switches the language, sets the text size, lets the scripts settle (a few frames) and reads ui.state. A text is reported when (1) `overflow`: it still does not fit its box at its effective size (the same test as ui.overflowed(id): after autoShrink and maxTextScale, see docs/TEXT.md), (2) `overlap`: two visible texts or labelled widgets (Text, Button, Toggle, Slider, TouchButton, neither the parent of the other) cover each other, or (3) `offscreen`: its rectangle leaves the screen. The cases are every language x every text scale, plus (with `pseudo`) a pseudo-localized pass in the default language where each translation is lengthened ("[" + vowels doubled + "]", at least 40 % longer) to show where an unknown, longer language would break. Returns {ok, checked: [{scene, cases}], skipped: [scenes with no UI], issueCount, issues: [{scene, kind, entity, path, key, text, rect, other?: {entity, path, key, text, rect}, cases: [{language, textScale, pseudo}]}]}: one issue per problem with every case where it happens, so the fix is to the widget (autoSize, autoShrink + minFontSize, maxWidth, a bigger box, a shorter string). Only texts with a localization `key` follow the language and the pseudo pass; a text a script writes is checked at each text scale only. It RELOADS scenes: afterwards the running scene is loaded again and the language, text size and pseudo mode are restored, but the game state is lost, so run it on a fresh game or session. Refused while a frame runs. The warnings, errors and scripts of each load behave as in scene.load. Example: ui.check_layout {"textScales":[1,2],"pseudo":true}

| Argument | Type | Required | Description |
|---|---|---|---|
| `scenes` | array | no | Project-relative scene paths to check, e.g. ["scenes/menu.scene.json"]. Default: every scene of the project that has UI (a widget or a screen-space Text). |
| `languages` | array | no | Languages to check, as in factoria.json localization.languages. Default: all of them (the current one when the game has no localization). |
| `textScales` | array | no | Text size options (ui.set_text_scale) to check. Default: [1, 2]. |
| `pseudo` | boolean | no | Also run the pseudo-localized pass (default language, every text scale). Default: true. |
| `settleFrames` | integer | no | Frames stepped after each change so scripts and layout settle. Default: 4. |

### `ui.clear_captions` (modifies state)

Since 0.2.0.

Remove every subtitle from the screen now.

The same as `ui.clearCaptions()` in a script. Sounds that have a caption keep playing. Example: ui.clear_captions {}

### `ui.set_slider` (modifies state)

Not released yet (on main after 0.2.0).

Set a Slider the way a drag does: clamped, snapped to step, and ui.change is sent.

For tests and tools (game.setSlider(id, value) in a test calls it). The slider takes focus, `value` is clamped to [min, max] and snapped to `step` exactly as dragging the track does, and the "ui.change" event {id, value} is sent when the number changed (not when it was already there). Writing Slider.value from a script sends no event: that is the difference. Needs an active, interactable Slider. Returns {id, value, changed}. Example: ui.set_slider {"id":"music_volume","value":0.5}

| Argument | Type | Required | Description |
|---|---|---|---|
| `id` | string | yes | Entity id (or name) of the Slider. |
| `value` | number | yes | The wanted value; clamped to [min, max] and snapped to step. |

### `ui.set_text_scale` (modifies state)

Since 0.2.0.

Set the text size option: screen-space Text and the labels of UI widgets get bigger or smaller.

The player's "text size" setting (accessibility), the same as `ui.textScale = value` in a script: the font size of every screen-space Text (space "screen") and of the labels of Button, Toggle, Slider and TextField is multiplied by `scale`, and so is what ui.measureText returns for them (space "screen", the default). World-space Text is part of the world and is not scaled, nor is its entity.bounds(). 1 is normal size; the range is 0.5 to 3. Wrapped text keeps its maxWidth and grows taller, and widgets keep their rectangles, so lay a menu out with room for the biggest size you offer. The engine does not save the option: the game stores it (storage) and sets it at start. Look at the result with game.screenshot. Example: ui.set_text_scale {"scale":1.5}

| Argument | Type | Required | Description |
|---|---|---|---|
| `scale` | number | yes | Text size multiplier: 1 = normal, 1.5 = 50% bigger, 0.5 = half. |

### `ui.speak` (modifies state)

Since 0.2.0.

Say a line aloud with the system's text to speech (or record it, headless).

The same as `ui.speak(text, { interrupt })` in a script: the line is said in the game's current language (i18n.language) with the system voice for it. `interrupt` (default true) stops what is being said first; false queues the line. Output only: it never changes the simulation. A system without speech (Linux without speech-dispatcher, Android without a speech engine) says nothing and `spoken` is false. Headless runs, tests and the editor say nothing and record the line (game.spoken() in tests). Example: ui.speak {"text":"Play"}

| Argument | Type | Required | Description |
|---|---|---|---|
| `text` | string | yes | What to say, already localized. |
| `interrupt` | boolean | no | Stop what is being said first (default true); false queues the line. |

### `ui.state`

Since 0.1.6.

List the UI widgets on screen (Panel, Button, Toggle, Slider, TextField, ScrollList, TouchStick, TouchButton, and screen-space Text) and which has focus.

Returns {focused, hovered, widgets: [{id, kind, rect: [x, y, w, h], focused, hovered, pressed, interactable, visible, value?, text?}]} in reading order (top to bottom, then left to right). Only widgets that are active in the hierarchy are listed. rect is in design pixels, top-left origin, +Y down: click a widget with game.input {"mouse": {"position": [x, y], "left": true}} or move the focus with the ui_up / ui_down / ui_left / ui_right and ui_submit actions (game.input {"press": ["ui_down"]}). `visible` is false when a ScrollList clips the widget away entirely, and for an on-screen gamepad control that is hidden (touchOnly while the player is not using touch). `value` is a Toggle's boolean, a Slider's number or a TouchStick's [x, y]; `pressed` of a TouchStick or TouchButton is a finger holding it (drive one with game.input {"touch": ...}); `text` is a Button's or TouchButton's text, a Toggle's or Slider's label or a TextField's contents. Screen-space Text entities (space "screen") follow the widgets as {id, kind: "Text", rect, text} (they are never focused or pressed; use it to check where HUD text is). `textScale` is the text size option (ui.set_text_scale). Example: ui.state {}

### `ui.stop_speaking` (modifies state)

Since 0.2.0.

Stop what is being said by ui.speak and drop the queued lines.

The same as `ui.stopSpeaking()` in a script. Does nothing when nothing is being said or the system has no speech. Example: ui.stop_speaking {}


## Scripting API (TypeScript declarations)

```ts
// Generated by `factoria api --dts`. Do not edit; regenerate after adding components or changing the engine.
// Declares the "factoria" and "factoria:test" modules used by gameplay scripts, tools and tests.

/**
 * Gameplay scripting API: behaviours, entities, world, input, audio, physics, math.
 */
declare module "factoria" {
  /**
   * Anything accepted where a 2D vector is expected: vec2(), {x, y} or [x, y].
   */
  export type Vec2Like = Vec2 | { x: number; y: number } | readonly [number, number];

  /**
   * Anything accepted where a 3D vector is expected (z defaults to unchanged/0).
   */
  export type Vec3Like = Vec3 | Vec2 | { x: number; y: number; z?: number } | readonly number[];

  /**
   * A color: color(), {r,g,b,a}, [r,g,b,a] (0..1) or "#rrggbb".
   */
  export type ColorLike = Color | { r: number; g: number; b: number; a?: number } | readonly number[] | string;

  /**
   * A rectangle {x, y, w, h}.
   */
  export type RectLike = Rect | { x: number; y: number; w: number; h: number } | readonly number[];

  /**
   * An entity, its id string, or null.
   */
  export type EntityLike = Entity | string | null;

  /**
   * A gamepad button (Xbox layout: A bottom, B right, X left, Y top; LeftThumb/RightThumb are the stick clicks). Names are case-insensitive at run time.
   */
  export type GamepadButton = "A" | "B" | "X" | "Y" | "Start" | "Back" | "Guide" | "DpadLeft" | "DpadRight" | "DpadUp" | "DpadDown" | "LeftShoulder" | "RightShoulder" | "LeftThumb" | "RightThumb";

  /**
   * A gamepad axis: sticks run -1..1 with +Y up, triggers 0..1.
   */
  export type GamepadAxis = "LeftX" | "LeftY" | "RightX" | "RightY" | "LeftTrigger" | "RightTrigger";

  /**
   * The family of a gamepad, found from its vendor id and name (Microsoft, Sony, Nintendo, Valve). It decides the button names input.buttonName() gives: the same bottom button is "A" on Xbox and Steam Deck, "Cross" on PlayStation and "B" on Nintendo. "generic" (any other pad) uses the Xbox names.
   */
  export type GamepadType = "generic" | "xbox" | "playstation" | "nintendo" | "steamdeck";

  /**
   * The kind of device that produced input last (input.lastDevice): choose keyboard or gamepad button prompts with it.
   */
  export type InputDevice = "keyboard" | "mouse" | "gamepad" | "touch";

  /**
   * Plain JSON data (objects, arrays, numbers, strings, booleans, null).
   */
  export type Json = any;

  /**
   * Shape swept by physics.shapeCast in 2D, centred on the cast position and axis-aligned. Sizes are full sizes in pixels, like Collider2D: { shape: "circle", radius: 8 } or { shape: "box", size: [16, 24] }.
   */
  export type CastShape2D = { shape: "circle"; radius: number } | { shape: "box"; size: Vec2Like };

  /**
   * Shape swept by physics.shapeCast in 3D, centred on the cast position and axis-aligned. Sizes are full sizes in meters, like Collider3D: { shape: "sphere", radius: 0.5 } or { shape: "box", size: [1, 2, 1] }.
   */
  export type CastShape3D = { shape: "sphere"; radius: number } | { shape: "box"; size: Vec3Like };

  /**
   * Options of world.spawn / world.spawnPrefab. rotation as a number = degrees around z. props are merged into Script.props. index is the place among the parent's children (0 = first, up to their count; omitted = last) and needs parent; a bad index throws.
   */
  export type SpawnOptions = { position?: Vec3Like; rotation?: number | Vec3Like; scale?: number | Vec3Like; parent?: Entity; index?: number; props?: Record<string, any> };

  /**
   * 2D vector value. Views returned by component fields (e.g. body.velocity) are live: writing .x/.y writes into the engine.
   */
  export class Vec2 {
    constructor(x?: number, y?: number);
    x: number;
    y: number;
    /**
     * v[0], v[1]...: the components in x, y, z order (also for the live view of a component field).
     */
    readonly [index: number]: number;
    /**
     * Iterates the components, so [...v], destructuring and for...of work.
     */
    [Symbol.iterator](): IterableIterator<number>;
    /**
     * Sets both components (writes through on live views).
     */
    set(x: number, y: number): this;
    /**
     * Copies another vector into this one.
     */
    copy(v: Vec2Like): this;
    /**
     * Component-wise sum (new vector).
     */
    add(v: Vec2Like): Vec2;
    /**
     * Component-wise difference.
     */
    sub(v: Vec2Like): Vec2;
    /**
     * Multiply by a vector (component-wise) or a scalar.
     */
    mul(v: Vec2Like | number): Vec2;
    /**
     * Multiply by a scalar.
     */
    scale(s: number): Vec2;
    /**
     * Divide by a vector or a scalar.
     */
    div(v: Vec2Like | number): Vec2;
    /**
     * Dot product.
     */
    dot(v: Vec2Like): number;
    /**
     * 2D cross product (z of the 3D cross).
     */
    cross(v: Vec2Like): number;
    /**
     * Euclidean length.
     */
    length(): number;
    /**
     * Squared length.
     */
    lengthSq(): number;
    /**
     * Unit vector (zero stays zero).
     */
    normalized(): Vec2;
    /**
     * Distance to another point.
     */
    distance(v: Vec2Like): number;
    /**
     * Linear interpolation.
     */
    lerp(v: Vec2Like, t: number): Vec2;
    /**
     * Plain copy (detaches a live view).
     */
    clone(): Vec2;
    /**
     * Approximate equality.
     */
    equals(v: Vec2Like, eps?: number): boolean;
    /**
     * Angle in degrees (atan2(y, x)).
     */
    angle(): number;
    /**
     * Rotated counter-clockwise by degrees.
     */
    rotated(deg: number): Vec2;
    toArray(): [number, number];
    toJSON(): [number, number];
    /**
     * Unit vector pointing at the angle (degrees).
     */
    static fromAngle(deg: number): Vec2;
    static readonly zero: Vec2;
    static readonly one: Vec2;
  }

  /**
   * 3D vector value (live view when it comes from a component field).
   */
  export class Vec3 {
    constructor(x?: number, y?: number, z?: number);
    x: number;
    y: number;
    z: number;
    /**
     * v[0], v[1]...: the components in x, y, z order (also for the live view of a component field).
     */
    readonly [index: number]: number;
    /**
     * Iterates the components, so [...v], destructuring and for...of work.
     */
    [Symbol.iterator](): IterableIterator<number>;
    /**
     * x and y as a Vec2.
     */
    readonly xy: Vec2;
    set(x: number, y: number, z: number): this;
    copy(v: Vec3Like): this;
    add(v: Vec3Like): Vec3;
    sub(v: Vec3Like): Vec3;
    mul(v: Vec3Like | number): Vec3;
    scale(s: number): Vec3;
    div(v: Vec3Like | number): Vec3;
    dot(v: Vec3Like): number;
    cross(v: Vec3Like): Vec3;
    length(): number;
    lengthSq(): number;
    normalized(): Vec3;
    distance(v: Vec3Like): number;
    lerp(v: Vec3Like, t: number): Vec3;
    clone(): Vec3;
    equals(v: Vec3Like, eps?: number): boolean;
    toArray(): [number, number, number];
    toJSON(): [number, number, number];
    static readonly zero: Vec3;
    static readonly one: Vec3;
    static readonly up: Vec3;
  }

  /**
   * RGBA color, components 0..1.
   */
  export class Color {
    constructor(r?: number, g?: number, b?: number, a?: number);
    r: number;
    g: number;
    b: number;
    a: number;
    /**
     * c[0]..c[3]: r, g, b, a.
     */
    readonly [index: number]: number;
    /**
     * Iterates the components, so [...v], destructuring and for...of work.
     */
    [Symbol.iterator](): IterableIterator<number>;
    /**
     * The number of components (4); Vec2 and Vec3 have the length() method instead.
     */
    readonly length: number;
    set(r: number, g: number, b: number, a?: number): this;
    copy(c: ColorLike): this;
    clone(): Color;
    withAlpha(a: number): Color;
    lerp(c: Color, t: number): Color;
    mul(c: Color | number): Color;
    equals(c: Color, eps?: number): boolean;
    toHex(): string;
    toArray(): [number, number, number, number];
    toJSON(): [number, number, number, number];
    /**
     * Parses "#rgb", "#rrggbb", "#rrggbbaa" or a color name.
     */
    static hex(s: string): Color;
    static readonly white: Color;
    static readonly black: Color;
    static readonly red: Color;
    static readonly green: Color;
    static readonly blue: Color;
    static readonly clear: Color;
  }

  /**
   * Axis-aligned rectangle; (x, y) is the minimum corner (the bottom-left in the +Y-up world), w and h the size. Entity.bounds() returns one.
   */
  export interface Rect {
    x: number;
    y: number;
    w: number;
    h: number;
    /**
     * r[0]..r[3]: x, y, w, h.
     */
    readonly [index: number]: number;
    /**
     * Iterates the components, so [...v], destructuring and for...of work.
     */
    [Symbol.iterator](): IterableIterator<number>;
    /**
     * The number of components (4); Vec2 and Vec3 have the length() method instead.
     */
    readonly length: number;
    contains(p: Vec2Like): boolean;
    toArray(): [number, number, number, number];
  }

  /**
   * Returned by this.after / this.every.
   */
  export interface TimerHandle {
    /**
     * Stops the timer.
     */
    cancel(): void;
    readonly active: boolean;
  }

  /**
   * Second argument of onCollisionEnter.
   */
  export interface CollisionInfo {
    /**
     * Contact point (Vec2 in 2D games).
     */
    point: Vec2 | Vec3;
    /**
     * Contact normal pointing from this entity toward the other.
     */
    normal: Vec2 | Vec3;
    /**
     * Approximate impact strength.
     */
    impulse: number;
  }

  /**
   * An entity handle. Properties read/write engine memory directly; using an entity after it was destroyed throws (check .alive).
   */
  export class Entity {
    /**
     * Stable unique id (assignable; keeps lookups consistent).
     */
    id: string;
    name: string;
    tags: string[];
    active: boolean;
    readonly activeInHierarchy: boolean;
    /**
     * False once the entity was destroyed.
     */
    readonly alive: boolean;
    /**
     * Transform view (position, rotation, scale).
     */
    readonly transform: Components["Transform"];
    /**
     * Shortcut for transform.position (live view; assignable with vec2/vec3/[x,y]).
     */
    position: Vec3;
    /**
     * World-space position (get/set).
     */
    worldPosition: Vec3;
    /**
     * Live view of a component, or null if the entity lacks it.
     */
    get<K extends keyof Components>(name: K): Components[K] | null;
    has(name: keyof Components): boolean;
    /**
     * Adds (or returns) a component and applies fields.
     */
    add<K extends keyof Components>(name: K, fields?: ComponentInit[K]): Components[K];
    /**
     * Patches component fields (adds the component if missing).
     */
    set<K extends keyof Components>(name: K, fields: ComponentInit[K]): Components[K];
    remove(name: keyof Components): boolean;
    /**
     * Names of the components on this entity.
     */
    components(): string[];
    /**
     * Destroys the entity (and children) at the end of the frame. It leaves physics at once: no collisions and no raycast or overlap hits from the call on.
     */
    destroy(): void;
    readonly parent: Entity | null;
    readonly children: Entity[];
    /**
     * Moves the entity under another one (null = top level). index is the place among the new parent's OTHER children (0 = first, up to their count; omitted = last), so it also reorders within the same parent. A parent is required for an index; a bad index throws. Layouts follow this order.
     */
    setParent(parent: EntityLike, keepWorld?: boolean, index?: number): void;
    hasTag(tag: string): boolean;
    addTag(tag: string): void;
    removeTag(tag: string): void;
    /**
     * The script instance attached to this entity (constructed as soon as the entity is spawned or its scene loaded), or null. Its own fields are reachable: game.find("p").behaviour.hp.
     */
    readonly behaviour: (Behaviour & Record<string, any>) | null;
    /**
     * Calls behaviour[method](...args) if it exists.
     */
    send(method: string, ...args: any[]): any;
    /**
     * World-space axis-aligned rectangle { x, y, w, h } of this entity's 2D visual, or null. (x, y) is the minimum corner, i.e. the BOTTOM-LEFT in the +Y-up world: the same Rect convention as physics.overlapBox and debug.rect. Tilemap: its size as drawn (rows form or width x height) times tileSize, from the top-left corner at the entity position. Sprite and Shape2D: size and pivot (a circle is its bounding square, a line its stroked segment; the outline thickness of other shapes is ignored). Text: the laid-out box (approximate when headless, like ui.measureText). Scale and rotation are applied (the box around the rotated corners) and several visuals give their union. null when the entity has no world-space 2D visual: none at all, an empty Tilemap, or only screen-space ones (space: "screen"). Children are not included. Example: const map = world.find("map").bounds();
     */
    bounds(): Rect | null;
    /**
     * Touching ground below (2D pixels tolerance, default 2; 3D meters, default 0.05).
     */
    isGrounded(tolerance?: number): boolean;
    /**
     * Entity JSON as in scene files.
     */
    toJSON(): Json;
    /**
     * Solid contact against the body in `direction` (the obstacle lies that way): isTouching(vec2(1, 0)) = wall on the right, vec2(0, 1) = ceiling. Triggers never count.
     */
    isTouching(direction: Vec3Like, tolerance?: number): boolean;
    /**
     * Immediately spawns `count` particles at this entity's ParticleEmitter (works with emitting = false). No-op with a warning when there is no renderer (headless).
     */
    emitBurst(count?: number): void;
    /**
     * Skeletal animation of this entity's Animator component (play, set, trigger, clips, events). Throws if the entity has no Animator; entity.get("Animator") answers null instead.
     */
    readonly animator: AnimatorAPI;
    /**
     * Playback of this entity's Video component (play, pause, stop, seek, time, duration, the "ended" event). Throws if the entity has no Video; entity.get("Video") answers null instead.
     */
    readonly video: VideoAPI;
  }

  /**
   * Base class of gameplay scripts. Export a subclass as the default export of a module in scripts/ and attach it with the Script component. Class fields are defaults overridable from Script.props.
   */
  export class Behaviour {
    /**
     * The owning entity.
     */
    readonly entity: Entity;
    readonly world: WorldAPI;
    /**
     * false skips update callbacks.
     */
    enabled: boolean;
    /**
     * Default false. While time.scale is 0 (game.paused) the engine calls onUpdate and onLateUpdate only on behaviours whose runWhilePaused is true, with the REAL frame time as dt (time.dt is 0 then; time.unscaledDt is the real one). Set it as a class field (`runWhilePaused = true;`) on pause menus and anything else that must react while gameplay is frozen. onFixedUpdate never runs while paused. ui events and world.on listeners are delivered either way.
     */
    runWhilePaused: boolean;
    /**
     * One-shot timer (scaled game time); cancelled automatically on destroy.
     */
    after(seconds: number, fn: () => void): TimerHandle;
    /**
     * Repeating timer.
     */
    every(seconds: number, fn: () => void): TimerHandle;
    /**
     * Subscribe to world events for this behaviour; returns unsubscribe.
     */
    on(name: string, fn: (data: any, source: Entity | null) => void): () => void;
    /**
     * Once, the first time the entity is active in the hierarchy (props already applied), before its first update and before the frame is drawn. The instance exists (entity.behaviour) from the moment the entity is spawned or its scene is loaded, active or not; an entity spawned inactive gets onStart when something sets active = true.
     */
    onStart?(): void;
    /**
     * Every time the entity becomes active in the hierarchy (it or an ancestor got active = true) while the Script is enabled; the first time it runs right after onStart. Runs before the frame is drawn, so a panel can refresh its texts here and they are right in the first drawn frame.
     */
    onEnable?(): void;
    /**
     * Every time the entity stops being active (it or an ancestor got active = false, or the Script was disabled), and before onDestroy of an entity that was active. Runs before the frame is drawn.
     */
    onDisable?(): void;
    /**
     * Every frame; dt in seconds scaled by time.scale.
     */
    onUpdate?(dt: number): void;
    /**
     * Every fixed step, before physics.
     */
    onFixedUpdate?(dt: number): void;
    /**
     * After all updates.
     */
    onLateUpdate?(dt: number): void;
    /**
     * Before the entity is removed.
     */
    onDestroy?(): void;
    onCollisionEnter?(other: Entity, info: CollisionInfo): void;
    onCollisionExit?(other: Entity): void;
    onTriggerEnter?(other: Entity): void;
    onTriggerExit?(other: Entity): void;
    /**
     * Any world.emit event.
     */
    onEvent?(name: string, data: any, source: Entity | null): void;
  }

  /**
   * Result of a raycast.
   */
  export interface RayHit<V = Vec2 | Vec3> {
    entity: Entity;
    point: V;
    normal: V;
    distance: number;
  }

  /**
   * Entity lookup, spawning and events.
   */
  export interface WorldAPI {
    /**
     * Finds by stable id first, then by name.
     */
    find(idOrName: string): Entity | null;
    findAll(name: string): Entity[];
    findByTag(tag: string): Entity[];
    /**
     * All alive entities in creation order.
     */
    entities(): Entity[];
    /**
     * Creates an entity from scene-file JSON ({ name, tags, components }). Vectors in component fields may be Vec2/Vec3, {x,y,z} objects or arrays (2D values get z = 0). The Script behaviour is constructed immediately (entity.behaviour), onStart runs before its first update.
     */
    spawn(entityJson: Json, opts?: SpawnOptions): Entity;
    /**
     * Instantiates a prefab file. `props` is merged into Script.props; `overrides` is entity JSON merged over the prefab (components deep-merge). `childOverrides` patches the prefab's descendants: key = a child's id, name or path like "Panel/Title", value = { name?, tags?, active?, components? }; an unknown child or field throws with a suggestion.
     */
    spawnPrefab(path: string, opts?: SpawnOptions & { overrides?: Json; childOverrides?: Record<string, Json> }): Entity;
    /**
     * Queue a game event; delivered to onEvent and world.on listeners.
     */
    emit(name: string, data?: any, source?: Entity): void;
    /**
     * Subscribe to an event; returns unsubscribe. The UI sends ui.click, ui.change, ui.submit, ui.focus and ui.cancel with data { id, value? } and the widget as `source` (ui.on wraps them).
     */
    on(name: string, fn: (data: any, source: Entity | null) => void): () => void;
    /**
     * Scene settings (gravity2D, ambientLight, ...).
     */
    readonly settings: Components["SceneSettings"];
    /**
     * Simulated seconds since the scene started.
     */
    readonly time: number;
    readonly frame: number;
  }

  /**
   * Mouse state (design-resolution pixels, top-left origin).
   */
  export interface MouseAPI {
    readonly position: Vec2;
    /**
     * Position in world coordinates through the main camera.
     */
    readonly world: Vec3;
    readonly delta: Vec2;
    readonly wheel: number;
    down(button?: "left" | "right" | "middle"): boolean;
    pressed(button?: "left" | "right" | "middle"): boolean;
    released(button?: "left" | "right" | "middle"): boolean;
    /**
     * Whether the mouse cursor is drawn over the window (default true). Set false for a game that draws its own cursor or plays with a pad. Independent of `locked`. A headless run or test only records the value.
     */
    visible: boolean;
    /**
     * Mouse lock for mouse-look cameras: the cursor is hidden and held in the window, `position` stays frozen and `delta` reports raw movement (not design pixels). The window system may unlock it when the window loses focus; the engine locks it again when focus comes back. A headless run or test only records the value.
     */
    locked: boolean;
  }

  export interface TouchInfo {
    id: number;
    position: Vec2;
    world: Vec3;
    pressed: boolean;
  }

  /**
   * One gamepad, from input.gamepad(index). Raw device state for local multiplayer; actions bound to Gamepad* names already match any pad.
   */
  export interface GamepadAPI {
    /**
     * A pad is plugged in at this index.
     */
    readonly connected: boolean;
    /**
     * The family of the pad: "xbox", "playstation", "nintendo", "steamdeck" or "generic" (also for a pad that is not connected). Found from its vendor id and name where the platform tells (Windows: XInput pads are xbox; Linux and macOS/iOS: from the ids or names; Android always "generic"). Use input.buttonName() to get the label, not this.
     */
    readonly type: GamepadType;
    /**
     * Button held. Unknown names throw with a suggestion.
     */
    down(button: GamepadButton): boolean;
    /**
     * Went down this frame.
     */
    pressed(button: GamepadButton): boolean;
    /**
     * Went up this frame (also when the pad was unplugged).
     */
    released(button: GamepadButton): boolean;
    /**
     * Stick -1..1 (+Y up) or trigger 0..1 with the deadzone applied, the same value the action bindings use (sticks: radial deadzone, the rest rescaled to the full range).
     */
    axis(axis: GamepadAxis): number;
    /**
     * The axis as the device reported it, without the deadzone.
     */
    rawAxis(axis: GamepadAxis): number;
  }

  /**
   * Input through named actions (factoria.json input.actions), raw keys or gamepads.
   */
  export interface InputAPI {
    /**
     * Action held. For an analog binding (gamepad stick or trigger) it means value >= 0.5. Unknown actions throw with a suggestion.
     */
    down(action: string): boolean;
    /**
     * Went down this frame.
     */
    pressed(action: string): boolean;
    released(action: string): boolean;
    /**
     * 0..1 strength of an action: 0 or 1 for keys, mouse, touch and pad buttons; for gamepad half-axis and trigger bindings the push after the deadzone (the maximum over the action's bindings). Unknown actions throw with a suggestion.
     */
    value(action: string): number;
    /**
     * -1..1 from two actions: value(positive) - value(negative). Analog with a gamepad stick bound to the actions; keys give exactly -1, 0 or 1.
     */
    axis(negative: string, positive: string): number;
    /**
     * 2D vector from four actions (+Y up), normalized only when longer than 1: a half-tilted stick gives a short vector, two keys a unit diagonal.
     */
    vector(left: string, right: string, down: string, up: string): Vec2;
    /**
     * Pad 0..3 (default 0); a bad index throws.
     */
    gamepad(index?: number): GamepadAPI;
    /**
     * Deadzone of gamepad sticks (radial) and triggers, 0 up to 1 (not included); factoria.json input.deadzone sets the start value (default 0.2). Assign to offer calibration in an options menu.
     */
    deadzone: number;
    /**
     * The characters typed this frame, as UTF-8 text ("" when none): from the keyboard or the on-screen keyboard, control characters left out. Append it to a text field's string; handle Backspace and Enter with input.keyPressed(). Desktop and iOS deliver composed text (shift, dead keys, IME). Android delivers what a key types in its layout (letters, digits, punctuation, accents through dead keys): a keyboard app that composes words or emoji (CJK input, emoji) cannot be received by a NativeActivity. docs/MOBILE.md lists the limits.
     */
    readonly text: string;
    /**
     * Shows (default) or hides the on-screen keyboard of phones and tablets while a text field has focus; its characters arrive in input.text. Desktop ignores it, a headless run only records it (input.keyboardShown). A text field does this by itself when it gets and loses focus.
     */
    showKeyboard(on?: boolean): void;
    /**
     * The last value given to showKeyboard() (false at start).
     */
    readonly keyboardShown: boolean;
    /**
     * True while the platform shows its own keyboard for the focused text field, because a native plugin took it (the Steam Deck's keyboard, through the Steam plugin); false otherwise. Only a gamepad player's focus can start it. The menu kit's on-screen keyboard stays closed while it is true. Read-only.
     */
    readonly platformKeyboard: boolean;
    /**
     * The system Back button or gesture of Android (nothing else sends it; a test sends it with game.pressBack()). Handlers run newest first at the start of the frame; the first one that does not return false consumes the press, so a handler that closes a menu returns true (or nothing) and one that has nothing to close returns false. When no handler consumes it, or there is none, the game quits, which is what Back did before this event existed. A handler that throws is reported and counts as consumed. Handlers end with the scene, like ui.on. Returns the function that removes the handler. Example: input.onBack(() => { if (!menu.open) return false; menu.close(); return true; });
     */
    onBack(handler: () => boolean | void): () => void;
    /**
     * One pulse of the vibration motor of a phone, seconds above 0 and up to 5 (default 0.1): 0.02 to 0.05 is a tap, 0.2 a buzz. iOS cannot pick a length: a short pulse is a haptic tap, a long one the system vibration; iPads have no motor. Android needs the VIBRATE permission, which the FactorIA Android template declares. A no-op on desktop; a headless run or test records the pulse (game.vibrations()). Throws for anything but a number in range.
     */
    vibrate(seconds?: number): void;
    /**
     * The names of all input actions (from factoria.json input.actions and the engine's own), sorted.
     */
    actions(): string[];
    /**
     * The bindings of an action in order, as names input.rebind() accepts: ["Space", "W", "GamepadA"]. An unknown action throws with a suggestion.
     */
    bindings(action: string): string[];
    /**
     * Replaces the bindings of an existing action, for a controls screen. Names are keys ("Space", "W", "Left"), "MouseLeft", "MouseRight", "MouseMiddle", "Touch" and gamepad bindings ("GamepadA", "GamepadLeftStickUp", "GamepadRightTrigger"...), case-insensitive. All or nothing: an unknown action or binding name throws an Error with "did you mean" and nothing changes. An empty array unbinds the action. Several actions may share a binding. Combine with input.lastPressed() to let the player press the new key, and save input.bindings(action) with storage.set() to restore it at the next start (see docs/SCRIPTING.md).
     */
    rebind(action: string, bindings: string[]): void;
    /**
     * Puts one action (or every action when no name is given) back to what factoria.json and the engine's defaults say, undoing input.rebind().
     */
    resetBindings(action?: string): void;
    /**
     * The binding that went down this frame ("Space", "MouseLeft", "Touch", "GamepadA", "GamepadLeftStickUp"...) or null: for a "press a key to rebind" screen. Sticks and triggers count when pushed past half way. If several went down in the same frame, keys come first, then touch, mouse buttons, pad buttons, sticks and triggers. Ignore the frame in which the player clicked the Rebind button itself.
     */
    lastPressed(): string | null;
    /**
     * The device that produced input last: "keyboard" (a key going down), "mouse" (moved, clicked, wheel), "gamepad" (a button pressed or a stick pushed past the deadzone) or "touch". "keyboard" at the start. Show gamepad prompts when it is "gamepad".
     */
    readonly lastDevice: InputDevice;
    /**
     * The label a player sees, for button prompts: a key gives its name ("Space", "W"), the mouse "Left Click", and a pad button the name on THAT pad (pad 0 by default): Xbox/Steam Deck "A" "B" "X" "Y" "LB" "RB" "LT" "RT" "View" "Menu", PlayStation "Cross" "Circle" "Square" "Triangle" "L1" "R1" "L2" "R2" "Create" "Options", Nintendo "B" "A" "Y" "X" "L" "R" "ZL" "ZR" "-" "+" (our A, the bottom button, is Nintendo's B). An action gives the label of its first binding for input.lastDevice (a pad binding after pad input, else a key or mouse binding), or "" if it has no binding. Unknown names throw with a suggestion.
     */
    buttonName(bindingOrAction: string, pad?: number): string;
    /**
     * Raw key by name ("Space", "A", "Escape"...).
     */
    keyDown(key: string): boolean;
    keyPressed(key: string): boolean;
    keyReleased(key: string): boolean;
    readonly mouse: MouseAPI;
    readonly touches: TouchInfo[];
  }

  export interface PlayOptions {
    volume?: number;
    pitch?: number;
    pan?: number;
    loop?: boolean;
    bus?: "sfx" | "music" | "ui";
    /**
     * A subtitle for this sound, plain text. It shows on the Captions component while the sound plays and goes when the sound ends or is stopped (audio.stop, audio.stopAll). With no Captions entity it is only tracked (game.captions() in tests). Use captionKey for a text that follows the language.
     */
    caption?: string;
    /**
     * Localization key of the subtitle (docs/LOCALIZATION.md): the line is the translation in the current language and changes with the language while it shows. `caption`, when also given, is the fallback for a key that no string table has.
     */
    captionKey?: string;
    /**
     * Name shown before the caption line in the Captions speakerColor, e.g. "Mara". Needs caption or captionKey.
     */
    speaker?: string;
    /**
     * Show the caption for this many seconds of the game clock instead of for as long as the sound plays. Required with loop: true (a looping sound never ends), otherwise play() throws.
     */
    captionSeconds?: number;
  }

  /**
   * Sound playback.
   */
  export interface AudioAPI {
    /**
     * Plays a clip, returns a voice id. With caption / captionKey the sound also shows a subtitle on the Captions component for as long as it plays (docs/TEXT.md, "Captions").
     */
    play(path: string, opts?: PlayOptions): number;
    stop(voice: number): void;
    stopAll(): void;
    /**
     * Starts looping background music.
     */
    music(path: string, opts?: { volume?: number; fade?: number }): void;
    stopMusic(fade?: number): void;
    /**
     * Volume multiplier of a bus (0 = silent, 1 = as recorded; default 1 for every bus). Plays go to "sfx" unless their `bus` option says otherwise; "master" scales everything. The setting is not saved: an options menu stores it (storage) and sets it again at start.
     */
    setVolume(bus: "master" | "sfx" | "music" | "ui", volume: number): void;
    /**
     * The volume last set for a bus with setVolume (1 when never set). Throws for an unknown bus name.
     */
    getVolume(bus: "master" | "sfx" | "music" | "ui"): number;
  }

  /**
   * Options of nav.findPath.
   */
  export interface NavPathOptions {
    /**
     * Agent radius of this query (meters). Default: the NavMesh3D's agentRadius. Larger than that is an error: bake a NavMesh3D for the bigger agent.
     */
    radius?: number;
    /**
     * How far (meters) a start or goal that is not on walkable ground is moved onto the nearest walkable cell (default agentRadius + 2 cells).
     */
    snap?: number;
    /**
     * When the goal cannot be reached, return a path to the reachable point nearest to it (complete = false) instead of found = false.
     */
    closest?: boolean;
    /**
     * Id of the entity with the NavMesh3D to use. Default: the first enabled one that contains `from`.
     */
    mesh?: string;
  }

  /**
   * Result of nav.findPath.
   */
  export interface NavPath {
    /**
     * true: `points` holds a path. false: `reason`, `message` and `hint` say why.
     */
    found: boolean;
    /**
     * Corners of the path from the start to the goal on the walkable surface (meters), few of them: walk straight from one to the next. Empty when not found.
     */
    points: Vec3[];
    /**
     * Meters along the points.
     */
    length: number;
    /**
     * false when only a path to the reachable point nearest the goal was returned (opts.closest).
     */
    complete: boolean;
    /**
     * Off-mesh links (NavLink3D) the path takes, in order: `point` is the index in `points` where the link starts (points[point + 1] is where it ends: jump or climb from one to the other, do not walk the straight line) and `entity` the id of the entity with the NavLink3D. Absent when the path takes none.
     */
    links?: { point: number; entity: string }[];
    /**
     * Id of the NavMesh3D entity that answered.
     */
    mesh: string;
    /**
     * Why there is no path: a point is not on walkable ground, or the two are in different walkable areas / a moving obstacle blocks the way or a moving platform (Collider3D.navWalkable) is away.
     */
    reason?: "start_off_mesh" | "goal_off_mesh" | "disconnected";
    /**
     * What is wrong, with numbers (nearest walkable point, areas, limits).
     */
    message?: string;
    /**
     * How to fix it.
     */
    hint?: string;
    /**
     * reason start_off_mesh / goal_off_mesh: the nearest walkable point.
     */
    nearest?: Vec3;
    /**
     * Meters from the point asked for to `nearest`.
     */
    nearestDistance?: number;
  }

  /**
   * Path finding on the baked NavMesh3D (docs/NAVIGATION.md). The mesh is baked from the static colliders when the scene loads.
   */
  export interface NavAPI {
    /**
     * Shortest walkable path between two 3D points (the agent's feet), as a few corner points on the ground: around walls, up ramps, never up a step higher than NavMesh3D.stepHeight. Never throws for 'no route': check `found` (off-mesh and disconnected results explain themselves in message / hint). Throws an Error that explains the fix when the scene has no NavMesh3D or opts.radius is bigger than the mesh was baked for. Deterministic. Example: const p = nav.findPath(this.entity.position, player.position, { radius: 0.3 }); if (p.found) this.target = p.points[1] ?? p.points[0];
     */
    findPath(from: Vec3 | { x: number; y: number; z: number } | readonly [number, number, number], to: Vec3Like, opts?: NavPathOptions): NavPath;
    /**
     * Bakes the NavMesh3D of entity `mesh` (default every enabled one) now and returns its stats. Needed only when autoBake is off; the colliders are re-baked by themselves otherwise.
     */
    bake(mesh?: string): { mesh: string; cellsX: number; cellsZ: number; cells: number; spans: number; walkableCells: number; regions: number; obstacles: number }[];
  }

  /**
   * Options of physics.raycast / raycast3d.
   */
  export interface RaycastOptions {
    /**
     * Layer mask the ray can hit (default all).
     */
    mask?: number;
    /**
     * Entity whose colliders (and its children's) are skipped; use the caster: { ignore: this.entity }.
     */
    ignore?: Entity | string;
    /**
     * Skip trigger colliders (default true); false hits them too.
     */
    ignoreTriggers?: boolean;
  }

  /**
   * Queries and direct body control. All vectors accept Vec2/Vec3, {x, y(, z)} objects and [x, y(, z)] arrays.
   */
  export interface PhysicsAPI {
    /**
     * 3D raycast between two points (when `from` has a z). A ray that starts inside a collider skips it. From a behaviour pass { ignore: this.entity }.
     */
    raycast(from: Vec3 | { x: number; y: number; z: number } | readonly [number, number, number], to: Vec3Like, opts?: RaycastOptions): RayHit<Vec3> | null;
    /**
     * 2D raycast between two points. A ray that starts inside a collider skips it. From a behaviour pass { ignore: this.entity } so it does not hit itself.
     */
    raycast(from: Vec2Like, to: Vec2Like, opts?: RaycastOptions): RayHit<Vec2> | null;
    /**
     * 3D raycast from an origin along a direction, at most maxDistance (default 1000) far.
     */
    raycast3d(origin: Vec3Like, dir: Vec3Like, maxDistance?: number, opts?: RaycastOptions): RayHit<Vec3> | null;
    /**
     * Sweeps a sphere or box from `from` to `to` (3D, when `from` has a z) and returns the first collider it touches: distance is how far the centre travels, point the contact point, normal the hit surface's normal (pointing back at the shape). Colliders the shape already overlaps at `from` are skipped, like a ray that starts inside one; a collider it only touches blocks the cast only if the shape moves towards it. Answers 'will this fit / how far can it go' for shapes where a ray is too thin. Same options as raycast; from a behaviour pass { ignore: this.entity }.
     */
    shapeCast(shape: CastShape3D, from: Vec3 | { x: number; y: number; z: number } | readonly [number, number, number], to: Vec3Like, opts?: RaycastOptions): RayHit<Vec3> | null;
    /**
     * Sweeps a circle or box from `from` to `to` (2D) and returns the first collider it touches: distance is how far the centre travels, point the contact point, normal the hit surface's normal (pointing back at the shape). Colliders the shape already overlaps at `from` are skipped, like a ray that starts inside one; a collider it only touches blocks the cast only if the shape moves towards it. Example: physics.shapeCast({ shape: "box", size: [16, 24] }, vec2(x, y), vec2(x, y - 40), { ignore: this.entity }). Throws an Error that explains the fix when the shape is wrong (misspelt name, "sphere" in 2D, missing size).
     */
    shapeCast(shape: CastShape2D, from: Vec2Like, to: Vec2Like, opts?: RaycastOptions): RayHit<Vec2> | null;
    /**
     * Entities whose 2D colliders (triggers included) overlap the circle.
     */
    overlapCircle(center: Vec2Like, radius: number, opts?: { mask?: number }): Entity[];
    /**
     * Entities whose 2D colliders (triggers included) overlap the rectangle.
     */
    overlapBox(rect: RectLike, opts?: { mask?: number }): Entity[];
    /**
     * Entities whose 3D colliders (triggers included) overlap the sphere.
     */
    overlapSphere(center: Vec3Like, radius: number, opts?: { mask?: number }): Entity[];
    /**
     * Instant change of momentum on a dynamic body (world units; 2D uses x, y).
     */
    applyImpulse(entity: Entity, v: Vec3Like): void;
    /**
     * Force applied to a dynamic body for the current step.
     */
    applyForce(entity: Entity, v: Vec3Like): void;
    /**
     * Sets a body's velocity (same as writing RigidBody.velocity).
     */
    setVelocity(entity: Entity, v: Vec3Like): void;
    /**
     * Moves an entity that has a CharacterController3D by `delta` metres with collide-and-slide: it slides along walls, climbs steps up to stepOffset, will not climb slopes steeper than slopeLimit, snaps down onto the ground, pushes dynamic bodies and is stopped by ceilings. Call it once per frame from onFixedUpdate with the walk of that frame (speed * time.fixedDt) plus your own gravity and jump (keep a vertical speed in the script and reset it when isGrounded). Throws an Error that explains the fix when the entity has no CharacterController3D.
     */
    moveCharacter(entity: Entity, delta: Vec3Like): CharacterMove;
  }

  /**
   * Result of physics.moveCharacter.
   */
  export interface CharacterMove {
    /**
     * World position of the entity after the move.
     */
    position: Vec3;
    /**
     * How far it actually moved (less than the delta when blocked).
     */
    moved: Vec3;
    /**
     * Standing on walkable ground (a slope not steeper than slopeLimit) after the move.
     */
    isGrounded: boolean;
    /**
     * Surface normal of that ground (zero when not grounded).
     */
    groundNormal: Vec3;
    /**
     * The entity it stands on, null in the air.
     */
    ground: Entity | null;
    /**
     * Blocked by a wall or a slope too steep to climb during this move.
     */
    hitWall: boolean;
    /**
     * Bumped its head on something above.
     */
    hitCeiling: boolean;
  }

  /**
   * Game clock.
   */
  export interface TimeAPI {
    /**
     * Seconds of the current frame (scaled).
     */
    readonly dt: number;
    readonly fixedDt: number;
    /**
     * Simulated seconds since scene start (fixed steps run so far x fixedDt); not affected by time.scale.
     */
    readonly elapsed: number;
    readonly frame: number;
    /**
     * Time scale for gameplay (>= 0, default 1): scales onUpdate/onFixedUpdate dt, timers, physics steps, particles and sprite animators. 0 freezes all of them (game.paused): only behaviours with runWhilePaused = true keep updating, and the UI keeps working. Audio is not scaled.
     */
    scale: number;
    /**
     * Seconds of the current frame, NOT scaled by time.scale (the real frame time while paused): animate pause menus with it.
     */
    readonly unscaledDt: number;
  }

  /**
   * Main camera helpers.
   */
  export interface CameraAPI {
    /**
     * The primary camera entity.
     */
    readonly main: Entity | null;
    worldToScreen(v: Vec3Like): Vec2;
    screenToWorld(v: Vec2Like, depth?: number): Vec3;
  }

  /**
   * Immediate-mode debug drawing (one frame).
   */
  export interface DebugAPI {
    line(a: Vec3Like, b: Vec3Like, color?: ColorLike): void;
    rect(x: number, y: number, w: number, h: number, color?: ColorLike): void;
    /**
     * Rect as { x, y, w, h } or [x, y, w, h].
     */
    rect(rect: RectLike, color?: ColorLike): void;
    circle(center: Vec2Like, radius: number, color?: ColorLike): void;
    text(screenPos: Vec2Like, text: string, color?: ColorLike): void;
    box(center: Vec3Like, size: Vec3Like, color?: ColorLike): void;
    sphere(center: Vec3Like, radius: number, color?: ColorLike): void;
  }

  export interface SceneAPI {
    /**
     * Reads a scene's files into memory ahead of time, a little every frame, and returns a handle at once: scene.load(path) of a preloaded scene reads nothing from the disk, so a loading screen can draw (and animate) while the next level loads. Reads the scene file and what it points at: prefabs, materials, textures, models (a .gltf brings its .bin and images), audio and fonts. Per frame the work is cut in whole files: four files per frame in tests, headless runs and replays (so the frames it takes never depend on how fast the machine is), as many as fit in a few milliseconds (at least one) in a game with a window. A scene path that does not exist throws with a did-you-mean list. Example: const job = scene.preload("scenes/level2.scene.json"); in onUpdate: bar.width = 400 * job.progress; if (job.done) scene.load("scenes/level2.scene.json"); or job.promise.then(() => scene.load(...)).
     */
    preload(path: string): PreloadHandle;
    /**
     * Deferred to the end of the frame.
     */
    load(path: string): void;
    reload(): void;
    readonly current: string;
  }

  /**
   * How far a notch, rounded corners and the system bars cover the screen from each edge, in design pixels.
   */
  export interface ScreenInsets {
    left: number;
    top: number;
    right: number;
    bottom: number;
  }

  /**
   * The screen as the player sees it, in design pixels with the origin at the top-left and +Y down (like screen-space Text and UI). On a phone the safe area is the screen minus the notch, rounded corners and the system bars; everywhere else (desktop, headless, tests without game.setSafeArea) it is the whole screen. It follows rotation. Give HUD items `safeArea: true` to anchor them to it without any script.
   */
  export interface ScreenAPI {
    /**
     * The design resolution (the same as game.screenSize).
     */
    readonly size: Vec2;
    /**
     * { left, top, right, bottom }: the distance in design pixels the notch, corners and bars cover from each edge. All 0 on a screen without cutouts.
     */
    readonly insets: ScreenInsets;
    /**
     * The part of the screen to keep text and buttons in, as a Rect { x, y, w, h } in design pixels: (x, y) is its TOP-LEFT corner and y grows downwards (unlike entity.bounds(), which is in the +Y-up world). Read it every frame or when needed: it changes when the phone rotates. Example: const a = screen.safeArea; button.position = [a.x + a.w - 20, a.y + 20];
     */
    readonly safeArea: Rect;
  }

  export interface GameAPI {
    quit(): void;
    /**
     * True while time.scale is 0. Setting it true sets time.scale to 0 (physics, particles, animators, timers and onUpdate stop; runWhilePaused behaviours and the UI keep running), false restores the time.scale it had when it was set true (1 if it was already 0). Setting time.scale while paused changes the scale to restore, the game stays paused.
     */
    paused: boolean;
    /**
     * The calendar date: year, month (1-12), day, weekday (0 = Sunday .. 6 = Saturday), utcOffsetMinutes (minutes east of UTC) and iso ("YYYY-MM-DD"). THE way to read the date: never use `Date`, whose wall clock makes a run differ from the next (like Math.random, see rng). A game with a window gets the player's real local date; `factoria test`, headless runs, `factoria call` and the MCP server get a fixed date, 2026-01-01 unless --date says another; a replay (--input) plays with the date it was recorded on. Tests set it with game.setDate("2026-10-23"). Example: const t = game.today(); rng.seed(t.year * 10000 + t.month * 100 + t.day); for a different challenge every day.
     */
    today(): { readonly year: number; readonly month: number; readonly day: number; readonly weekday: number; readonly utcOffsetMinutes: number; readonly iso: string };
    /**
     * True while the game's window has the keyboard focus (always true on a phone with the app in the foreground, in headless runs and in tests until game.blur()). Changes are announced by game.on("focus") and game.on("blur").
     */
    readonly focused: boolean;
    /**
     * Listens to the life of the app: "suspend" (the app goes to the background: the home button on a phone, a call), "resume" (it is back), "focus" and "blur" (the window gains or loses the focus; a desktop window that is covered does not suspend). The handler takes no arguments. Returns a function that stops listening. Listeners end with the scene, like world.on, so register them where the scene starts (a Behaviour's onStart). With factoria.json "pauseOnSuspend" (default true) the engine also freezes the game and the music while suspended: after the "suspend" handlers ran (a handler that opened your pause menu, game.paused = true, keeps its pause) and before the "resume" ones. Set "pauseOnSuspend": false to decide yourself. Example: game.on("suspend", () => pauseMenu.open());
     */
    on(event: "suspend" | "resume" | "focus" | "blur", fn: () => void): () => void;
    /**
     * factoria.json contents.
     */
    readonly project: Readonly<Json>;
    readonly screenSize: Vec2;
    /**
     * The third-party software inside the FactorIA runtime that every game ships (the parts whose full license texts `factoria export` writes to FACTORIA_NOTICES.txt next to the game), FactorIA first. Show it on a credits or licenses screen: e.g. game.notices().map((n) => `${n.name} (${n.license})`).
     */
    notices(): { name: string; url: string; license: string; usedFor: string }[];
    /**
     * The platform this runtime was built for. Menus use it for platform rules, e.g. phone and tablet apps have no Quit button (the system closes them).
     */
    readonly platform: "windows" | "macos" | "linux" | "ios" | "android" | "web";
    /**
     * The device the game runs on, to pick a graphics preset: formFactor (a phone and a tablet are told apart by the short side of the screen, 600 logical pixels), gpuBackend ("metal", "d3d11", "glcore", "gles3", "wgpu", "vulkan"; "headless" in headless runs and tests), memoryGB (physical memory, 0 when the platform cannot tell) and tier ("low", "medium" or "high", from the graphics backend and the memory: under 3.5 GB low, under 7.5 GB (5.5 on a phone or tablet) medium). Headless runs, tests and the editor always read { formFactor: "desktop", gpuBackend: "headless", memoryGB: 8, tier: "high" } so output never depends on the machine; tests change it with game.setDevice(). Example: const preset = { low: "performance", medium: "balanced", high: "quality" }[game.device.tier].
     */
    readonly device: Readonly<{ formFactor: "desktop" | "phone" | "tablet"; gpuBackend: string; memoryGB: number; tier: "low" | "medium" | "high" }>;
    /**
     * The player's operating system accessibility settings, to start your options screen from: textScale (the system text size, 1 = 100 %, between 0.5 and 4), reduceMotion (animations turned off or reduced), highContrast and screenReader (a screen reader or touch exploration is running). Read when the game starts and again when the window regains focus or the app resumes. The engine applies none of them: apply them to your own options on the first run and save the player's choice (docs/MENUS.md). Where a platform cannot tell, the value is 1 / false: macOS and the web have no text size, the web and Linux outside GNOME have no screen reader. Headless runs, tests and the editor always give { textScale: 1, reduceMotion: false, highContrast: false, screenReader: false }; tests change it with game.setAccessibility(). Example: const size = storage.get("textScale", game.accessibility.textScale).
     */
    readonly accessibility: Readonly<{ textScale: number; reduceMotion: boolean; highContrast: boolean; screenReader: boolean }>;
  }

  /**
   * A window size in logical pixels, from window.resolutions().
   */
  export interface Resolution {
    width: number;
    height: number;
  }

  /**
   * The game window, for an options menu: full screen, size, vsync and frame cap. The getters work in every run (a run without a window answers from factoria.json display settings). Every setter throws an Error that explains why when this run has no window (headless runs, tests, the MCP server, the editor's game view), so check `window.available` first. The engine saves nothing: keep the player's choice with storage.set() and apply it at start (docs/SCRIPTING.md has the recipe). Sizes are logical pixels: the window system's points, so a 1280 x 720 window on a 200% display has a 2560 x 1440 framebuffer. Phones and tablets always run full screen.
   */
  export interface WindowAPI {
    /**
     * True when the game owns a real window: `factoria run`, an exported game, the mobile players. False in headless runs, tests and inside the editor.
     */
    readonly available: boolean;
    /**
     * Whether the window is full screen (the project's display.fullscreen when there is no window; always true on phones and tablets).
     */
    readonly fullscreen: boolean;
    /**
     * Enters or leaves full screen (desktop: the window covers its monitor). `window.fullscreen` follows at once. On phones and tablets true does nothing and false throws ("phones and tablets always run full screen"). Throws without a window.
     */
    setFullscreen(on: boolean): void;
    /**
     * The window's client size in logical pixels (the project's display size when there is no window). In full screen it is the monitor's size.
     */
    readonly size: Vec2;
    /**
     * The size in logical pixels of the monitor the window is on (the whole screen on Linux with several monitors); the window size when the platform cannot tell.
     */
    readonly displaySize: Vec2;
    /**
     * Resizes the window's client area, in whole logical pixels from 160 to 16384; the window keeps its position. Desktop windows only, and not in full screen: call setFullscreen(false) first, or the call throws and says so. The game keeps its design resolution and letterboxes (or expands, see display.scaleMode) to the new size.
     */
    setSize(width: number, height: number): void;
    /**
     * Window sizes for a resolution picker: common 16:9 and 16:10 sizes (640x360 up to 3840x2160) plus the game's design size, keeping those that fit the monitor, smallest first. Pass an entry to setSize().
     */
    resolutions(): Resolution[];
    /**
     * Whether presents wait for the display (the project's display.vsync at start, then setVsync()).
     */
    readonly vsync: boolean;
    /**
     * Turns vsync on or off while the game runs (Windows, Linux; macOS only stops waiting for the display). Throws and names the platform where it cannot (phones and tablets, a Linux driver without swap control) or when there is no window.
     */
    setVsync(on: boolean): void;
    /**
     * Frames per second the window may draw at: 0 = unlimited (default), else a whole number from 15 to 1000. The game loop waits so frames do not start faster than that; the simulation still runs at the fixed step, so gameplay results do not change. Useful with vsync off, or to save battery on a laptop. Setting it throws without a window and on phones and tablets (the display sets the pace).
     */
    frameCap: number;
    /**
     * Resolution of the picture as a fraction of the window, from 0.5 to 1 (default 1). 0.5 draws a quarter of the pixels and scales the picture up: the cheapest graphics option on a weak phone. Works in every run with a renderer, headless tests included (game.screenshot then has that size); a run without graphics only remembers the value. A number outside 0.5 - 1 throws. The engine saves nothing: keep the player's choice with storage.set(). Example: window.renderScale = game.device.tier === "low" ? 0.6 : 1.
     */
    renderScale: number;
    /**
     * Whether this run can do `feature`, so an options menu hides what a phone, tablet or test cannot instead of catching the Error: frameCap, fullscreen and resize need a desktop window (window.available and game.device.formFactor "desktop"; their setters throw otherwise), renderScale works wherever the game runs. An unknown name throws with a "did you mean". Read window.supports("frameCap") before offering window.frameCap.
     */
    supports(feature: "frameCap" | "renderScale" | "fullscreen" | "resize"): boolean;
  }

  /**
   * Persistent JSON save data (<user dir>/storage.json). Tests and `--storage memory` runs use a throw-away in-memory object instead.
   */
  export interface StorageAPI {
    get<T = any>(key: string, fallback?: T): T;
    set(key: string, value: Json): void;
    remove(key: string): void;
    keys(): string[];
    clear(): void;
    /**
     * True when storage.json did not parse at the first use of storage in this run (a crash or a bad edit damaged it). The engine kept the damaged file as storage.corrupt.json in the save folder (storage.corrupt.2.json, .3... if one is already there; it never replaces one) and the game started with empty save data, so nothing is lost for good: a script can tell the player ("your save was damaged") or offer a recovery. Writes are atomic (temporary file, then rename), so a crash during a save leaves the previous file intact. False when the file was fine or missing, in memory runs and in tests (unless game.setStorageText gave a damaged text).
     */
    readonly corrupt: boolean;
  }

  /**
   * Deterministic random numbers (seeded per run). Math.random is routed here too.
   */
  export interface RngAPI {
    /**
     * [0, 1).
     */
    float(): number;
    range(min: number, max: number): number;
    /**
     * Inclusive.
     */
    int(min: number, max: number): number;
    chance(p?: number): boolean;
    pick<T>(items: readonly T[]): T | undefined;
    shuffle<T>(items: readonly T[]): T[];
    /**
     * Reseeds the deterministic world RNG (use from tools/tests for seed -> level determinism). The running game draws from this one RNG, so reseeding it changes the game's random sequence: a level generator should use rng.create(seed) instead.
     */
    seed(n: number): void;
    /**
     * Creates an independent, deterministic generator with the same methods as rng. It has its own state and never reads or changes the world RNG (or Math.random), so a tool can generate a level from a seed without disturbing the running game. Algorithm: mulberry32 (32-bit state, one step per draw). The algorithm and the draws each method consumes are STABLE across engine versions, so a stored seed keeps giving the same sequence. The seed is reduced to 32 bits (ToUint32: integer part, modulo 2^32); 0 is a valid seed. Throws for a non-number or non-finite seed. Example: const r = rng.create(7); r.int(1, 6).
     */
    create(seed: number): Rng;
  }

  /**
   * An independent seeded generator from rng.create(seed). Algorithm mulberry32, stable across engine versions: the same seed gives the same sequence on every platform. Every method draws a fixed number of 32-bit steps (float, range, int and chance: one per call; pick: one, none for an empty array; shuffle: items.length - 1), so a sequence does not depend on the arguments.
   */
  export interface Rng {
    /**
     * Next number in [0, 1): a 32-bit step divided by 2^32.
     */
    float(): number;
    /**
     * min + (max - min) * float(); in [min, max).
     */
    range(min: number, max: number): number;
    /**
     * Integer in [min, max], both inclusive (arguments are truncated to integers): min + floor(float() * (max - min + 1)). Returns min when max <= min (still one draw).
     */
    int(min: number, max: number): number;
    /**
     * True with probability p (default 0.5): float() < p.
     */
    chance(p?: number): boolean;
    /**
     * A random item (items[floor(float() * length)]), or undefined for an empty array.
     */
    pick<T>(items: readonly T[]): T | undefined;
    /**
     * A shuffled copy (Fisher-Yates from the end, j = floor(float() * (i + 1))); the input is not modified.
     */
    shuffle<T>(items: readonly T[]): T[];
    /**
     * Restarts this generator from seed n (same reduction as rng.create); the same as a new rng.create(n). Does not touch the world RNG.
     */
    seed(n: number): void;
  }

  export interface MathAPI {
    clamp(v: number, min: number, max: number): number;
    lerp(a: number, b: number, t: number): number;
    inverseLerp(a: number, b: number, v: number): number;
    remap(v: number, a0: number, a1: number, b0: number, b1: number): number;
    /**
     * Frame-rate independent smoothing.
     */
    damp(current: number, target: number, smoothing: number, dt: number): number;
    moveTowards(current: number, target: number, maxDelta: number): number;
    approach(current: number, target: number, maxDelta: number): number;
    sign(v: number): number;
    degToRad(deg: number): number;
    radToDeg(rad: number): number;
    /**
     * Wraps to (-180, 180].
     */
    wrapAngle(deg: number): number;
  }

  export interface CommandInfoJS {
    name: string;
    summary: string;
    description: string;
    inputSchema: Json;
    readOnly: boolean;
    category: string;
  }

  /**
   * Engine commands (the same ones MCP exposes).
   */
  export interface FaAPI {
    /**
     * Runs a command and returns its result. On failure it throws an Error with `code`, `hint` and, when the command reported structured details (for example a project tool's ToolError(message, hint, data)), `data`.
     */
    call(name: string, args?: Json): any;
    commands(): CommandInfoJS[];
  }

  /**
   * Throw from a tool's run() for an EXPECTED failure: the caller gets the message, the hint (how to fix) and optional structured data. Any other Error becomes a generic "failed" error.
   */
  export class ToolError extends Error {
    constructor(message: string, hint?: string, data?: Json);
    /**
     * How to fix it.
     */
    readonly hint: string;
    /**
     * Optional details (e.g. a report) delivered with the error.
     */
    readonly data?: Json;
  }

  /**
   * Particle helpers.
   */
  export interface ParticlesAPI {
    /**
     * Immediately spawns `count` particles at the entity's ParticleEmitter (works with emitting = false). No-op with a warning without a renderer.
     */
    burst(entity: Entity | string, count?: number): void;
  }

  /**
   * What a ui.on callback receives: one widget event (Button, Toggle, Slider, TextField).
   */
  export interface UiEvent {
    /**
     * Which event: click (Button pressed by ui_submit or the mouse), change (Toggle flipped, Slider moved, TextField edited), submit (TextField Enter), focus (a widget took focus), cancel (ui_cancel pressed: Escape or the pad's B).
     */
    readonly type: "click" | "change" | "submit" | "focus" | "cancel";
    /**
     * Id of the widget entity (the "id" of the scene entity). null for a cancel with nothing focused.
     */
    readonly id: string | null;
    /**
     * The widget entity; null for a cancel with nothing focused.
     */
    readonly entity: Entity | null;
    /**
     * change and submit only: the Toggle's value (boolean), the Slider's value (number) or the TextField's text (string).
     */
    readonly value?: boolean | number | string;
  }

  /**
   * Game UI: widget events, focus, text measurement. Widgets are the components Panel, Button, Toggle, Slider, TextField and ScrollList (see docs/SCRIPTING.md, UI); TouchStick and TouchButton, the on-screen gamepad, send no events: they press gamepad bindings (docs/MOBILE.md). The UI keeps working while time.scale is 0.
   */
  export interface UIAPI {
    /**
     * Size of `text` laid out exactly like Text rendering: shaped (ligatures, kerning, Arabic joining, bidi) and wrapped at maxWidth > 0 at spaces and between CJK characters. `space` (default "screen") says how it will be drawn: a "screen" label is measured at fontSize * ui.textScale, a "world" one is not scaled. Headless runs approximate 0.6 * fontSize per character (with a warning). maxTextScale, autoShrink, minFontSize and maxHeight are the fields of Text with the same names: the size is capped, and shrunk to fit maxWidth x maxHeight, exactly as a Text with them is drawn. `fontSize` in the result is the size it is laid out at, in pixels (fontSize times the capped text scale, or the shrunk size).
     */
    measureText(text: string, opts?: { fontSize?: number; font?: string; maxWidth?: number; space?: "screen" | "world"; maxTextScale?: number; autoShrink?: boolean; minFontSize?: number; maxHeight?: number }): { width: number; height: number; fontSize: number };
    /**
     * true when the text of a screen-space or world Text with a box (maxWidth, maxHeight) or the label of a Button, Toggle, Slider or TouchButton still does not fit its box at the size it is drawn at, i.e. after ui.textScale, maxTextScale and autoShrink (down to minFontSize) have done what they can. false for any other entity, an empty text or a Text without a box. Read it after game.step or ui.layout(). Same as `overflowed: true` in `ui.state`. Example: ui.textScale = 2; game.step(1); expect(ui.overflowed("play_button")).toBe(false);
     */
    overflowed(entityOrId: Entity | string): boolean;
    /**
     * Where a UI widget or a screen-space Text is drawn, as { x, y, w, h } in design pixels: (x, y) is the TOP-LEFT corner and y grows downwards (like screen.safeArea, unlike entity.bounds()). It includes the safe area and what a Panel or ScrollList laid out, so read it after game.step or ui.layout(). Takes an Entity or an id/name; null for an entity that is neither (a world-space sprite). Same numbers as the rect of `ui.state`. Example: const r = ui.rectOf("options.panel"); expect(r.x + r.w).toBeLessThan(1280);
     */
    rectOf(entityOrId: Entity | string): Rect | null;
    /**
     * Runs the UI layout now, exactly what every frame does: autoSize sizes, fit sizes, ScrollList fill, positions and the Panel fallbackLayout choice. After changing a label or a font size, call it and read Button.size, Panel.size or ui.rectOf right away, with no game.step. Throws when the run has no UI system. Example: button.get("Button").text = "A longer label"; ui.layout(); const w = ui.rectOf(button).w;
     */
    layout(): void;
    /**
     * The player's text size option, 0.5 to 3 (default 1): the font size of every screen-space Text (space "screen") and of the labels of Button, Toggle, Slider and TextField is multiplied by it, and ui.measureText (space "screen") agrees. World-space Text, and its entity.bounds(), are not scaled. Widgets keep their rectangles and wrapped text keeps its maxWidth, so leave room for the biggest size you offer. Setting a number outside 0.5 to 3 throws; clamp a saved value first. The engine does not save it: keep it in `storage` and set it at start. Resets to 1 for every test file. Same as the ui.set_text_scale command.
     */
    textScale: number;
    /**
     * Listens to a widget event from any widget. Returns the function that stops listening. Inside a behaviour prefer this.on("ui.click", (data, source) => ...), which is removed with the behaviour. An unknown type throws with a suggestion.
     */
    on(type: "click" | "change" | "submit" | "focus" | "cancel", fn: (e: UiEvent) => void): () => void;
    /**
     * Listens to a widget event from one widget only; `target` is the widget Entity or its entity id, e.g. ui.on("click", "play_button", () => scene.load("scenes/level1.scene.json")).
     */
    on(type: "click" | "change" | "submit" | "focus" | "cancel", target: Entity | string, fn: (e: UiEvent) => void): () => void;
    /**
     * Gives keyboard / gamepad focus to a Button, Toggle, Slider or TextField (null clears the focus) and sends ui.focus. Nothing takes focus by itself except a widget with autoFocus when none is focused, so call this when a menu opens. Throws, saying why and what to do, when the entity cannot take focus (not a focusable widget, inactive, interactable false).
     */
    focus(target: Entity | string | null): void;
    /**
     * Says `text` aloud with the system's text to speech (Windows SAPI, macOS/iOS AVSpeechSynthesizer, Android TextToSpeech, Linux speech-dispatcher, the browser's speechSynthesis), in the current language (i18n.language): the system voice for it when there is one. `interrupt` (default true) stops what is being said first; false queues the line after the ones before it. Speech is output only and never touches the simulation. Where the system has no speech (ui.speechAvailable is false) it does nothing and logs one warning per run. Headless runs and tests say nothing and record the line for game.spoken(). Pass an already localized string: ui.speak(i18n.t("menu.play")). Example: ui.on("focus", (e) => ui.speak(e.entity.get("Button").text)). Same as the ui.speak command.
     */
    speak(text: string, opts?: { interrupt?: boolean }): void;
    /**
     * Shows a subtitle line on the Captions component for `seconds` (default 3) of the game clock, for dialogue or hints that have no sound file; a sound's own subtitle is audio.play(path, { caption }). With `key` (a localization key) the line is the translation and follows a language change while it shows; `text` is then the fallback and may be "". `speaker` is a name drawn before the line. The newest Captions.maxLines lines show, the oldest drop first. Without a Captions entity the line is only tracked and the log says so once. Same as the ui.caption command. Example: ui.caption("Watch out!", 2, { speaker: "Mara" }).
     */
    caption(text: string, seconds?: number, opts?: { key?: string; speaker?: string }): void;
    /**
     * Removes every caption now, also the ones of sounds that still play (the sounds are not stopped). Same as the ui.clear_captions command.
     */
    clearCaptions(): void;
    /**
     * Stops what is being said and drops the queued lines. Does nothing when nothing is being said or the system has no speech. Same as the ui.stop_speaking command.
     */
    stopSpeaking(): void;
    /**
     * True when the system can speak. False on a Linux without speech-dispatcher (libspeechd.so.2) or an Android without a speech engine: hide your "read menus aloud" option then. Headless runs and tests report true because they record what would be said (game.spoken()).
     */
    readonly speechAvailable: boolean;
    /**
     * The widget that has keyboard / gamepad focus, or null.
     */
    readonly focused: Entity | null;
    /**
     * The widget under the mouse pointer (the top-most visible interactable one), or null. Check it in game code so a click meant for a button does not also shoot.
     */
    readonly hovered: Entity | null;
  }

  /**
   * Progress of scene.preload / assets.preload. Values change between frames only, never in the middle of your code. The files stay in memory through the first two scene loads after the job finishes (a load reads none of them from the disk); release() frees them earlier.
   */
  export interface PreloadHandle {
    /**
     * How much of the work is done, 0..1: whole files read over the files to read (the scene file counts as one). Never goes down, 1 when done.
     */
    readonly progress: number;
    /**
     * True once every file is read, or the job failed (then error says why).
     */
    readonly done: boolean;
    /**
     * Files read so far.
     */
    readonly files: number;
    /**
     * Bytes read so far.
     */
    readonly bytes: number;
    /**
     * Why the job failed (a file could not be read, the scene is not valid JSON), or an empty string.
     */
    readonly error: string;
    /**
     * Resolves with the totals when everything is read; rejects with an Error (message + hint) when the job fails or is released first.
     */
    readonly promise: Promise<{ files: number; bytes: number }>;
    /**
     * Stops a job that is still running and drops the files nobody has read yet (they would be read from the disk again). Optional: the files leave memory by themselves after the second scene load that follows the job.
     */
    release(): void;
  }

  /**
   * Asset queries.
   */
  export interface AssetsAPI {
    /**
     * Reads the files ahead of time like scene.preload does (models with their buffers and textures, images, audio, fonts, prefabs, materials), for assets a script will use later: the next read of each file, by the renderer or by audio, takes it from memory. A path that does not exist throws with a did-you-mean list; the list must not be empty. Example: assets.preload(["assets/boss.glb", "assets/boss_theme.ogg"]).promise.then(() => spawnBoss()).
     */
    preload(paths: string[]): PreloadHandle;
    /**
     * Pixel size of the texture file at the project-relative `path`, e.g. assets.textureSize("assets/hero.png"). This is the size a Sprite without `size` or `region` is drawn at and that entity.bounds() uses. A missing or unreadable file gives 32 x 32, the size of the missing-texture checker. Cached per file and modification time, so it is cheap to call every frame. Works headless (it reads the file, not the GPU texture). Throws for an empty or non-string path.
     */
    textureSize(path: string): { width: number; height: number };
  }

  /**
   * A group of platform functions a backend may or may not offer; platform.has(service) tells. The functions of a missing service reject with code "unavailable".
   */
  export type PlatformService = "achievements" | "stats" | "leaderboards" | "cloudSave" | "purchases" | "overlay" | "presence" | "integrity" | "ads";

  /**
   * Who is signed in to the store.
   */
  export interface PlatformPlayer {
    /**
     * The store's id of the player ("" when nobody is signed in).
     */
    readonly id: string;
    /**
     * The player's display name.
     */
    readonly name: string;
    /**
     * False when nobody is signed in: calls then reject with code "notSignedIn".
     */
    readonly signedIn: boolean;
  }

  /**
   * The outcome of a purchase, from purchases.buy() or the "purchase" event.
   */
  export interface PlatformPurchase {
    /**
     * revoked (only in a "purchase" event): the store took the purchase back (a refund): take the goods away. purchased: paid, deliver the goods and call purchases.finish(transactionId). pending: waiting for approval (Ask to Buy, a slow payment): a "purchase" event follows when it is decided. cancelled: the player backed out (not an error).
     */
    readonly status: "purchased" | "pending" | "cancelled" | "revoked";
    /**
     * The catalog id of the product (as in factoria.json platform.products).
     */
    readonly productId: string;
    /**
     * Only when purchased: pass it to purchases.finish() once the goods are delivered.
     */
    readonly transactionId?: string;
    /**
     * Only when purchased: the store's proof of purchase, for a server that wants to verify it.
     */
    readonly receipt?: string;
  }

  /**
   * A product as the store shows it.
   */
  export interface PlatformProduct {
    /**
     * The catalog id.
     */
    readonly id: string;
    /**
     * The title in the current language: the catalog's titleKey translated (else title) on the fake backend; a real store answers its own, localized by its console.
     */
    readonly title: string;
    /**
     * The store's description.
     */
    readonly description: string;
    /**
     * The price formatted for the player's country ("$0.99"): show it as it is.
     */
    readonly price: string;
    /**
     * The price as a number.
     */
    readonly priceValue: number;
    /**
     * ISO currency code ("USD").
     */
    readonly currency: string;
    /**
     * The catalog's product type.
     */
    readonly type: "consumable" | "nonConsumable" | "subscription";
  }

  /**
   * One row of a leaderboard.
   */
  export interface PlatformLeaderboardEntry {
    /**
     * 1 is the best.
     */
    readonly rank: number;
    /**
     * The player's display name.
     */
    readonly name: string;
    /**
     * The score.
     */
    readonly score: number;
    /**
     * The store's id of the player.
     */
    readonly playerId: string;
    /**
     * True for the signed-in player's own row.
     */
    readonly isPlayer: boolean;
  }

  /**
   * Achievements of factoria.json platform.achievements.
   */
  export interface PlatformAchievementsAPI {
    /**
     * Unlocks an achievement; `newly` is false when it already was. An id the catalog does not declare throws at once with a suggestion.
     */
    unlock(id: string): Promise<{ id: string; unlocked: true; newly: boolean }>;
    /**
     * Reports progress from 0 to 1 toward an achievement; 1 unlocks it. Progress never goes down.
     */
    progress(id: string, fraction: number): Promise<{ id: string; progress: number; unlocked: boolean }>;
    /**
     * The state of every achievement of the catalog, with its name and description in the current language (the catalog's nameKey / descriptionKey translated, else name / description; a store that answers its own texts wins).
     */
    list(): Promise<{ id: string; name: string; description: string; unlocked: boolean; progress: number }[]>;
    /**
     * Development only: locks every achievement again (the fake backend; real stores usually refuse).
     */
    reset(): Promise<void>;
  }

  /**
   * Numbers the store keeps for the player (factoria.json platform.stats).
   */
  export interface PlatformStatsAPI {
    /**
     * The stat's value (0 when never set).
     */
    get(id: string): Promise<number>;
    /**
     * Sets the stat and resolves with the stored value. An int stat needs a whole number.
     */
    set(id: string, value: number): Promise<number>;
    /**
     * get() then set(): resolves with the new value. Not atomic: two adds in flight can lose one.
     */
    add(id: string, delta: number): Promise<number>;
  }

  /**
   * Leaderboards of factoria.json platform.leaderboards. A board with "period": "daily" or "weekly" starts over with each calendar day or week of game.today(): submit and entries always address the current one (the fake keeps one per period; Steam makes one board per period, Game Center and Play Games use their own time scopes: docs/PLATFORM.md, "Leaderboard periods"; each store starts a period at its own time).
   */
  export interface PlatformLeaderboardsAPI {
    /**
     * Submits a whole-number score (a time in milliseconds, not seconds); `best` is the player's best afterwards. The leaderboard's order decides what better means. `periodStart` and `periodEnd` (ISO 8601 UTC text) are there when the store says when the board's period runs.
     */
    submit(id: string, score: number): Promise<{ id: string; score: number; best: number; periodStart?: string; periodEnd?: string }>;
    /**
     * Reads entries: the best ("top", default), the ones around the player, or the player's friends; count 1..100 (default 10). For a daily or weekly board the array has `periodStart` and `periodEnd` (ISO 8601 UTC text) when the store says when the period runs.
     */
    entries(id: string, options?: { range?: "top" | "around" | "friends"; count?: number }): Promise<PlatformLeaderboardEntry[] & { periodStart?: string; periodEnd?: string }>;
  }

  /**
   * Cloud saves: small named values the store keeps for the player across devices.
   */
  export interface PlatformCloudAPI {
    /**
     * Stores any JSON value under a key (1-64 letters, digits, '_', '.', '-'). Stores limit how much a game may keep in the cloud, so save small things (settings, progress), not assets.
     */
    save(key: string, value: Json): Promise<{ key: string; bytes: number }>;
    /**
     * The stored value, or undefined when the key does not exist.
     */
    load(key: string): Promise<Json | undefined>;
    /**
     * The stored keys.
     */
    list(): Promise<string[]>;
    /**
     * Deletes a key.
     */
    remove(key: string): Promise<void>;
  }

  /**
   * In-app purchases of factoria.json platform.products.
   */
  export interface PlatformPurchasesAPI {
    /**
     * Titles and prices as the store shows them, for the given catalog ids (all by default). Products the store does not know are left out.
     */
    products(ids?: string[]): Promise<PlatformProduct[]>;
    /**
     * Starts a purchase. Resolves also when the player cancels (status "cancelled"); rejects when the store failed (network, notAllowed...). Deliver the goods when status is "purchased", then call finish().
     */
    buy(id: string): Promise<PlatformPurchase>;
    /**
     * Tells the store the goods were delivered, once per transaction (consumables can be bought again only after this). Take transactionId from buy(), a "purchase" event or restore(). A transaction the game was not told about (or finished already) rejects with code "unknownId".
     */
    finish(transactionId: string): Promise<void>;
    /**
     * The non-consumables and subscriptions the player owns (a "Restore purchases" button).
     */
    restore(): Promise<{ productId: string; transactionId: string; receipt: string }[]>;
  }

  /**
   * The store's own overlay (Steam overlay, Game Center dashboard).
   */
  export interface PlatformOverlayAPI {
    /**
     * Opens a page of the overlay; `id` (an achievement, leaderboard or product of the catalog) goes to that entry where the store can. Pause the game on the "overlay" event while it is open.
     */
    open(page: "achievements" | "leaderboards" | "friends" | "store", id?: string): Promise<void>;
  }

  /**
   * Rich presence: what friends see the player doing.
   */
  export interface PlatformPresenceAPI {
    /**
     * Sets the text ("In level 3"); "" clears it. `data` holds string values some stores use (Steam's rich presence keys).
     */
    set(text: string, data?: { [key: string]: string }): Promise<void>;
  }

  /**
   * What the player answered to the consent sheets, from ads.consent().
   */
  export interface PlatformConsent {
    /**
     * The GDPR (Google UMP) sheet: granted, denied, notRequired (the player is outside the regions that need it) or unknown (not asked yet).
     */
    readonly gdpr: "granted" | "denied" | "notRequired" | "unknown";
    /**
     * The tracking permission (Apple's App Tracking Transparency): notRequired where the system has no such sheet (Android) and on iOS when platform.ads.trackingPrompt is off; otherwise the status of the sheet the ads plugin asks for after the consent form.
     */
    readonly tracking: "authorized" | "denied" | "notDetermined" | "restricted" | "notRequired";
    /**
     * False when the player refused the GDPR consent: no ad may be requested then.
     */
    readonly canShowAds: boolean;
    /**
     * Whether the game must offer a way to change the ad choices (GDPR): required means the player has to find a "Privacy settings" button that calls platform.ads.privacyOptions(); notRequired where the consent sheet does not apply; unknown before the consent flow finished.
     */
    readonly privacyOptions: "required" | "notRequired" | "unknown";
  }

  /**
   * Advertising at the placements of factoria.json platform.ads.placements. Development runs and tests get a scripted test ad that draws nothing and ends at once (game.platform.ad() chooses how); a shipped Android game gets Google AdMob with the Google consent sheet (UMP) when it has the admob plugin (platform.add_backend admob), and any other shipped game rejects every call with code "unavailable" until a backend offers ads (check platform.has("ads")). Use platform.release to keep a development-only ad stub out of a shipped game. Children: factoria.json platform.ads.audience (docs/PLATFORM.md, "Children and consent").
   */
  export interface PlatformAdsAPI {
    /**
     * True when a rewarded ad is ready to show at the placement (false: no fill, or the player refused the consent). Use it to show or hide the "watch an ad" button. A placement the catalog does not declare throws at once with a suggestion.
     */
    available(placement: string): Promise<boolean>;
    /**
     * Shows a rewarded ad and resolves when it ends. rewarded is true only when the player watched it to the end: give the reward then and only then. Otherwise reason says why: closedEarly (the player closed it), noFill (no ad to show), consentRefused (the player refused the consent). Rejects with code "network" or "unavailable" when the platform failed.
     */
    showRewarded(placement: string): Promise<{ rewarded: boolean; reason?: "closedEarly" | "noFill" | "consentRefused" }>;
    /**
     * What the GDPR and tracking sheets answered, for the game's privacy screen.
     */
    consent(): Promise<PlatformConsent>;
    /**
     * Tells the ad network whether the player is under the age of consent (use 16, the highest age of consent in Europe). Call it after the game asked the player's age with a neutral screen (the menu kit's ageGate part does). The engine keeps the answer for the session and sends it with every ads request: AdMob then tags the requests as child-directed and under the age of consent, and the consent sheet is not shown to a child. With factoria.json platform.ads.audience "mixed" no ad is shown before this is called (available() is false, showRewarded() ends with reason "consentRefused"); with "children" every player counts as under age and setUnderAge(false) throws.
     */
    setUnderAge(underAge: boolean): Promise<void>;
    /**
     * Opens the consent form where the player changes their ad choices. Show a "Privacy settings" button that calls it only when consent().privacyOptions is "required" (the menu kit's options screen does). Resolves when the form closes; shown is false when there was no form to open.
     */
    privacyOptions(): Promise<{ shown: boolean }>;
    /**
     * Who plays, from factoria.json platform.ads.audience (default "general").
     */
    readonly audience: "general" | "children" | "mixed";
    /**
     * The answer of setUnderAge() for this session: true or false; true in a "children" game; null while the game has not asked.
     */
    readonly underAge: boolean | null;
  }

  /**
   * Integrity checks: the platform signs a statement that this is the genuine app on a genuine device, and the game's own server verifies it.
   */
  export interface PlatformIntegrityAPI {
    /**
     * Asks the platform for a signed integrity token. `challenge` is a nonce your server made: 16 to 500 characters of URL-safe Base64 (A-Z a-z 0-9 - _ =), e.g. 16 or more random bytes. Send the token to your server, which must verify it with the store's server API and check the challenge inside the decoded token (a token without a fresh challenge can be replayed); never trust the client's word. A bad challenge throws at once. Offered by some stores only (Google Play): check platform.has("integrity") and let the game work without it; otherwise the Promise rejects with code "unavailable".
     */
    token(challenge: string): Promise<{ token: string }>;
  }

  /**
   * Store and platform services behind one API: achievements, stats, leaderboards, cloud saves, purchases, overlay, presence, integrity, ads. factoria.json "platform" declares the ids; a store plugin (Steam, Apple) answers in a shipped game, a deterministic fake in development, tests and the MCP server. Every function returns a Promise; a mistake in the call (an undeclared id, a wrong type) throws at once with a suggestion, a store failure rejects with an Error that has `code` ("unavailable", "notSignedIn", "notAllowed", "unknownId", "network" or "failed") and `hint`. Answers that arrive later settle at the start of the next frame. See docs/PLATFORM.md.
   */
  export interface PlatformAPI {
    /**
     * Which backend answers: "fake" (development, tests), "none" (no store: every call rejects with "unavailable"), or the plugin's backend name ("steam", "apple").
     */
    readonly backend: string;
    /**
     * Which backend answers platform.ads: an ads plugin ("admob"), the store backend when it offers ads itself ("fake"), or "none" when nothing offers ads.
     */
    readonly adsBackend: string;
    /**
     * True when the backend offers the service, e.g. if (platform.has("leaderboards")) hide the button otherwise. An unknown service throws with a suggestion.
     */
    has(service: PlatformService): boolean;
    /**
     * The last known player (from signIn() and "player" events).
     */
    readonly player: PlatformPlayer;
    /**
     * Signs the player in (or reads who is signed in). Always allowed, even when nobody is.
     */
    signIn(): Promise<PlatformPlayer>;
    /**
     * Listens to purchases that did not come from a buy() call: Ask to Buy approved, an unfinished transaction from an earlier run, a purchase made in the store. Deliver the goods and call purchases.finish(e.transactionId). Events that arrive while nobody listens are kept (up to 100) and delivered to the first listener. Returns the function that stops listening; listeners end with the scene, like ui.on.
     */
    on(event: "purchase", fn: (e: PlatformPurchase) => void): () => void;
    /**
     * The store's overlay opened or closed: pause the game while it is open.
     */
    on(event: "overlay", fn: (e: { open: boolean }) => void): () => void;
    /**
     * The signed-in player changed.
     */
    on(event: "player", fn: (e: PlatformPlayer) => void): () => void;
    readonly achievements: PlatformAchievementsAPI;
    readonly stats: PlatformStatsAPI;
    readonly leaderboards: PlatformLeaderboardsAPI;
    readonly cloud: PlatformCloudAPI;
    readonly purchases: PlatformPurchasesAPI;
    readonly overlay: PlatformOverlayAPI;
    readonly presence: PlatformPresenceAPI;
    readonly integrity: PlatformIntegrityAPI;
    readonly ads: PlatformAdsAPI;
    /**
     * True in a shipped game, false in development runs (`factoria run`, the editor), tests and the MCP server. Use it to leave out what is only for development, such as a test-ad stub or a cheat button.
     */
    readonly release: boolean;
  }

  /**
   * The payload of i18n.on("change").
   */
  export interface I18nChange {
    /**
     * The language now in use.
     */
    language: string;
    /**
     * The language before.
     */
    previous: string;
  }

  /**
   * Localization: the strings of locales/<language>.json in the player's language. factoria.json "localization" lists the languages; without it the game is not localized (t(key) returns the key, languages is []). Components with a `key` field (Text, Button, Toggle, Slider, TextField) are translated by the engine; use t() for text a script builds itself. The chosen language is not saved between runs: keep it with `storage` and call setLanguage at start. See docs/LOCALIZATION.md.
   */
  export interface I18nAPI {
    /**
     * The text of `key` in the current language, else in its base language ("pt" for "pt-BR"), else in the default language. `{name}` placeholders are filled from args; a plural entry is chosen by args.count with the language's CLDR rules. A key that no table has returns the key itself and warns once in the log; it never throws for a missing key. A key that is not a string or args that is not an object throws.
     */
    t(key: string, args?: { count?: number; [name: string]: unknown }): string;
    /**
     * `value` written the way the current language writes numbers: decimal and group separators and digits from the engine's table (en "1,234.5", es "1234,5" and "12.345,5", de "1.234,5", fr "1 234,5" with a narrow no-break space, ar Arabic-Indic digits "١٬٢٣٤٫٥"). `decimals` (0 to 9) fixes the digits after the separator; without it the number keeps the digits it has. A language the table does not know writes like English; a game without localization is English. Same as the `{v:number:1}` placeholder of a string table. Throws for a value that is not a number or decimals out of range.
     */
    number(value: number, options?: { decimals?: number }): string;
    /**
     * `seconds` as a time in the current language: "1:23.4" for 83.4 (minutes:seconds), "1:02:03.4" from one hour on. `decimals` (0 to 3, default 1) are the digits of the second; the decimal separator and the digits follow the language (es "1:23,4", ar "١:٢٣٫٤"). Rounded as a whole, so 59.96 is "1:00.0". Same as the `{t:duration}` placeholder of a string table.
     */
    duration(seconds: number, options?: { decimals?: number }): string;
    /**
     * True when a table of the current language's fallback chain has `key`, so a real string can be told from the key returned for a missing one.
     */
    has(key: string): boolean;
    /**
     * The current language (one of `languages`; "" when the game has no localization).
     */
    readonly language: string;
    /**
     * Switches now: every Text and widget with a `key` is rewritten at once and the "change" listeners run. Accepts the tag as in factoria.json or close to it ("pt_br", "es-MX" -> "es"). An unknown language throws with a "did you mean" and the languages the game has. Not saved: a game keeps the player's choice with `storage` and calls this at start.
     */
    setLanguage(language: string): void;
    /**
     * The game's languages, as in factoria.json localization.languages.
     */
    readonly languages: string[];
    /**
     * factoria.json localization.defaultLanguage: the language of the text written in scenes and the last fallback.
     */
    readonly defaultLanguage: string;
    /**
     * The writing direction of the current language: "rtl" for Arabic, Hebrew, Persian, Urdu and the other right-to-left languages, else "ltr" (also when the game has no localization). Text align "start"/"end" and Panel direction "auto" follow it by themselves; read it to mirror what they do not reach, such as an anchor or a pivot (docs/LOCALIZATION.md, section 6).
     */
    readonly direction: "ltr" | "rtl";
    /**
     * The player's system languages, best first (BCP 47 tags such as "es-MX"). Empty in headless runs and tests: the start language does not depend on the machine there.
     */
    readonly systemLanguages: string[];
    /**
     * The language's own name for a language menu ("Español"): the "$name" of its table, else the tag.
     */
    name(language: string): string;
    /**
     * Runs fn after every language switch (setLanguage or the i18n.set_language command). Returns the function that stops listening; listeners end with the scene, like ui.on, so register in onStart.
     */
    on(event: "change", fn: (e: I18nChange) => void): () => void;
  }

  /**
   * The world.
   */
  export const world: WorldAPI;

  /**
   * Input.
   */
  export const input: InputAPI;

  /**
   * Audio.
   */
  export const audio: AudioAPI;

  /**
   * Physics.
   */
  export const physics: PhysicsAPI;

  /**
   * Path finding on the baked NavMesh3D.
   */
  export const nav: NavAPI;

  /**
   * Game clock.
   */
  export const time: TimeAPI;

  /**
   * Camera helpers.
   */
  export const camera: CameraAPI;

  /**
   * Debug drawing.
   */
  export const debug: DebugAPI;

  /**
   * Scene control.
   */
  export const scene: SceneAPI;

  /**
   * Game control.
   */
  export const game: GameAPI;

  /**
   * The screen and its safe area.
   */
  export const screen: ScreenAPI;

  /**
   * The game window: full screen, size, vsync, frame cap.
   */
  export const window: WindowAPI;

  /**
   * Save data.
   */
  export const storage: StorageAPI;

  /**
   * Deterministic RNG.
   */
  export const rng: RngAPI;

  /**
   * Engine commands.
   */
  export const fa: FaAPI;

  /**
   * Math helpers.
   */
  export const math: MathAPI;

  /**
   * Plain object that persists across scene loads for the whole run (score, lives, current level). Not saved to disk; reset for every test file. Module-level variables persist across scene loads too.
   */
  export const session: Record<string, any>;

  /**
   * Particle helpers.
   */
  export const particles: ParticlesAPI;

  /**
   * Game UI events and focus, text measurement.
   */
  export const ui: UIAPI;

  /**
   * Asset queries (texture size).
   */
  export const assets: AssetsAPI;

  /**
   * Functions of the game's native plugins (factoria.json "plugins", docs/EXTENDING.md "Native plugins"): plugins.<plugin>.<function>(...args) passes the arguments as JSON and returns the plugin's JSON result; a failure throws an Error with the plugin's message and hint. A plugin that is not built for this platform is undefined (test with `if (plugins.steam)`); one that failed to load throws why on first use.
   */
  export const plugins: PluginsAPI;

  /**
   * Store and platform services: achievements, stats, leaderboards, cloud saves, purchases, overlay, presence, integrity, ads (docs/PLATFORM.md).
   */
  export const platform: PlatformAPI;

  /**
   * Localization: t(key, args), number, duration, language, setLanguage, languages, systemLanguages, on("change") (docs/LOCALIZATION.md).
   */
  export const i18n: I18nAPI;

  /**
   * Plays the clips of a skinned glTF on an entity with an Animator component (entity.animator). The engine advances it in the fixed step, so animation, its events and state machine transitions are deterministic. Example: `hero.animator.set("speed", 3)`; `hero.animator.on("footstep", () => audio.play("assets/step.wav"))`.
   */
  export interface AnimatorAPI {
    /**
     * Starts a clip (a glTF animation name, see `clips`), cross-fading from the current pose over `fadeSeconds` (default: the component's `fade`; 0 cuts). Playing the clip that already plays does not restart it. Throws with the clip names when it does not exist.
     */
    play(clip: string, fadeSeconds?: number): void;
    /**
     * Pauses and returns to the bind pose (the model as exported).
     */
    stop(): void;
    /**
     * Sets a state machine parameter declared in the Animator's `params`. The transitions read it on the next step.
     */
    set(name: string, value: number | boolean): void;
    /**
     * Current value of a state machine parameter.
     */
    get(name: string): number | boolean;
    /**
     * Makes the parameter `name` true for the next step only (one-shot input like "jump" or "hurt"). It does not need to be declared.
     */
    trigger(name: string): void;
    /**
     * Names of the animation clips of the model.
     */
    readonly clips: string[];
    /**
     * Length of a clip in seconds.
     */
    duration(clip: string): number;
    /**
     * Listens to a game event of THIS entity's animator: a clip event from the Animator's `events`, a state's `onEnter` name, or "anim.finished". Returns the unsubscribe function. world.on(name, fn) hears every entity.
     */
    on(event: string, fn: (data: { id: string; clip?: string; time?: number; state?: string }, source: Entity | null) => void): () => void;
    /**
     * State machine: the current state.
     */
    readonly state: string;
    /**
     * The clip playing now. Assigning switches clips with the component's `fade`.
     */
    clip: string;
    /**
     * Seconds into the current clip. Assigning seeks (no events fire for the jump).
     */
    time: number;
    /**
     * Playback speed multiplier.
     */
    speed: number;
    /**
     * Start over at the end of the clip. false stops on the last pose and sends "anim.finished".
     */
    loop: boolean;
    /**
     * false pauses, true resumes.
     */
    playing: boolean;
    /**
     * The Animator component view (model, params, states, transitions, events...).
     */
    readonly component: Components["Animator"];
  }

  /**
   * Controls a Video component (entity.video): an .mpg drawn in the entity's UI rectangle. The engine advances it in the fixed step from the game clock, so it pauses with the game and a headless run is deterministic. Example: `intro.video.on("ended", () => scene.load("scenes/menu.scene.json"))`; `intro.video.seek(10)`.
   */
  export class VideoAPI {
    /**
     * Plays, or resumes after pause(). After the end it starts over from the first picture.
     */
    play(): void;
    /**
     * Stops advancing and keeps the picture; the sound goes silent.
     */
    pause(): void;
    /**
     * Pauses and returns to the first picture.
     */
    stop(): void;
    /**
     * Jumps to `seconds` (clamped to the length) and shows the picture there. Keeps playing if it was playing; no "ended" event comes from a seek.
     */
    seek(seconds: number): void;
    /**
     * Listens to the "ended" event of THIS entity's video: a video that does not loop reached its end (once per play). Returns the unsubscribe function. world.on("video.ended", fn) hears every Video.
     */
    on(event: "ended", fn: (data: { id: string; path: string }, source: Entity | null) => void): () => void;
    /**
     * Seconds into the video.
     */
    readonly time: number;
    /**
     * Length in seconds; 0 until the file is open (the first fixed step after the scene loads).
     */
    readonly duration: number;
    /**
     * True while it advances.
     */
    readonly playing: boolean;
    /**
     * True after it reached its end, until a seek or play() starts it again.
     */
    readonly ended: boolean;
    /**
     * Wrap to the first picture at the end instead of ending.
     */
    loop: boolean;
    /**
     * Loudness of the sound, 0..1.
     */
    volume: number;
    /**
     * The Video component view (path, autoplay, fit, tint, bus...).
     */
    readonly component: Components["Video"];
  }

  /**
   * An easing function: maps progress 0..1 to eased progress (0 at 0, 1 at 1; back and elastic overshoot in between).
   */
  export type EaseFn = (t: number) => number;

  /**
   * Name of a built-in easing: linear, or quad / cubic / quart / quint / sine / expo / circ / back / elastic / bounce followed by In, Out or InOut.
   */
  export type EaseName = "linear" | "quadIn" | "quadOut" | "quadInOut" | "cubicIn" | "cubicOut" | "cubicInOut" | "quartIn" | "quartOut" | "quartInOut" | "quintIn" | "quintOut" | "quintInOut" | "sineIn" | "sineOut" | "sineInOut" | "expoIn" | "expoOut" | "expoInOut" | "circIn" | "circOut" | "circInOut" | "backIn" | "backOut" | "backInOut" | "elasticIn" | "elasticOut" | "elasticInOut" | "bounceIn" | "bounceOut" | "bounceInOut";

  /**
   * The built-in easing functions by name (ease.quadOut, ease.bounceOut...). tween() also accepts the name as a string.
   */
  export interface EaseAPI {
    readonly linear: EaseFn;
    readonly quadIn: EaseFn;
    readonly quadOut: EaseFn;
    readonly quadInOut: EaseFn;
    readonly cubicIn: EaseFn;
    readonly cubicOut: EaseFn;
    readonly cubicInOut: EaseFn;
    readonly quartIn: EaseFn;
    readonly quartOut: EaseFn;
    readonly quartInOut: EaseFn;
    readonly quintIn: EaseFn;
    readonly quintOut: EaseFn;
    readonly quintInOut: EaseFn;
    readonly sineIn: EaseFn;
    readonly sineOut: EaseFn;
    readonly sineInOut: EaseFn;
    readonly expoIn: EaseFn;
    readonly expoOut: EaseFn;
    readonly expoInOut: EaseFn;
    readonly circIn: EaseFn;
    readonly circOut: EaseFn;
    readonly circInOut: EaseFn;
    readonly backIn: EaseFn;
    readonly backOut: EaseFn;
    readonly backInOut: EaseFn;
    readonly elasticIn: EaseFn;
    readonly elasticOut: EaseFn;
    readonly elasticInOut: EaseFn;
    readonly bounceIn: EaseFn;
    readonly bounceOut: EaseFn;
    readonly bounceInOut: EaseFn;
  }

  /**
   * Options of tween().
   */
  export interface TweenOptions {
    /**
     * Seconds per play (default 1).
     */
    duration?: number;
    /**
     * Seconds to wait before it starts (default 0).
     */
    delay?: number;
    /**
     * Easing (default "linear"). inOut easings play the in curve for the first half and its mirror image for the second.
     */
    ease?: EaseName | EaseFn;
    /**
     * Extra plays after the first (0 = once, Infinity = forever).
     */
    repeat?: number;
    /**
     * Every second play runs backwards.
     */
    yoyo?: boolean;
    /**
     * Start values instead of the current ones, same shape as the end values: { x: 0 }. For tween(from, to, ...) the start is the first argument.
     */
    from?: any;
    /**
     * Called once when the delay is over and it starts moving (start values are read here).
     */
    onStart?: (tween: Tween) => void;
    /**
     * Called after every update. `value` is the eased progress (can overshoot with back/elastic); for tween(from, to) it is the current number.
     */
    onUpdate?: (value: number, tween: Tween) => void;
    /**
     * Called when the last play ends (never for a cancelled tween).
     */
    onComplete?: (tween: Tween) => void;
  }

  /**
   * A running tween, returned by tween(). Driven by the game clock: pauses with time.scale = 0, identical in headless runs.
   */
  export interface Tween {
    /**
     * false once it completed or was cancelled.
     */
    readonly active: boolean;
    /**
     * 0..1 over all plays (after the delay).
     */
    readonly progress: number;
    /**
     * Resolves true when it completes and false when it is cancelled (also when the scene changes). `await tween(...).finished` in async code.
     */
    readonly finished: Promise<boolean>;
    /**
     * Stops it where it is (values stay as they are) and cancels the tweens chained after it.
     */
    cancel(): this;
    /**
     * Freezes it.
     */
    pause(): this;
    /**
     * Continues after pause().
     */
    resume(): this;
    /**
     * Adds a completion callback.
     */
    onComplete(fn: (tween: Tween) => void): this;
    /**
     * Starts another tween when this one completes (chain): `tween(a, {x: 1}).next(a, {y: 1}).next(b, {a: 0})`. Returns the NEW tween. Cancelling this one cancels the chain.
     */
    next(target: object, props: object, options?: TweenOptions): Tween;
  }

  /**
   * Built-in easing functions.
   */
  export const ease: EaseAPI;

  /**
   * Creates a Vec2: vec2(1, 2), vec2([1, 2]), vec2({x, y}), vec2(3) = (3, 3).
   */
  export function vec2(x?: number | Vec2Like, y?: number): Vec2;

  /**
   * Creates a Vec3.
   */
  export function vec3(x?: number | Vec3Like, y?: number, z?: number): Vec3;

  /**
   * Creates a Color from components 0..1 or "#rrggbb".
   */
  export function color(r?: number | ColorLike, g?: number, b?: number, a?: number): Color;

  /**
   * Moves numbers, vectors and colors of `target` to the end values in `props` over time. Targets: a component view (`tween(sprite, {color: "#ff0000"})`), a vector (`tween(entity.position, {y: 5})`), a color, or a plain object. A vector end value is [x, y, z], {x, y, z} or a Vec; a color is "#rrggbb", [r, g, b, a] or {r, g, b, a}. Start values are read when the delay ends. Driven by the game clock (fixed step, time.scale), never by the wall clock. Example: `await tween(entity.position, {y: 3}, {duration: 0.5, ease: "backOut"}).finished`.
   */
  export function tween(target: object, props: { [property: string]: number | string | readonly number[] | { [channel: string]: number } }, options?: TweenOptions): Tween;

  /**
   * Tweens a plain number from `from` to `to`, calling options.onUpdate(value) every step (for a counter, a health bar value...).
   */
  export function tween(from: number, to: number, options: TweenOptions & { onUpdate: (value: number, tween: Tween) => void }): Tween;

  /**
   * Cancels every running tween, or only those whose target is `target`.
   */
  export function cancelTweens(target?: object): void;

  // ---- Components (generated from the engine's reflection registry) ----
  /**
   * Identity of an entity; present on every entity. In scene files these fields are the entity's top-level keys (id, name, tags, active), not a component entry. Tags are handled by the scene serializer.
   * 
   * Category: Core
   */
  export interface EntityInfoComponent {
    /**
     * Stable unique string id within the scene (e.g. "player"). Used to reference the entity from Entity fields, scripts (world.find) and tools. Auto-generated ("e1", "e2"...) if omitted.
     */
    id: string;
    /**
     * Display name shown in the editor and logs. Not unique.
     */
    name: string;
    /**
     * If false the entity and all its children are skipped by rendering, physics, audio and scripts.
     */
    active: boolean;
  }
  /**
   * Position, rotation and scale of an entity relative to its parent. Present on every entity. 2D uses x/y of position and the z angle of rotation; 3D units are meters.
   * 
   * Category: Core
   */
  export interface TransformComponent {
    /**
     * Local position relative to the parent [x, y, z]. 2D: x right, y up, z is only used for depth ordering of 3D content. Units: world units (design pixels in 2D, meters in 3D).
     */
    get position(): Vec3;
    set position(value: Vec3Like);
    /**
     * Local rotation as euler angles in DEGREES [pitch around X, yaw around Y, roll around Z], applied in the order Y, X, Z. 2D games only use the z value (counter-clockwise).
     */
    get rotation(): Vec3;
    set rotation(value: Vec3Like);
    /**
     * Local scale [x, y, z]. 1 = original size; negative values mirror.
     */
    get scale(): Vec3;
    set scale(value: Vec3Like);
  }
  /**
   * Renders the scene to the screen. The active camera with primary=true and the lowest depth draws the game (only one camera renders for now; split-screen/overlay cameras are on the roadmap). 3D cameras look down their local -Z axis.
   * 
   * Category: Camera
   */
  export interface CameraComponent {
    /**
     * orthographic: flat 2D view (no perspective). perspective: 3D view with depth.
     */
    projection: "orthographic" | "perspective";
    /**
     * Perspective only: vertical field of view in degrees.
     */
    fov: number;
    /**
     * Orthographic only: half of the visible height in world units. 0 = use the design resolution (pixel perfect: one world unit is one design pixel).
     */
    orthoSize: number;
    /**
     * Perspective only: distance of the near clip plane in meters. Keep it as large as possible for depth precision.
     */
    nearPlane: number;
    /**
     * Perspective only: distance of the far clip plane in meters.
     */
    farPlane: number;
    /**
     * Background color the camera clears to when clear is true.
     */
    get clearColor(): Color;
    set clearColor(value: ColorLike);
    /**
     * Clear the target before drawing. Set false on overlay cameras that draw on top of another camera.
     */
    clear: boolean;
    /**
     * The first active primary camera renders the game.
     */
    primary: boolean;
    /**
     * Picks the rendering camera when several are primary: the lowest depth wins (multi-camera rendering is on the roadmap).
     */
    depth: number;
    /**
     * Bloom (glow) post-process: bright pixels bleed light into their surroundings, the neon / laser / fire / explosion look. Works for 2D and 3D cameras, is applied to the whole finished frame (screen-space HUD included, unless bloomScreenSpace is false) and shows in screenshots. Combine with blend "additive" on Sprite, Shape2D or ParticleEmitter instead of hand-drawing blurred halo sprites. Off by default; costs a few extra render passes per frame (cheap on a GPU, about 5 ms at 1280x720 on the software renderer used for headless runs). Tune with bloomThreshold, bloomIntensity and bloomRadius; keep the HUD crisp with bloomScreenSpace.
     */
    bloom: boolean;
    /**
     * Only used when bloom is true. Brightness (0..1, the largest of a pixel's r, g, b) at which glow starts: pixels at or below it do not glow, the glow ramps up linearly to full strength at 1 (white / fully saturated). Lower it (0.3-0.6) to make dim colors glow too; raise it (0.9+) so only the brightest pixels do (values above 0.99 behave like 0.99).
     */
    bloomThreshold: number;
    /**
     * Only used when bloom is true. Strength of the glow that is added back onto the frame: 0 = none, 1 = the blurred bright pixels are added once, 2 = twice (brighter, saturates sooner). Limited to 0..10.
     */
    bloomIntensity: number;
    /**
     * Only used when bloom is true. How far the glow reaches, in design pixels (1280x720 by default): a gaussian blur whose visible halo fades out roughly this far from the bright pixels. Values below ~5 behave like 5 (the glow is computed at reduced resolution, and larger radii at even lower resolution, so wide glows are softer). Limited to 1..128.
     */
    bloomRadius: number;
    /**
     * Only used when bloom is true. true (default): the whole finished frame glows, screen-space items (Sprite, Shape2D, Text with space "screen", and debug text) included, so a bright neon title or HUD icon glows too. false: screen-space items are drawn AFTER the bloom, so the HUD (score, lives, menus) stays crisp and never glows while the world still does. Set it to false whenever the HUD has white or bright text over a glowing world; leave it true to make a screen-space title or logo glow.
     */
    bloomScreenSpace: boolean;
    /**
     * Accessibility colour filter, the LAST post-process pass: it is applied to the whole finished frame (HUD included, after the bloom) on every graphics backend, so screenshots, factoria run --screenshot-at and --record-video show it too. A game's options screen sets it from the player's choice (it is not saved by itself). none (default): no pass, no cost. greyscale: Rec. 709 luminance in linear light. highContrast: contrast stretched 1.8x around mid grey, clipped. protanopia, deuteranopia, tritanopia: a daltonize correction for a player who lacks that cone: the loss is estimated with the Machado 2009 matrix (severity 1.0) and the lost information is shifted into the channels the player still sees (Fidaner's method), so colours that collapse together (red vs green) differ in brightness or in the remaining hue. To CHECK a game without changing what the player sees, use the `simulate` option of game.screenshot / --screenshot-simulate instead.
     * @since 0.2.0
     */
    colorFilter: "none" | "greyscale" | "highContrast" | "protanopia" | "deuteranopia" | "tritanopia";
  }
  /**
   * Draws a textured (or solid color) quad. Use `region` to pick a frame from a sprite sheet. Draw order: higher `layer` on top; ties sort by position.y (lower y on top), then creation order.
   * 
   * Category: 2D
   */
  export interface SpriteComponent {
    /**
     * Project-relative path of the image (e.g. "assets/hero.png"). Empty draws a solid quad of `color`. (asset path: texture)
     */
    texture: string;
    /**
     * Source rectangle [x, y, w, h] in texture pixels with the origin at the TOP-LEFT. A zero size means the whole texture. SpriteAnimator overwrites it every frame.
     */
    get region(): Rect;
    set region(value: RectLike);
    /**
     * Size [w, h] in world units. [0, 0] = use the region (or texture) size in pixels.
     */
    get size(): Vec2;
    set size(value: Vec2Like);
    /**
     * Anchor inside the sprite: [0, 0] bottom-left, [0.5, 0.5] center, [1, 1] top-right.
     */
    get pivot(): Vec2;
    set pivot(value: Vec2Like);
    /**
     * Tint multiplied with the texture. Alpha makes it translucent. Accepts [r,g,b,a], "#rrggbb" or a name.
     */
    get color(): Color;
    set color(value: ColorLike);
    /**
     * Mirror horizontally.
     */
    flipX: boolean;
    /**
     * Mirror vertically.
     */
    flipY: boolean;
    /**
     * Draw order. Higher layers draw on top of lower ones. Backgrounds use negative layers.
     */
    layer: number;
    /**
     * world: positioned in the game world and affected by cameras. screen: UI/HUD in design-resolution pixels with (0,0) at the TOP-LEFT and +Y DOWN; drawn after the world.
     */
    space: "world" | "screen";
    /**
     * true = nearest-neighbour filtering (crisp pixels), false = smooth linear filtering.
     */
    pixelArt: boolean;
    /**
     * Compositing: alpha (normal), additive (glow, neon, fire, lasers; brightens), multiply (darkens/tints).
     */
    blend: "alpha" | "additive" | "multiply";
    /**
     * Screen space only: screen point the position is relative to. [0,0] top-left (default), [1,0] top-right, [0.5,0.5] center, [1,1] bottom-right. Keeps HUD elements glued to screen edges on any aspect ratio.
     */
    get anchor(): Vec2;
    set anchor(value: Vec2Like);
    /**
     * Screen space only. true: the anchor names a point of the SAFE area, the screen minus the notch, rounded corners and system bars of a phone (screen.safeArea in scripts), instead of the whole screen: anchor [0, 0] is the top-left corner of the safe area, [1, 1] its bottom-right. Keeps HUD and buttons out of the notch. On a screen without cutouts (desktop, most tablets) it changes nothing. Default false.
     * @since 0.2.0
     */
    safeArea: boolean;
    /**
     * 9-slice borders in texture pixels [left, top, right, bottom], measured inside `region` (or the whole texture). With a border set the four corners are drawn at their texture size (1 texture pixel = 1 world unit), the edges stretch along one axis and the centre along both, so one small frame gives a panel, bar or platform of any `size`. [0, 0, 0, 0] (default) stretches the whole region. Borders that do not fit in `size` shrink together. Works with atlas-packed textures, flipX / flipY and a lit sprite. Screen-space UI panels use the same slicing through Panel.texture and Panel.slice.
     * @since 0.2.0
     */
    get slice(): Vec3 & { w: number };
    set slice(value: readonly number[] | { x: number; y: number; z: number; w: number });
    /**
     * World space only. true: the sprite is shaded by the Light2D entities of the scene plus SceneSettings.ambientLight (its colour is multiplied by ambient + the sum of the lights); false (default): drawn exactly as the texture says, whatever lights exist. At most 16 lights shade a frame (see Light2D).
     * @since 0.2.0
     */
    lit: boolean;
    /**
     * Lit sprites only. Tangent-space normal map: RGB = (x, y, z) mapped from 0..1 to -1..1, +x to the right and +y UP the picture (OpenGL / Unity convention), laid out exactly like `texture` and `region` (same size). It turns with the sprite's rotation and flips. Empty (default) = a flat sprite lit only by distance. Ignored unless `lit` is true. (asset path: texture)
     * @since 0.2.0
     */
    normalMap: string;
  }
  /**
   * Shifts the drawing of this entity's world-space visuals (Sprite, Shape2D, Text, Tilemap) with the camera so far layers slide slower than near ones. Offset = camera position * (1 - factor) per axis: factor 1 behaves like any world object, 0 stays glued to the camera (a sky), 0.5 is half as fast (distant hills), above 1 is a foreground. With the camera at (0, 0) the entity is exactly where its Transform says. Only the drawing moves: Transform, physics and picking positions stay put, while entity.bounds() reports where it is drawn. Deterministic: it depends only on the camera position.
   * 
   * Category: 2D
   * @since 0.2.0
   */
  export interface ParallaxComponent {
    /**
     * [x, y] fraction of the camera's movement this layer follows (0 = fixed on screen, 1 = a normal world object).
     * @since 0.2.0
     */
    get factor(): Vec2;
    set factor(value: Vec2Like);
    /**
     * Sprite only. Tile the sprite endlessly left and right (at `repeatSize.x` spacing, or its own width) so a background strip never runs out. The copies are drawn only where the camera sees them.
     * @since 0.2.0
     */
    repeatX: boolean;
    /**
     * Sprite only. Same as repeatX, up and down.
     * @since 0.2.0
     */
    repeatY: boolean;
    /**
     * Distance between repeated copies in world units [x, y]. 0 = the sprite's own width / height. Use a smaller value to overlap soft edges, a larger one for gaps.
     * @since 0.2.0
     */
    get repeatSize(): Vec2;
    set repeatSize(value: Vec2Like);
    /**
     * Runtime: the shift [x, y] currently applied to the drawing (written by the renderer every frame). Read-only.
     * @since 0.2.0
     */
    readonly offset: Vec2;
  }
  /**
   * A light for lit 2D visuals: sprites and tilemaps with `lit` true. Their colour is multiplied by SceneSettings.ambientLight plus the light of every Light2D (point: color * intensity * (1 - distance / radius)^falloff, scaled by the normal map's angle to the light when the sprite has a normalMap; directional: even light from one direction). Unlit visuals ignore lights, so existing games look the same. At most 16 lights shade a frame (the same on every graphics backend): directional lights first, then the point lights whose radius reaches the camera view, the ones with more of their radius in view first, then the more intense ones; a light entirely off-view is never kept over one in view. More than 16 in view logs one warning per scene, and renderStats().lights2d / lights2dDropped count what was kept and left out. The light sits at the entity's position (Transform) and ignores layers.
   * 
   * Category: 2D
   * @since 0.2.0
   */
  export interface Light2DComponent {
    /**
     * point: a lamp at the entity's position that fades out at `radius`. directional: sun / moon, the same everywhere, coming from the opposite of `direction`.
     * @since 0.2.0
     */
    type: "point" | "directional";
    /**
     * Light colour. Accepts [r,g,b,a], "#rrggbb" or a name (alpha is ignored).
     * @since 0.2.0
     */
    get color(): Color;
    set color(value: ColorLike);
    /**
     * Strength: multiplies color. 1 = full colour at the lamp; above 1 over-brightens.
     * @since 0.2.0
     */
    intensity: number;
    /**
     * Point lights: distance in world units at which the light has faded to nothing.
     * @since 0.2.0
     */
    radius: number;
    /**
     * Point lights: fade curve exponent. 1 = linear, 2 (default) = smooth, higher = a tight bright core.
     * @since 0.2.0
     */
    falloff: number;
    /**
     * Point lights: height above the drawing plane in world units. Only matters for normal-mapped sprites: a low lamp grazes the surface and shows relief, a high one lights it flatly.
     * @since 0.2.0
     */
    height: number;
    /**
     * Directional lights: degrees the light travels towards (0 = right, 90 = up, 270 = down).
     * @since 0.2.0
     */
    direction: number;
    /**
     * Directional lights: angle above the drawing plane in degrees (90 = straight at the picture, 0 = along it).
     * @since 0.2.0
     */
    elevation: number;
  }
  /**
   * Flipbook animation over a grid sprite sheet. Requires a Sprite on the same entity; it overwrites Sprite.region every frame. Frames are numbered row-major from the top-left.
   * 
   * Category: 2D
   */
  export interface SpriteAnimatorComponent {
    /**
     * Number of columns in the sprite sheet grid.
     */
    columns: number;
    /**
     * Number of rows in the sprite sheet grid.
     */
    rows: number;
    /**
     * First frame of the clip (inclusive, row-major index).
     */
    firstFrame: number;
    /**
     * Last frame of the clip (inclusive, row-major index).
     */
    lastFrame: number;
    /**
     * Playback speed in frames per second.
     */
    fps: number;
    /**
     * Restart from firstFrame after lastFrame. If false the animation stops on the last frame.
     */
    loop: boolean;
    /**
     * Set false to pause, true to play.
     */
    playing: boolean;
    /**
     * Runtime state: seconds elapsed in the current clip.
     */
    time: number;
    /**
     * Runtime state: current frame index.
     */
    frame: number;
  }
  /**
   * Untextured 2D primitive for prototypes, UI panels and debug visuals.
   * 
   * Category: 2D
   */
  export interface Shape2DComponent {
    /**
     * Kind of primitive to draw. triangle: isosceles, apex at the middle of the top edge of the size box, base along the bottom edge. diamond: a rhombus whose 4 points sit at the middles of the size box's 4 edges (a square rotated 45 degrees when size is square; handy for gems, enemies and neon markers). polygon: a regular polygon with `sides` sides whose vertices lie on the ellipse inscribed in the size box, first vertex pointing up (hexagons, pentagons, octagons; many sides approach a circle). star: `points` tips on that ellipse, first tip pointing up, with notches at `innerRadius` of the outer radius in between. Outlines (filled = false) of triangle, diamond, polygon and star grow INWARD from the silhouette, like the rectangle's, so a thick outline never pokes out of the size box.
     */
    shape: "rectangle" | "circle" | "line" | "triangle" | "diamond" | "polygon" | "star";
    /**
     * rectangle/triangle/diamond/polygon/star: [width, height] of the box that contains the shape. circle: diameter in x. line: end point offset from the entity origin.
     */
    get size(): Vec2;
    set size(value: Vec2Like);
    /**
     * Fill or outline color.
     */
    get color(): Color;
    set color(value: ColorLike);
    /**
     * true = solid shape, false = outline only (lines are always drawn as strokes).
     */
    filled: boolean;
    /**
     * Outline / line thickness in world units.
     */
    thickness: number;
    /**
     * Draw order. Higher layers draw on top.
     */
    layer: number;
    /**
     * world: affected by cameras. screen: UI in design pixels, origin TOP-LEFT, +Y down.
     */
    space: "world" | "screen";
    /**
     * Anchor point within the shape's size box for every shape but line: [0.5,0.5] = the box centre sits on the position (default), [0,0] bottom-left, [1,1] top-right. This point is also what the entity rotates and scales around. In screen space +Y is down, so [0,1] puts the top-left corner at the position. For a triangle the box centre is NOT its centre of mass (the apex is at the top-middle, the base along the bottom): use [0.5, 0.3333] to put its centroid on the position, the natural point to spin a triangle around without it wobbling. Circles and diamonds are symmetric, so the default [0.5,0.5] already spins them in place.
     */
    get pivot(): Vec2;
    set pivot(value: Vec2Like);
    /**
     * Compositing: alpha (normal), additive (glow/neon), multiply (darken).
     */
    blend: "alpha" | "additive" | "multiply";
    /**
     * Screen space only: screen point the position is relative to ([0,0] top-left, [1,1] bottom-right).
     */
    get anchor(): Vec2;
    set anchor(value: Vec2Like);
    /**
     * Screen space only. true: the anchor names a point of the SAFE area, the screen minus the notch, rounded corners and system bars of a phone (screen.safeArea in scripts), instead of the whole screen: anchor [0, 0] is the top-left corner of the safe area, [1, 1] its bottom-right. Keeps HUD and buttons out of the notch. On a screen without cutouts (desktop, most tablets) it changes nothing. Default false.
     * @since 0.2.0
     */
    safeArea: boolean;
    /**
     * polygon only: number of sides (3 = triangle, 6 = hexagon, 8 = octagon).
     */
    sides: number;
    /**
     * star only: number of tips (5 = the classic star).
     */
    points: number;
    /**
     * star only: radius of the notches between the tips as a fraction of the outer radius. 0.5 = classic star, near 1 = a fat spiky polygon, near 0 = thin needles.
     */
    innerRadius: number;
    /**
     * World space only. true: the shape is shaded by the Light2D entities of the scene plus SceneSettings.ambientLight (its colour is multiplied by ambient + the sum of the lights), like Sprite.lit, so a dark level can use shapes for platforms and hazards; every shape type, outlines and lines included, is flat (no normal map). false (default): drawn exactly in `color`, whatever lights exist. At most 16 lights shade a frame (see Light2D).
     * @since 0.2.0
     */
    lit: boolean;
  }
  /**
   * Draws a string with a TrueType font (or the built-in font). Works in world and screen space.
   * 
   * Category: 2D
   */
  export interface TextComponent {
    /**
     * The string to draw. Use \n for line breaks. While `key` is set the engine overwrites it with the translation of the current language every frame: edit the string table (locales/<language>.json), not this field.
     */
    text: string;
    /**
     * Localization key, e.g. "menu.play" (docs/LOCALIZATION.md). Empty (default) = this Text is not translated. With a key, the runtime writes the string of that key in the current language (locales/<language>.json, falling back to the base language and then to localization.defaultLanguage) into `text` when a scene or prefab loads, every frame and when the language changes, so `text` is overwritten at run time. A key that no string table has keeps the text written here and logs one warning.
     * @since 0.2.0
     */
    key: string;
    /**
     * Values for the {placeholders} of `key`, an object of name -> string or number: {"score": 12} fills "Score: {score}" (and `count` picks the form of a plural entry). Set it once from a script (`entity.set("Text", { keyArgs: { score } })` or `scene.set_component`) instead of rewriting the text every frame: the engine formats the translation with them when the text is localized, when the args change and when the language changes, so a language switch keeps them. Empty (default) = no arguments. Ignored while `key` is empty. Returns a plain-object COPY; assign a new value to write.
     * @since unreleased
     */
    keyArgs: any;
    /**
     * Project-relative path of a .ttf font. Empty uses the built-in font, DejaVu Sans (Latin, Greek, Cyrillic, Hebrew, Arabic); "builtin:pixel" is Press Start 2P. Characters the font has no glyph for draw as nothing and log one warning per font: Chinese, Japanese and Korean need a .ttf that covers them (e.g. Noto Sans SC, JP or KR). Keep this empty and list the extra fonts in factoria.json (localization.fallbackFonts, localization.languageFonts) to cover every Text of the game (docs/TEXT.md). (asset path: font)
     */
    font: string;
    /**
     * Glyph height in world units (pixels in 2D).
     */
    fontSize: number;
    /**
     * Text color.
     */
    get color(): Color;
    set color(value: ColorLike);
    /**
     * Horizontal alignment of lines inside the text box. left / right are always the left / right edge, even for right-to-left text. start / end follow the current language: start = left and end = right in a left-to-right language, start = right and end = left in Arabic, Hebrew and the other right-to-left languages (i18n.direction); use them for text that must read from its start side.
     */
    align: "left" | "center" | "right" | "start" | "end";
    /**
     * Anchor of the text box: [0, 1] top-left (default), [0.5, 0.5] center, [1, 0] bottom-right.
     */
    get pivot(): Vec2;
    set pivot(value: Vec2Like);
    /**
     * If > 0, lines wrap at this width in world units. 0 = no wrapping. With autoShrink it is also the width the text must fit (a word longer than the box shrinks the font).
     */
    maxWidth: number;
    /**
     * Box height in the same units as maxWidth that autoShrink fits the text into: a card title with maxWidth 200 and maxHeight 30 stays on one line at any text size by shrinking. 0 (default) = only the width counts. Nothing is clipped or wrapped by it; it only drives autoShrink and ui.overflowed(id).
     * @since unreleased
     */
    maxHeight: number;
    /**
     * true: when the text does not fit its box at the current text size (ui.textScale) and language, the font is made smaller until it does, never under `minFontSize` (so a German label in a fixed button stays inside at 200 % text, and a long translation is smaller instead of cut). It is decided every frame from the laid-out size, with no script. If it still does not fit at minFontSize it is drawn there and ui.overflowed(id) is true. false (default): the size is never reduced.
     * @since unreleased
     */
    autoShrink: boolean;
    /**
     * autoShrink floor in design pixels, before ui.textScale (the floor is minFontSize times the player's text size, capped by maxTextScale, so the accessibility setting keeps working). Never above fontSize.
     * @since unreleased
     */
    minFontSize: number;
    /**
     * > 0: the player's text size (ui.textScale) stops growing this text at this scale, so a heading or a round button label does not outgrow its place: 1.3 means it is drawn at most 1.3 times its fontSize however big the option is. It only limits growth: at a text size below the cap it is drawn at the player's size. 0 (default) = no cap. Measuring (autoSize, layout, ui.measureText, ui.rectOf) and drawing use the same capped size.
     * @since unreleased
     */
    maxTextScale: number;
    /**
     * Draw order. Higher layers draw on top. Text defaults above sprites.
     */
    layer: number;
    /**
     * world: affected by cameras. screen: HUD/UI in design pixels, origin TOP-LEFT, +Y down.
     */
    space: "world" | "screen";
    /**
     * Screen space only: screen point the position is relative to ([0,0] top-left, [1,0] top-right, [0.5,0] top-center, [1,1] bottom-right). Combine with pivot, e.g. anchor [1,0] + pivot [1,1] + position [-20, 20] = right-aligned 20px from the top-right corner.
     */
    get anchor(): Vec2;
    set anchor(value: Vec2Like);
    /**
     * Screen space only. true: the anchor names a point of the SAFE area, the screen minus the notch, rounded corners and system bars of a phone (screen.safeArea in scripts), instead of the whole screen: anchor [0, 0] is the top-left corner of the safe area, [1, 1] its bottom-right. Keeps HUD and buttons out of the notch. On a screen without cutouts (desktop, most tablets) it changes nothing. Default false.
     * @since 0.2.0
     */
    safeArea: boolean;
  }
  /**
   * A grid of tiles drawn from a tileset texture; tile index -1 is empty. Row 0 is the TOP row. Solid tiles can generate static 2D collision.
   * 
   * Category: 2D
   */
  export interface TilemapComponent {
    /**
     * Project-relative path of the tileset image (tiles laid out left-to-right, top-to-bottom). (asset path: texture)
     */
    tileset: string;
    /**
     * Size of one tile [w, h], both in the tileset texture (pixels) and in the world (units).
     */
    get tileSize(): Vec2;
    set tileSize(value: Vec2Like);
    /**
     * Number of tile columns in the tileset texture (used to find a tile's source rectangle). Optional: 0 (the default) derives it from the tileset texture, as many whole tiles of tileSize.x as fit across its width. Set it only when the image has a different layout.
     */
    columns: number;
    /**
     * Map width in tiles, for a flat tiles array. Not needed when tiles is an array of rows (the rows define the size; drawing and collision both use it).
     */
    width: number;
    /**
     * Map height in tiles, for a flat tiles array. Not needed when tiles is an array of rows.
     */
    height: number;
    /**
     * Tile values, row-major with row 0 at the TOP: either a flat array of width*height integers (set width and height) or an array of rows (the size comes from the rows). -1 = empty. A value is the tileset index, optionally plus flags that mirror or turn that tile when drawn: 268435456 flips it left-right (flipX), 536870912 top-bottom (flipY), 1073741824 mirrors it across the diagonal (transpose). The image is transposed first, then flipped in x, then in y; a 90 degree clockwise turn is transpose + flipX = 1342177280 + index, 180 is flipX + flipY = 805306368 + index, 90 counter-clockwise is transpose + flipY = 1610612736 + index. scene.import_ascii legends write these for you: {"tile": 3, "rotate": 90, "flipX": true}. Returns a plain-object COPY; assign a new value to write.
     */
    tiles: any;
    /**
     * List of plain tile indices (no flip flags) that block movement; static colliders are generated for them. A flipped or rotated copy of a solid tile is still solid. Empty = nothing collides. Returns a plain-object COPY; assign a new value to write.
     */
    solidTiles: any;
    /**
     * Tint multiplied with the tileset.
     */
    get color(): Color;
    set color(value: ColorLike);
    /**
     * Draw order. Defaults below sprites (-10).
     */
    layer: number;
    /**
     * true: the tiles are shaded by the Light2D entities and SceneSettings.ambientLight, like Sprite.lit. Default false.
     * @since 0.2.0
     */
    lit: boolean;
    /**
     * Lit tilemaps only. Normal map image laid out exactly like the tileset (same size, same tile positions); flipped and rotated tiles turn their normals with them. Empty = flat tiles. (asset path: texture)
     * @since 0.2.0
     */
    normalMap: string;
  }
  /**
   * Emits short-lived particles (smoke, sparks, explosions). Particles interpolate size and color over their lifetime.
   * 
   * Category: 2D
   */
  export interface ParticleEmitterComponent {
    /**
     * Continuously emit while true. Set false to stop spawning (live particles finish).
     */
    emitting: boolean;
    /**
     * Particles emitted per second while emitting.
     */
    rate: number;
    /**
     * Number of particles emitted once when the emitter starts (explosions).
     */
    burst: number;
    /**
     * Upper limit of simultaneously alive particles.
     */
    maxParticles: number;
    /**
     * How long a particle lives, in seconds.
     */
    lifetime: number;
    /**
     * Random +- fraction applied to lifetime (0.2 = +-20%).
     */
    lifetimeVariance: number;
    /**
     * Initial speed in world units per second.
     */
    speed: number;
    /**
     * Random +- fraction applied to speed.
     */
    speedVariance: number;
    /**
     * 2D emission direction in degrees: 0 = right, 90 = up.
     */
    direction: number;
    /**
     * Half-angle of the emission cone in degrees (180 = all directions).
     */
    spread: number;
    /**
     * Constant acceleration [x, y, z] in world units/s^2 (default pulls down).
     */
    get gravity(): Vec3;
    set gravity(value: Vec3Like);
    /**
     * Particle size when born, in world units.
     */
    startSize: number;
    /**
     * Particle size at the end of its life.
     */
    endSize: number;
    /**
     * Particle color when born.
     */
    get startColor(): Color;
    set startColor(value: ColorLike);
    /**
     * Particle color at the end of life (alpha 0 fades out).
     */
    get endColor(): Color;
    set endColor(value: ColorLike);
    /**
     * Particle image. Empty uses a soft round particle. (asset path: texture)
     */
    texture: string;
    /**
     * true = particles stay where they were emitted when the emitter moves; false = they follow the emitter.
     */
    worldSpace: boolean;
    /**
     * Emit in a 3D cone as camera-facing billboards instead of in the 2D plane.
     */
    is3D: boolean;
    /**
     * Draw order. Higher layers draw on top.
     */
    layer: number;
    /**
     * Compositing of particles: additive is ideal for sparks, fire, magic and neon effects.
     */
    blend: "alpha" | "additive" | "multiply";
    /**
     * Destroy the entity automatically once it is not emitting and all its particles died. Use with burst > 0 and emitting = false for one-shot effects (explosions, pickups).
     */
    autoDestroy: boolean;
    /**
     * world: affected by cameras. screen: HUD/UI effects (menu sparks, score bursts) in design pixels, origin TOP-LEFT, +Y down, unaffected by cameras and drawn in the screen-space pass (so with Camera.bloomScreenSpace = false they are not bloomed). direction, gravity and speed keep their world meaning on screen: 90 = up, negative gravity y falls down the screen. Ignored (treated as world) when is3D is true.
     */
    space: "world" | "screen";
    /**
     * Screen space only: screen point the position is relative to ([0,0] top-left, [1,0] top-right, [0.5,0.5] center, [1,1] bottom-right).
     */
    get anchor(): Vec2;
    set anchor(value: Vec2Like);
    /**
     * Screen space only. true: the anchor names a point of the SAFE area, the screen minus the notch, rounded corners and system bars of a phone (screen.safeArea in scripts), instead of the whole screen: anchor [0, 0] is the top-left corner of the safe area, [1, 1] its bottom-right. Keeps HUD and buttons out of the notch. On a screen without cutouts (desktop, most tablets) it changes nothing. Default false.
     * @since 0.2.0
     */
    safeArea: boolean;
  }
  /**
   * Draws a 3D mesh with a PBR material (GGX highlights, sky reflections, normal maps; glTF materials are read). Needs a perspective Camera and (unless unlit) a Light to be visible.
   * 
   * Category: 3D
   */
  export interface MeshRendererComponent {
    /**
     * Built-in shape name ("cube", "sphere", "plane", "cylinder", "capsule", "cone", "quad") or a project-relative path to a .gltf/.glb model (e.g. "assets/models/ship.glb").
     */
    mesh: string;
    /**
     * Base color texture. Empty = none (or the glTF material). (asset path: texture)
     */
    texture: string;
    /**
     * Tangent-space normal map (glTF convention: +Y up, the usual blue-ish image) that adds small-scale relief without more triangles. Empty = none (or the glTF material's normalTexture). Replaces the glTF one when set. (asset path: texture)
     * @since 0.2.0
     */
    normalMap: string;
    /**
     * How strong the normal map is: 0 = flat, 1 = as authored.
     * @since 0.2.0
     */
    normalScale: number;
    /**
     * Base color, multiplied with the texture.
     */
    get color(): Color;
    set color(value: ColorLike);
    /**
     * 0 = plastic/stone, 1 = metal. glTF models use their own metallic value and metallicRoughnessTexture instead.
     */
    metallic: number;
    /**
     * 0 = mirror-smooth, 1 = fully rough/matte. glTF models use their own roughness and metallicRoughnessTexture instead.
     */
    roughness: number;
    /**
     * Light emitted by the surface regardless of lighting (glow). Black = none.
     */
    get emissive(): Color;
    set emissive(value: ColorLike);
    /**
     * true = ignore lighting and draw the flat base color.
     */
    unlit: boolean;
    /**
     * Cast shadows from shadow-casting lights.
     */
    castShadows: boolean;
    /**
     * Receive shadows from shadow-casting lights.
     */
    receiveShadows: boolean;
    /**
     * Texture tiling [u, v]; 2 repeats the texture twice.
     */
    get uvScale(): Vec2;
    set uvScale(value: Vec2Like);
    /**
     * Project-relative path of a custom material, a *.material.json file (e.g. "materials/water.material.json"), or "" (default) for the standard PBR material. The material file names a GLSL snippet whose surface() changes what the standard material computed (albedo, alpha, normal, emission...) and whose optional vertex() moves the vertices, and declares its params, textures, lighting (pbr or unlit) and alphaMode (opaque, clip or blend). The `material.info` command lists a material's params and textures; `shader.compile` compiles it and reports errors with file:line. The material's alphaMode wins over color.a < 1; `unlit` true forces unlit lighting. A material that does not compile draws magenta and logs why. Guide with worked examples: docs/SHADERS.md (`factoria docs read shaders`). (asset path: material)
     * @since 0.2.0
     */
    material: string;
    /**
     * Per-entity overrides of the material's params and textures, as an object keyed by the name declared in the material file: numbers for float params, arrays for vectors and colors ([r, g, b, a]), project-relative paths for textures. Example: {"glow": [1, 0.2, 0, 1], "mask": "textures/leaf.png"}. Unnamed params keep the material's defaults. An entity without overrides batches with the others that share the material. Returns a plain-object COPY; assign a new value to write.
     * @since 0.2.0
     */
    materialParams: any;
    /**
     * Per-material colours of a glTF model, an object keyed by glTF material name: {"Body": [0.2, 0.8, 0.7, 1]}. The colour REPLACES that material's baseColorFactor on its sub-meshes (the texture still multiplies it) and `color` still multiplies the result, so `color` stays the tint of the whole model. Materials not named keep their own colour. Names come from the model (the sub-mesh keeps its material name from import); `factoria validate` checks them and suggests the right one for a typo. Ignored by built-in shapes. Entities that differ only in materialColors are drawn in separate batches. Returns a plain-object COPY; assign a new value to write.
     * @since unreleased
     */
    materialColors: any;
  }
  /**
   * A light source for 3D meshes. A directional light shines along the entity's forward direction (-Z rotated by the Transform), point and spot lights shine from the entity's position.
   * 
   * Category: 3D
   */
  export interface LightComponent {
    /**
     * directional: sun-like, infinite distance. point: radiates in all directions. spot: cone along forward.
     */
    type: "directional" | "point" | "spot";
    /**
     * Light color.
     */
    get color(): Color;
    set color(value: ColorLike);
    /**
     * Brightness multiplier.
     */
    intensity: number;
    /**
     * Point/spot only: distance in meters where the light fades to zero.
     */
    range: number;
    /**
     * Spot only: cone half-angle in degrees.
     */
    spotAngle: number;
    /**
     * Cast shadows. Only supported on directional lights for now.
     */
    castShadows: boolean;
  }
  /**
   * Plays the skeletal animation clips of a skinned glTF model (the model of the MeshRenderer on the same entity, or `model`): one clip at a time with cross-fades, clip events, and an optional small state machine (`params`, `states`, `transitions`). It runs in the fixed step, so headless runs and replays match. Scripts: entity.animator.play("Run", 0.2), .set("speed", 3), .stop(); events reach world.on(name, ...).
   * 
   * Category: 3D
   * @since 0.2.0
   */
  export interface AnimatorComponent {
    /**
     * Project-relative .gltf/.glb path with the skin and the clips. Empty = the `mesh` of the MeshRenderer on the same entity (usual case: leave it empty).
     * @since 0.2.0
     */
    model: string;
    /**
     * Name of the glTF animation playing now (see entity.animator.clips). Assigning it at run time switches clips with a cross-fade of `fade` seconds. Empty = bind pose (the model as exported).
     * @since 0.2.0
     */
    clip: string;
    /**
     * Playback speed multiplier: 1 = authored speed, 2 = twice as fast, 0 = frozen.
     * @since 0.2.0
     */
    speed: number;
    /**
     * true = start over when the clip ends. false = stop on the last pose and send the `anim.finished` event.
     * @since 0.2.0
     */
    loop: boolean;
    /**
     * Set false to pause, true to play.
     * @since 0.2.0
     */
    playing: boolean;
    /**
     * Cross-fade seconds used when `clip` is changed by assignment (play() takes its own).
     * @since 0.2.0
     */
    fade: number;
    /**
     * State machine parameters and their start values, an object such as {"speed": 0, "grounded": true}. Numbers and booleans. Scripts change them with animator.set(name, value); transitions read them. Returns a plain-object COPY; assign a new value to write.
     * @since 0.2.0
     */
    params: any;
    /**
     * State machine states, an object name -> {clip, loop (default true), speed (default 1), onEnter}. `onEnter` is the name of a game event sent when the state starts (world.on). Example: {"idle": {"clip": "Idle"}, "run": {"clip": "Run", "onEnter": "started_running"}}. Returns a plain-object COPY; assign a new value to write.
     * @since 0.2.0
     */
    states: any;
    /**
     * State machine transitions, an array checked in order every step; the first that matches fires. Each: {from (a state, or "*"/omitted = any), to, when, fade (seconds, default 0.2), onFinish}. `when` is conditions joined by "&&": `speed > 0.1`, `grounded`, `!grounded`, `hp <= 0` (operators > >= < <= == !=). A parameter set with animator.trigger(name) is true for one step. onFinish: true fires when the current non-looping clip ended (alone or together with `when`). Returns a plain-object COPY; assign a new value to write.
     * @since 0.2.0
     */
    transitions: any;
    /**
     * Clip events, an array of {clip, time, name}: when the clip's time passes `time` (seconds) the game event `name` is sent once per loop, with data {id, clip, time}; listen with world.on(name, fn). Example: [{"clip": "Walk", "time": 0.3, "name": "footstep"}]. Returns a plain-object COPY; assign a new value to write.
     * @since 0.2.0
     */
    events: any;
    /**
     * State machine: the state the animator is in (the start state when set in the scene; empty = the first state of `states`). Updated as transitions fire.
     * @since 0.2.0
     */
    state: string;
    /**
     * Runtime state: seconds into the current clip. Assigning it seeks (no events fire).
     * @since 0.2.0
     */
    time: number;
    /**
     * Runtime state: current value of every state machine parameter. Returns a plain-object COPY; assign a new value to write.
     * @since 0.2.0
     */
    values: any;
  }
  /**
   * Puts the entity under 2D physics (Box2D). Pair it with a Collider2D. Positions are simulated in world units; gravity comes from the scene settings (gravity2D).
   * 
   * Category: Physics
   */
  export interface RigidBody2DComponent {
    /**
     * static: never moves (walls, floors). dynamic: moved by forces and collisions. kinematic: moved only by setting velocity or the Transform; pushes dynamic bodies but is not pushed back.
     */
    type: "static" | "dynamic" | "kinematic";
    /**
     * Multiplier on world gravity. 0 = floats, negative = falls upwards.
     */
    gravityScale: number;
    /**
     * Air resistance for movement; 0 = none, higher slows faster.
     */
    linearDamping: number;
    /**
     * Air resistance for spinning.
     */
    angularDamping: number;
    /**
     * true = never rotates from collisions (platformer characters).
     */
    fixedRotation: boolean;
    /**
     * true = continuous collision detection, for fast small objects that would tunnel through walls.
     */
    bullet: boolean;
    /**
     * Linear velocity [x, y] in world units per second. Read/write: writes apply before the next physics step.
     */
    get velocity(): Vec2;
    set velocity(value: Vec2Like);
    /**
     * Spin in degrees per second (counter-clockwise positive).
     */
    angularVelocity: number;
  }
  /**
   * Collision shape for 2D physics. Without a RigidBody2D the collider acts as a static obstacle. Colliders collide when each one's layer is included in the other's mask.
   * 
   * Category: Physics
   */
  export interface Collider2DComponent {
    /**
     * Shape type; uses size (box, capsule) or radius (circle).
     */
    shape: "box" | "circle" | "capsule";
    /**
     * box/capsule: [width, height] in world units (capsule is vertical).
     */
    get size(): Vec2;
    set size(value: Vec2Like);
    /**
     * circle: radius in world units.
     */
    radius: number;
    /**
     * Shape center offset [x, y] from the entity origin, in world units.
     */
    get offset(): Vec2;
    set offset(value: Vec2Like);
    /**
     * true = sensor: reports overlaps (onTriggerEnter/Exit) but does not block movement.
     */
    isTrigger: boolean;
    /**
     * Surface friction; 0 = ice, 1 = grippy.
     */
    friction: number;
    /**
     * Bounciness: 0 = no bounce, 1 = perfectly elastic.
     */
    restitution: number;
    /**
     * Mass per area; mass = density * shape area.
     */
    density: number;
    /**
     * Collision category of this collider, 0..31.
     */
    layer: number;
    /**
     * Bitmask of layers this collider collides with. -1 = all layers (bit i = layer i).
     */
    mask: number;
    /**
     * One-way platform: only blocks bodies landing on it from above (the entity's +Y side); bodies can jump up through it from below and pass sideways.
     */
    oneWay: boolean;
  }
  /**
   * A Box2D joint on this entity's body: revolute (a hinge / pendulum / wheel axle), distance (a rope or spring of fixed length), prismatic (a slider along an axis) or weld (glue two bodies together). Both this entity and `connected` need a RigidBody2D (or a Collider2D, which makes a static body); leave `connected` empty to pin to the world. Lengths and anchors are world units (pixels), angles degrees; created when the entity is, destroyed with either body or when the component is removed. Changing type, connected, anchors, axis or collideConnected rebuilds the joint; limits, motor, spring and length apply live, so scripts can toggle a motor. Positive angle, motor speed and translation move THIS entity counter-clockwise / along +axis relative to `connected` (the axis is in the connected body's frame, the world's when empty). Reaction force, angle and translation are read-only runtime fields.
   * 
   * Category: Physics
   * @since 0.2.0
   */
  export interface Joint2DComponent {
    /**
     * revolute: the bodies share the anchor point and may turn around it. distance: the anchors stay `length` apart (a spring when enableSpring). prismatic: the anchor slides along `axis` and the bodies cannot turn relative to each other. weld: the bodies stay rigidly together (soft with springHertz > 0).
     * @since 0.2.0
     */
    type: "revolute" | "distance" | "prismatic" | "weld";
    /**
     * Id of the other entity (it needs a body). Empty (leave it out, null or "") = the joint is fixed to the world and connectedAnchor is a world position.
     * @since 0.2.0
     */
    get connected(): Entity | null;
    set connected(value: EntityLike);
    /**
     * Joint point [x, y] in THIS entity's local space (scaled by Transform.scale), world units from its origin.
     * @since 0.2.0
     */
    get anchor(): Vec2;
    set anchor(value: Vec2Like);
    /**
     * Joint point [x, y] in the connected entity's local space; a world position when `connected` is empty. For a hinge both anchors name the same spot in the world when the joint is created.
     * @since 0.2.0
     */
    get connectedAnchor(): Vec2;
    set connectedAnchor(value: Vec2Like);
    /**
     * Prismatic only: slide direction [x, y] in this entity's local space; normalised. [1, 0] slides along local x.
     * @since 0.2.0
     */
    get axis(): Vec2;
    set axis(value: Vec2Like);
    /**
     * true: the two joined bodies still collide with each other (default false).
     * @since 0.2.0
     */
    collideConnected: boolean;
    /**
     * Distance only: rest length in world units. 0 = the distance between the anchors when the joint is created.
     * @since 0.2.0
     */
    length: number;
    /**
     * Limit the motion: revolute angle, prismatic translation, or distance length (needs enableSpring to stretch).
     * @since 0.2.0
     */
    enableLimit: boolean;
    /**
     * Lower limit: revolute degrees (between -178 and 178, 0 = the pose at creation), prismatic translation in world units (0 = anchors coincide), distance minimum length in world units.
     * @since 0.2.0
     */
    lowerLimit: number;
    /**
     * Upper limit, same units as lowerLimit.
     * @since 0.2.0
     */
    upperLimit: number;
    /**
     * Drive the joint at motorSpeed with at most maxMotorTorque. Revolute and prismatic; a distance joint motor works only with enableSpring.
     * @since 0.2.0
     */
    enableMotor: boolean;
    /**
     * Target speed: revolute degrees per second (positive = counter-clockwise), prismatic / distance world units per second.
     * @since 0.2.0
     */
    motorSpeed: number;
    /**
     * Strongest push the motor may apply: a torque for a revolute joint, a force for prismatic and distance joints (the same units as physics.applyForce). 0 = the motor does nothing.
     * @since 0.2.0
     */
    maxMotorTorque: number;
    /**
     * Revolute, prismatic, distance: make the free motion springy, pulling towards the rest pose (angle 0, translation 0, `length`).
     * @since 0.2.0
     */
    enableSpring: boolean;
    /**
     * Spring stiffness in cycles per second (about 1 = a slow bounce, 5 = stiff). Weld joints: 0 = rigid, above 0 = a soft weld (no enableSpring needed).
     * @since 0.2.0
     */
    springHertz: number;
    /**
     * Spring damping: 0 = bounces on, 1 = settles without overshoot.
     * @since 0.2.0
     */
    dampingRatio: number;
    /**
     * Runtime: the force [x, y] the joint applied last step to hold the bodies (same units as physics.applyForce). Compare it with a limit to break a rope. Read-only.
     * @since 0.2.0
     */
    readonly reactionForce: Vec2;
    /**
     * Runtime: the torque the joint applied last step. Read-only.
     * @since 0.2.0
     */
    readonly reactionTorque: number;
    /**
     * Runtime: revolute and weld: the current joint angle in degrees (0 = the pose at creation). Read-only.
     * @since 0.2.0
     */
    readonly angle: number;
    /**
     * Runtime: prismatic: the current slide position; distance: the current length, in world units. Read-only.
     * @since 0.2.0
     */
    readonly translation: number;
  }
  /**
   * Simple 3D physics body for arcade games (spheres, oriented boxes, capsules and convex hulls; a triangle-mesh collider is for static level geometry only). Pair it with a Collider3D; add a Joint3D to hinge it to the world or to another body. A capsule body with lockRotation is a simple physics character (for a controller that slides, climbs steps and checks slopes use CharacterController3D instead). Gravity comes from scene settings (gravity3D). Fast bodies are swept against every solid collider (continuous collision, automatic). A dynamic BOX is a rigid body: collisions and friction apply torque at the contact points (inertia from its size and mass), so it tips over a ledge, tumbles and settles on a face; set lockRotation for a character or an upright crate. A sphere is an arcade rolling ball by default (rollWithMotion = true: spun to match its motion, contacts never turn it); with rollWithMotion = false it is a rigid body too: friction at the contact point spins it, so it rolls down slopes and a glancing hit spins it. A tumbling box precesses like a real one. A dynamic body that stays nearly still for half a second falls asleep together with the bodies it touches (no cost, no events) and wakes when touched by something moving, when gameplay writes its position, rotation or velocity, applies a force, or when what it rests on goes away.
   * 
   * Category: Physics
   */
  export interface RigidBody3DComponent {
    /**
     * static: never moves. dynamic: moved by gravity and collisions. kinematic: moved only by velocity/Transform.
     */
    type: "static" | "dynamic" | "kinematic";
    /**
     * Mass in kilograms (affects collision responses between dynamic bodies).
     */
    mass: number;
    /**
     * Multiplier on world gravity.
     */
    gravityScale: number;
    /**
     * Air resistance; 0 = none.
     */
    linearDamping: number;
    /**
     * Linear velocity [x, y, z] in meters per second. Read/write.
     */
    get velocity(): Vec3;
    set velocity(value: Vec3Like);
    /**
     * Rotation speed in degrees/second around x, y, z; integrated into Transform.rotation each step. Read/write (writing it wakes a sleeping body). A box spinning about a non-principal axis keeps its angular momentum, so this vector wanders (precession) while it tumbles.
     */
    get angularVelocity(): Vec3;
    set angularVelocity(value: Vec3Like);
    /**
     * Sphere colliders only. true (default, arcade ball): while it touches the ground the sphere is spun to match its rolling motion (sets angularVelocity from the horizontal velocity) and uses rolling resistance (rollingFriction) instead of sliding friction; contacts never turn it, so setting velocity every frame steers it exactly. false: the sphere is a rigid body (solid-sphere inertia 2/5 m r^2): friction at the contact point spins it, so on a slope it rolls (spin = speed / radius) and a glancing hit makes it spin; on flat ground it keeps rolling until angularDamping / linearDamping or an obstacle stops it. Add lockRotation for a ball that slides and is never spun by contacts.
     */
    rollWithMotion: boolean;
    /**
     * Rolling resistance of a dynamic sphere with rollWithMotion = true: friction cap = rollingFriction * normal force, replacing the sliding friction of its contacts, so on flat ground its speed decays by about rollingFriction * gravity per second (default 0.02 rolls about 23 m from 3 m/s; 0 never slows down). Ignored when rollWithMotion is false (then Collider3D.friction acts at the contact point of the rigid sphere) and for boxes.
     */
    rollingFriction: number;
    /**
     * Rotation drag of a dynamic body: angularVelocity is divided by (1 + dt * angularDamping) every step, so 0 = a spinning body keeps spinning in the air, larger values slow it down faster.
     */
    angularDamping: number;
    /**
     * true = collisions and friction never turn this body (a dynamic box, or a sphere with rollWithMotion = false): it stays upright and slides, as boxes did before rotation dynamics. Use it for characters and upright crates. angularVelocity and Transform.rotation written by gameplay still turn it. A rollWithMotion sphere is never turned by contacts either way.
     */
    lockRotation: boolean;
  }
  /**
   * Collision shape for 3D physics: box, sphere, capsule, convex hull or triangle mesh. Boxes, capsules and meshes are ORIENTED: they follow the entity's world rotation (parents included), so a box rotated 45 degrees blocks at its rotated edge. Scaled by the Transform scale. A `mesh` collider is for level geometry and needs a static body (no RigidBody3D, or type static): a dynamic or kinematic body with one is reported as an error and ignored.
   * 
   * Category: Physics
   */
  export interface Collider3DComponent {
    /**
     * box: uses size. sphere: uses radius. capsule: uses radius and height, along the entity's local Y. convex: the convex hull of the vertices of `mesh` (any dynamic body, fast). mesh: the triangles of `mesh` (static level geometry only; concave shapes, ramps, terrain).
     */
    shape: "box" | "sphere" | "capsule" | "convex" | "mesh";
    /**
     * box: full extents [x, y, z] in meters along the entity's own (rotated) axes, before Transform scale.
     */
    get size(): Vec3;
    set size(value: Vec3Like);
    /**
     * sphere and capsule: radius in meters.
     */
    radius: number;
    /**
     * capsule: full height in meters from tip to tip along the entity's local Y (so the straight part is height - 2 * radius; never less than 2 * radius).
     * @since 0.2.0
     */
    height: number;
    /**
     * convex / mesh shapes: a built-in primitive name ("cube", "sphere", "plane", "cylinder", "capsule", "cone", "quad", the same sizes as MeshRenderer) or a project-relative path to a .gltf/.glb model (every mesh node of the file, with its node transform). Use the same value as the MeshRenderer so the collider matches what is drawn.
     * @since 0.2.0
     */
    mesh: string;
    /**
     * Shape center offset [x, y, z] from the entity origin, scaled and rotated with the entity (for convex and mesh: where the model's own origin sits).
     */
    get offset(): Vec3;
    set offset(value: Vec3Like);
    /**
     * true = sensor: reports overlaps but does not block movement.
     */
    isTrigger: boolean;
    /**
     * Surface friction; 0 = ice, 1 = grippy.
     */
    friction: number;
    /**
     * Bounciness: 0 = none, 1 = perfectly elastic.
     */
    restitution: number;
    /**
     * Collision category of this collider, 0..31.
     */
    layer: number;
    /**
     * Bitmask of layers this collider collides with. -1 = all layers.
     */
    mask: number;
    /**
     * true = a NavMesh3D does not bake this collider into the ground (a crate, a gate, a door that moves): it blocks the navigation cells it covers, plus the agent's radius, wherever it is NOW, and the affected cells are marked again each time it moves, so nav.findPath goes around it. Use it on anything that moves or is removed during play; static level geometry needs nothing.
     * @since unreleased
     */
    navObstacle: boolean;
    /**
     * true = a NavMesh3D does not bake this collider either, but its TOP surface is walkable wherever it is NOW: put it on a kinematic body or a body held by a joint that characters stand on (a rope-bridge plank, a seesaw, a moving platform, a lift). The cells it covers are added to the navigation mesh and marked again each time it moves (only the cells it left and entered), and they join the ground around them within stepHeight, so nav.findPath crosses a bridge, rides a platform that is docked and says `disconnected` while it is away. The ground under it is blocked meanwhile. Surfaces steeper than maxSlope are not walkable. Wins over navObstacle when both are set.
     * @since unreleased
     */
    navWalkable: boolean;
  }
  /**
   * Joins this entity's RigidBody3D to another body or to the world: a hinge (door, pendulum, wheel), a ball joint (rope link, ragdoll shoulder) or a fixed joint (welds the two bodies). Solved together with the contacts. Put it on the body that swings; set `connected` to the other entity (empty = the world). A jointed dynamic body is always a rotating rigid body. Bodies joined together fall asleep together once the whole chain is at rest (a motor keeps its bodies awake), so a settled rope bridge costs nothing. A chain of three or more jointed bodies is solved with extra iterations, so planks of any width hang still without heavy damping. The joint holds the pose the bodies have when it is created (autoAnchor); hinge limits are angles relative to that pose.
   * 
   * Category: Physics
   * @since 0.2.0
   */
  export interface Joint3DComponent {
    /**
     * hinge: rotation about `axis` only. ball: free rotation about the anchor point. fixed: no relative movement at all.
     * @since 0.2.0
     */
    type: "hinge" | "ball" | "fixed";
    /**
     * The other body's entity id. Empty (leave it out, null or "") = the world: the anchor point stays where it is. The entity needs a RigidBody3D (any type) or a Collider3D.
     * @since 0.2.0
     */
    get connected(): Entity | null;
    set connected(value: EntityLike);
    /**
     * Joint point [x, y, z] in THIS entity's local space (scaled and rotated with it): the pendulum's pivot, the door's hinge edge.
     * @since 0.2.0
     */
    get anchor(): Vec3;
    set anchor(value: Vec3Like);
    /**
     * Joint point in the connected entity's local space, or a world position when `connected` is empty. Ignored while autoAnchor is true.
     * @since 0.2.0
     */
    get connectedAnchor(): Vec3;
    set connectedAnchor(value: Vec3Like);
    /**
     * true (default): connectedAnchor is computed from `anchor` when the joint is created, so the bodies stay joined exactly where they are. false: use connectedAnchor as given (the bodies are pulled together).
     * @since 0.2.0
     */
    autoAnchor: boolean;
    /**
     * hinge: the rotation axis [x, y, z] in THIS entity's local space (normalized).
     * @since 0.2.0
     */
    get axis(): Vec3;
    set axis(value: Vec3Like);
    /**
     * hinge: keep the angle between lowerLimit and upperLimit.
     * @since 0.2.0
     */
    useLimits: boolean;
    /**
     * hinge: lowest angle in degrees, relative to the pose the joint was created in (0 there).
     * @since 0.2.0
     */
    lowerLimit: number;
    /**
     * hinge: highest angle in degrees (same reference).
     * @since 0.2.0
     */
    upperLimit: number;
    /**
     * hinge: drive the joint at motorSpeed (a wheel, an opening door).
     * @since 0.2.0
     */
    useMotor: boolean;
    /**
     * hinge motor: target speed in degrees/second of this body relative to the connected one, about the axis.
     * @since 0.2.0
     */
    motorSpeed: number;
    /**
     * hinge motor: the most torque in newton-meters the motor may apply; a heavy or loaded body needs more.
     * @since 0.2.0
     */
    maxMotorTorque: number;
    /**
     * false (default): the two joined bodies do not collide with each other. true: they do.
     * @since 0.2.0
     */
    collideConnected: boolean;
    /**
     * Resistance to the two bodies turning relative to each other, per second: each physics sub-step the relative angular velocity (about the axis for a hinge, every axis for a ball joint) is divided by 1 + damping * dt. 0 (default) = free; 1 takes the swing out of a door in a few seconds; 2..5 stops a rope-bridge plank ringing. A chain of 3+ bodies already settles without it.
     * @since unreleased
     */
    damping: number;
    /**
     * Runtime: the current hinge angle in degrees, relative to the creation pose. Read-only.
     * @since 0.2.0
     */
    readonly angle: number;
    /**
     * Runtime, read only: true while a motor (useMotor with a non-zero motorSpeed) cannot turn the joint: the relative speed stayed below a tenth of motorSpeed for a quarter of a second, e.g. a gate pushing against a wall, or a maxMotorTorque too low for the load. False when the hinge simply reached its limit. Scripts read it to open another way or raise the torque. Read-only.
     * @since unreleased
     */
    readonly stalled: boolean;
  }
  /**
   * A walking character: a kinematic capsule that moves and slides. Move it with physics.moveCharacter(entity, [dx, dy, dz]) (Unity-style: you add gravity and jumping to the move yourself, using isGrounded) or set `velocity`. It slides along walls and ceilings, climbs steps up to stepOffset, will not climb slopes steeper than slopeLimit (it slides down them), stays on the ground going down ramps, is carried by the kinematic platform it stands on (carriedByPlatforms), weighs on the dynamic body below it (applyWeight, mass: a seesaw tips) and pushes the free dynamic bodies it walks into (pushStrength). Other bodies treat it as a kinematic capsule. The entity origin is the capsule centre (plus `center`). Do not add RigidBody3D or Collider3D to the same entity.
   * 
   * Category: Physics
   * @since 0.2.0
   */
  export interface CharacterController3DComponent {
    /**
     * Capsule radius in meters (scaled by Transform.scale).
     * @since 0.2.0
     */
    radius: number;
    /**
     * Capsule height in meters from tip to tip (never less than 2 * radius).
     * @since 0.2.0
     */
    height: number;
    /**
     * Capsule centre [x, y, z] from the entity origin, in meters.
     * @since 0.2.0
     */
    get center(): Vec3;
    set center(value: Vec3Like);
    /**
     * Highest step in meters the character walks up (and the distance it snaps down to stay on the ground).
     * @since 0.2.0
     */
    stepOffset: number;
    /**
     * Steepest slope in degrees the character can walk up; steeper surfaces count as walls.
     * @since 0.2.0
     */
    slopeLimit: number;
    /**
     * Gap in meters kept between the capsule and the surfaces it touches; avoids jitter and tunnelling.
     * @since 0.2.0
     */
    skin: number;
    /**
     * Collision category of the character, 0..31.
     * @since 0.2.0
     */
    layer: number;
    /**
     * Bitmask of layers the character collides with. -1 = all layers.
     * @since 0.2.0
     */
    mask: number;
    /**
     * Velocity in meters/second [x, y, z]: when not zero the character moves by velocity * dt every physics step (no gravity is added). Use it or moveCharacter, not both for the same motion.
     * @since 0.2.0
     */
    get velocity(): Vec3;
    set velocity(value: Vec3Like);
    /**
     * When true (default) a kinematic RigidBody3D the character stands on carries it: every physics step it moves with the platform's displacement (velocity, or a teleport by script) and turns about the platform's centre with its angularVelocity (the character also yaws with it). Set false and it stays where it is, so a moving platform slides out from under it and the script must carry it.
     * @since unreleased
     */
    carriedByPlatforms: boolean;
    /**
     * When true (default) a character standing on a dynamic RigidBody3D presses on it with mass * gravity at its feet, every physics step: a seesaw tips towards the side it stands on, a bridge plank or a crate feels the load. Set false for a character that weighs nothing.
     * @since unreleased
     */
    applyWeight: boolean;
    /**
     * Weight in kilograms pressed on the dynamic body below when applyWeight is on (see applyWeight).
     * @since unreleased
     */
    mass: number;
    /**
     * How hard the character shoves the free dynamic bodies it walks into: 1 (default) gives them its own speed, 0.5 half of it, 0 none (they block it like a wall). A body held by a Joint3D (a seesaw on its pivot, a bridge plank, a door) is never shoved whatever the value.
     * @since unreleased
     */
    pushStrength: number;
    /**
     * Runtime: true when the last move ended standing on walkable ground (slope up to slopeLimit). Read-only.
     * @since 0.2.0
     */
    readonly isGrounded: boolean;
    /**
     * Runtime: the normal of the ground under the character after the last move (up when airborne). Read-only.
     * @since 0.2.0
     */
    readonly groundNormal: Vec3;
  }
  /**
   * A navigation mesh for path finding on 3D ground. It is baked from the STATIC colliders (no RigidBody3D, or a static one) inside a box around this entity, when the scene loads (autoBake) or with the nav.bake command: the box is cut into cells of cellSize; a cell is walkable where the ground is not steeper than maxSlope, has agentHeight of free space above it and lies at least agentRadius from a wall or a drop; neighbouring cells connect when their heights differ by at most stepHeight. Then nav.findPath(from, to) in scripts (the nav.find_path command) returns the points of a path over it. A collider with Collider3D.navObstacle is not baked: it blocks the cells it covers while it is there; one with Collider3D.navWalkable (a bridge, a lift) adds its top surface while it is there, and NavLink3D entities add off-mesh links. The mesh is deterministic: the same colliders always give the same cells. See docs/NAVIGATION.md.
   * 
   * Category: Physics
   * @since unreleased
   */
  export interface NavMesh3DComponent {
    /**
     * Size [x, y, z] in meters of the baked box, centred on the entity's world position; rotation and scale are ignored. Cover the whole level: ground outside is not walkable and the box edge counts as a drop. y must reach from below the lowest floor to above the highest head.
     * @since unreleased
     */
    get size(): Vec3;
    set size(value: Vec3Like);
    /**
     * Width of one cell on the ground plane, meters. Smaller = finer paths, more memory and a slower bake (cells = x/cellSize * z/cellSize, at most 4 million). Walls thinner than half a cell can be missed.
     * @since unreleased
     */
    cellSize: number;
    /**
     * Heights are rounded to a multiple of this, meters; a path is up to half of it above or below the true surface. Keep it at most stepHeight / 4.
     * @since unreleased
     */
    cellHeight: number;
    /**
     * Radius in meters of the walker the mesh is made for: walkable cells stay this far from walls and drops, so a body of that radius never touches them. findPath with a bigger radius is an error (bake another NavMesh3D for the bigger agent).
     * @since unreleased
     */
    agentRadius: number;
    /**
     * Height in meters of the walker; ground with less free space above it (under a low ceiling or table) is not walkable.
     * @since unreleased
     */
    agentHeight: number;
    /**
     * Highest step in meters the walker climbs; a higher ledge is a wall. Match CharacterController3D.stepOffset.
     * @since unreleased
     */
    stepHeight: number;
    /**
     * Steepest walkable ground in degrees; steeper ground is a wall. Match CharacterController3D.slopeLimit.
     * @since unreleased
     */
    maxSlope: number;
    /**
     * true (default): bake when the scene loads and again when a static collider is added, moved or removed. false: only the nav.bake command bakes (and a scene without a bake has no paths).
     * @since unreleased
     */
    autoBake: boolean;
    /**
     * false = nav.findPath ignores this mesh (and it is not baked).
     * @since unreleased
     */
    enabled: boolean;
    /**
     * Runtime: how many cells can be walked on after the last bake (read only). Read-only.
     * @since unreleased
     */
    readonly walkableCells: number;
    /**
     * Runtime: how many separate walkable areas the last bake found; two points in different areas have no path (read only). Read-only.
     * @since unreleased
     */
    readonly regions: number;
  }
  /**
   * An off-mesh link of the NavMesh3D: a jump across a gap, a climb up a ladder, a drop off a ledge. The walkable cells do not join the two places, so this joins them: the link runs from this entity's world position to `end` (both are moved onto the nearest walkable cell). nav.findPath may take it, and its result lists where in `links` (the index of the point where the link starts and the link's entity), so a script makes the character jump or climb there; the next point is where it ends. See docs/NAVIGATION.md.
   * 
   * Category: Physics
   * @since unreleased
   */
  export interface NavLink3DComponent {
    /**
     * World position [x, y, z] where the link ends. The entity's own world position is where it starts. Both ends must be within the NavMesh3D box and near walkable ground (agentRadius + two cells horizontally, about stepHeight up and agentHeight down); a link whose end is not is ignored, and nav.info says so.
     * @since unreleased
     */
    get end(): Vec3;
    set end(value: Vec3Like);
    /**
     * true (default): the path may also go from `end` to the entity. false: one way only, from the entity to `end` (a drop, a jump that cannot be climbed back).
     * @since unreleased
     */
    bidirectional: boolean;
    /**
     * Extra path length in meters added to the straight distance between the two ends. 0 = as long as the straight line; raise it so a path prefers walking around when that is not much longer.
     * @since unreleased
     */
    cost: number;
  }
  /**
   * Plays a sound clip from the entity. Set playOnStart to start automatically, or set `playing` from a script to trigger it.
   * 
   * Category: Audio
   */
  export interface AudioSourceComponent {
    /**
     * Project-relative path of the sound (.wav, .ogg, .mp3 or .qoa). (asset path: audio)
     */
    clip: string;
    /**
     * Loudness multiplier, 0 (silent) to 1 (full).
     */
    volume: number;
    /**
     * Playback speed multiplier; 2 = one octave higher and twice as fast.
     */
    pitch: number;
    /**
     * Restart the clip when it ends.
     */
    loop: boolean;
    /**
     * Start playing when the entity spawns / the scene loads.
     */
    playOnStart: boolean;
    /**
     * Runtime state: true while a voice is playing. Set true to play, false to stop.
     */
    playing: boolean;
    /**
     * true = pan and attenuate relative to the AudioListener; false = plain stereo (music, UI).
     */
    spatial: boolean;
    /**
     * Spatial only: distance in world units where the volume reaches 0.
     */
    range: number;
  }
  /**
   * The 'ears' for spatial audio, usually on the camera or player. If no listener exists, the primary camera is used.
   * 
   * Category: Audio
   */
  export interface AudioListenerComponent {
    /**
     * Master volume multiplier for everything this listener hears.
     */
    volume: number;
  }
  /**
   * Container widget: a background rectangle (solid or 9-slice) whose children are laid out in a row, a column or a grid. Children are ordinary entities parented to it (Button, Toggle, Slider, TextField, Text, other Panels...). Every UI widget is SCREEN SPACE only (design pixels, origin top-left, +Y down; no `space` field); rotation and scale of UI entities are ignored by layout and hit-testing. Widgets draw above the world and above HUD Text; events (ui.click, ui.change...) and focus are in docs/SCRIPTING.md.
   * 
   * Category: UI
   * @since 0.1.6
   */
  export interface PanelComponent {
    /**
     * Size [w, h] in design pixels. The default depends on the kind (Button 240 x 56, Toggle 240 x 40, Slider 320 x 40, TextField 320 x 48, Panel and ScrollList 320 x 240, TouchStick 200 x 200, TouchButton 96 x 96, Captions 960 x 180, Video 640 x 360). A Panel with fit = true recomputes it every frame.
     * @since 0.1.6
     */
    get size(): Vec2;
    set size(value: Vec2Like);
    /**
     * Which point of the widget sits on the position: [0.5, 0.5] = its centre (default), [0, 1] = top-left corner, [1, 0] = bottom-right. Same meaning as Shape2D.pivot in screen space: +Y is down on screen but pivot [0, 1] is still the visual top-left. Layout does not care about the pivot of its children.
     * @since 0.1.6
     */
    get pivot(): Vec2;
    set pivot(value: Vec2Like);
    /**
     * Screen point the position is relative to, as a fraction of the screen: [0, 0] top-left (default), [1, 0] top-right, [0.5, 0.5] centre. Anchor [0.5, 0.5] with position [0, 0] centres the widget on any aspect ratio. The anchor of the widget itself is used, not its parent's: children of a Panel normally keep anchor [0, 0] and are placed by the Panel's layout.
     * @since 0.1.6
     */
    get anchor(): Vec2;
    set anchor(value: Vec2Like);
    /**
     * Screen space only. true: the anchor names a point of the SAFE area, the screen minus the notch, rounded corners and system bars of a phone (screen.safeArea in scripts), instead of the whole screen: anchor [0, 0] is the top-left corner of the safe area, [1, 1] its bottom-right. Keeps HUD and buttons out of the notch. On a screen without cutouts (desktop, most tablets) it changes nothing. Default false (true on TouchStick and TouchButton).
     * @since 0.2.0
     */
    safeArea: boolean;
    /**
     * Draw order of the background; higher is on top. Defaults to 200, above HUD Text (layer 100). The label draws at layer + 1 and the focus ring at layer + 2. Pointer hit-testing follows the same order: the highest layer, then the latest entity, under the pointer is the hovered widget.
     * @since 0.1.6
     */
    layer: number;
    /**
     * Background colour, multiplied with `texture` when there is one. Hovered widgets are brightened, pressed ones darkened, non-interactable ones drawn at half alpha. Accepts [r,g,b,a], "#rrggbb" or a name.
     * @since 0.1.6
     */
    get color(): Color;
    set color(value: ColorLike);
    /**
     * Optional background image (project path), drawn as a 9-slice (see `slice`) with nearest-neighbour sampling, so pixel art stays crisp. Empty draws a solid rectangle of `color`. (asset path: texture)
     * @since 0.1.6
     */
    texture: string;
    /**
     * 9-slice borders in TEXTURE pixels [left, top, right, bottom]. The four corners are drawn unscaled (1 texture pixel = 1 design pixel), the edges stretch along one axis and the centre along both, so one small image gives panels of any size. [0, 0, 0, 0] (default) stretches the whole image. When the widget is smaller than left + right (or top + bottom) the borders shrink proportionally.
     * @since 0.1.6
     */
    get slice(): Vec3 & { w: number };
    set slice(value: readonly number[] | { x: number; y: number; z: number; w: number });
    /**
     * How children are placed, every frame: none = they keep their own positions; row / column = one after the other along that axis; grid = `columns` per row, every cell as large as the largest child. Children are the active child entities that have a size (a widget, or a Text / Sprite / Shape2D in screen space); the rest are skipped. A child's own position, anchor and pivot do not matter: layout moves its Transform.position so it lands in its slot.
     * @since 0.1.6
     */
    layout: "none" | "row" | "column" | "grid";
    /**
     * Gap in design pixels between children (a grid uses it on both axes).
     * @since 0.1.6
     */
    spacing: number;
    /**
     * Space [left, top, right, bottom] between the panel's edge and its children.
     * @since 0.1.6
     */
    get padding(): Vec3 & { w: number };
    set padding(value: readonly number[] | { x: number; y: number; z: number; w: number });
    /**
     * Grid only: number of columns.
     * @since 0.1.6
     */
    columns: number;
    /**
     * Cross-axis alignment: horizontal in a column, vertical in a row, both axes inside a grid cell. start = left / top, end = right / bottom (a panel with `direction` rtl, or auto in a right-to-left language, swaps left and right: start = right).
     * @since 0.1.6
     */
    align: "start" | "center" | "end";
    /**
     * Main-axis placement of the whole run of children inside the padded box: start = packed at the left / top, center, end = packed at the right / bottom (with a right-to-left `direction`, start = the right edge). A grid is placed as one block on both axes.
     * @since 0.1.6
     */
    justify: "start" | "center" | "end";
    /**
     * Horizontal reading direction of the layout. ltr (default) = a row runs left to right and start means left. rtl = the first child of a row is at the right, a grid fills its columns from the right and align / justify `start` means the right edge. auto = ltr in a left-to-right language and rtl in Arabic, Hebrew and the other right-to-left languages (i18n.direction): one menu that mirrors itself.
     * @since 0.2.0
     */
    direction: "ltr" | "auto" | "rtl";
    /**
     * true: `size` is recomputed every frame as the content size + padding (needs layout row, column or grid); the pivot then decides which point of the fitted box stays on the position.
     * @since 0.1.6
     */
    fit: boolean;
    /**
     * true: every Button, Toggle and Slider with autoSize anywhere inside this panel (children, and the children of the panels and lists inside it; active ones only) takes the size of the largest of them, width and height separately, every layout. Widgets without autoSize keep their size and do not count. Use it for a grid of level buttons as wide as the widest label.
     * @since 0.2.0
     */
    uniformSize: boolean;
    /**
     * Layout used instead of `layout` when the panel laid out with `layout` would not fit the screen (none = never switch). The panel leaves the screen when its content size + padding, or the size of the outermost fit Panel around it, is wider than the screen and `layout` is row or grid, or taller and `layout` is column or grid. The deepest panels switch first, so a menu changes one level at a time until it fits; the choice is made again every frame, so it follows the text size and the language and goes back to `layout` when the texts shrink. Example: a column of two blocks with fallbackLayout "row" stands them side by side at a big text size; a row of buttons with fallbackLayout "column" stacks them. Scripts that must adapt read `usingFallback`.
     * @since 0.2.0
     */
    fallbackLayout: "none" | "row" | "column" | "grid";
    /**
     * Runtime: true while the panel is laid out with `fallbackLayout` instead of `layout`. Read-only.
     * @since 0.2.0
     */
    readonly usingFallback: boolean;
  }
  /**
   * Clickable button with a text label. Activated by the mouse / a touch, or by ui_submit (Enter, Space, gamepad A) while it has focus; the event is ui.click {id}. Focus rules and the other widgets: see Panel.
   * 
   * Category: UI
   * @since 0.1.6
   */
  export interface ButtonComponent {
    /**
     * Size [w, h] in design pixels. The default depends on the kind (Button 240 x 56, Toggle 240 x 40, Slider 320 x 40, TextField 320 x 48, Panel and ScrollList 320 x 240, TouchStick 200 x 200, TouchButton 96 x 96, Captions 960 x 180, Video 640 x 360). A Panel with fit = true recomputes it every frame.
     * @since 0.1.6
     */
    get size(): Vec2;
    set size(value: Vec2Like);
    /**
     * Which point of the widget sits on the position: [0.5, 0.5] = its centre (default), [0, 1] = top-left corner, [1, 0] = bottom-right. Same meaning as Shape2D.pivot in screen space: +Y is down on screen but pivot [0, 1] is still the visual top-left. Layout does not care about the pivot of its children.
     * @since 0.1.6
     */
    get pivot(): Vec2;
    set pivot(value: Vec2Like);
    /**
     * Screen point the position is relative to, as a fraction of the screen: [0, 0] top-left (default), [1, 0] top-right, [0.5, 0.5] centre. Anchor [0.5, 0.5] with position [0, 0] centres the widget on any aspect ratio. The anchor of the widget itself is used, not its parent's: children of a Panel normally keep anchor [0, 0] and are placed by the Panel's layout.
     * @since 0.1.6
     */
    get anchor(): Vec2;
    set anchor(value: Vec2Like);
    /**
     * Screen space only. true: the anchor names a point of the SAFE area, the screen minus the notch, rounded corners and system bars of a phone (screen.safeArea in scripts), instead of the whole screen: anchor [0, 0] is the top-left corner of the safe area, [1, 1] its bottom-right. Keeps HUD and buttons out of the notch. On a screen without cutouts (desktop, most tablets) it changes nothing. Default false (true on TouchStick and TouchButton).
     * @since 0.2.0
     */
    safeArea: boolean;
    /**
     * Draw order of the background; higher is on top. Defaults to 200, above HUD Text (layer 100). The label draws at layer + 1 and the focus ring at layer + 2. Pointer hit-testing follows the same order: the highest layer, then the latest entity, under the pointer is the hovered widget.
     * @since 0.1.6
     */
    layer: number;
    /**
     * Background colour, multiplied with `texture` when there is one. Hovered widgets are brightened, pressed ones darkened, non-interactable ones drawn at half alpha. Accepts [r,g,b,a], "#rrggbb" or a name.
     * @since 0.1.6
     */
    get color(): Color;
    set color(value: ColorLike);
    /**
     * Optional background image (project path), drawn as a 9-slice (see `slice`) with nearest-neighbour sampling, so pixel art stays crisp. Empty draws a solid rectangle of `color`. (asset path: texture)
     * @since 0.1.6
     */
    texture: string;
    /**
     * 9-slice borders in TEXTURE pixels [left, top, right, bottom]. The four corners are drawn unscaled (1 texture pixel = 1 design pixel), the edges stretch along one axis and the centre along both, so one small image gives panels of any size. [0, 0, 0, 0] (default) stretches the whole image. When the widget is smaller than left + right (or top + bottom) the borders shrink proportionally.
     * @since 0.1.6
     */
    get slice(): Vec3 & { w: number };
    set slice(value: readonly number[] | { x: number; y: number; z: number; w: number });
    /**
     * Font of the label: project path of a .ttf, empty = the built-in font (same values as Text.font). (asset path: font)
     * @since 0.1.6
     */
    font: string;
    /**
     * Localization key, e.g. "menu.play" (docs/LOCALIZATION.md). Empty (default) = not translated. With a key, the runtime writes the translation into the widget's own text: Button.text, Toggle.label, Slider.label, or TextField.placeholder (never TextField.text, which is what the player typed). It does so when a scene or prefab loads, every frame and when the language changes, so that field is overwritten at run time while `key` is set. A key that no string table has keeps the text written in the field and logs one warning.
     * @since 0.2.0
     */
    key: string;
    /**
     * Values for the {placeholders} of `key`, an object of name -> string or number: {"score": 12} fills "Score: {score}" (and `count` picks the form of a plural entry). Set it once from a script (`entity.set("Text", { keyArgs: { score } })` or `scene.set_component`) instead of rewriting the text every frame: the engine formats the translation with them when the text is localized, when the args change and when the language changes, so a language switch keeps them. Empty (default) = no arguments. Ignored while `key` is empty. Returns a plain-object COPY; assign a new value to write.
     * @since unreleased
     */
    keyArgs: any;
    /**
     * Label glyph height in design pixels.
     * @since 0.1.6
     */
    fontSize: number;
    /**
     * > 0: the player's text size (ui.textScale) stops growing this text at this scale, so a heading or a round button label does not outgrow its place: 1.3 means it is drawn at most 1.3 times its fontSize however big the option is. It only limits growth: at a text size below the cap it is drawn at the player's size. 0 (default) = no cap. Measuring (autoSize, layout, ui.measureText, ui.rectOf) and drawing use the same capped size.
     * @since unreleased
     */
    maxTextScale: number;
    /**
     * Label colour.
     * @since 0.1.6
     */
    get textColor(): Color;
    set textColor(value: ColorLike);
    /**
     * Colour of the focus ring, the slider fill and knob, the toggle check mark and the text caret.
     * @since 0.1.6
     */
    get accentColor(): Color;
    set accentColor(value: ColorLike);
    /**
     * false: the widget is drawn at half alpha and is never hovered, focused or clicked, so it sends no ui events. A focused widget that becomes non-interactable loses focus.
     * @since 0.1.6
     */
    interactable: boolean;
    /**
     * Focus rule: nothing takes keyboard / gamepad focus by itself, except that when NOTHING is focused the first widget with autoFocus = true (reading order: top, then left) takes it. Mark the first item of each menu; HUD buttons then stay out of gamepad play (Space / A must never click a HUD button). When the focused widget disappears (inactive, destroyed, not interactable) autoFocus applies again. When every visible autoFocus widget has interactable = false (a greyed-out buy button), the first interactable widget in reading order takes the focus instead, so the gamepad is never left with nothing focused.
     * @since 0.1.6
     */
    autoFocus: boolean;
    /**
     * Runtime: true while the widget has keyboard / gamepad focus. Written by the UI every frame; move focus with ui.focus(entity). Read-only.
     * @since 0.1.6
     */
    readonly focused: boolean;
    /**
     * Runtime: the pointer (mouse or first touch) is over this widget, the top-most visible interactable one. Read-only.
     * @since 0.1.6
     */
    readonly hovered: boolean;
    /**
     * Runtime: the pointer is held down on this widget. Read-only.
     * @since 0.1.6
     */
    readonly pressed: boolean;
    /**
     * Label, centred on the button. `
     * ` starts a new line; every line is centred. Text longer than the button is clipped to it: use `maxWidth` to wrap it, `autoSize` to grow the button or `autoShrink` to shrink the text.
     * @since 0.1.6
     */
    text: string;
    /**
     * > 0 wraps the label at this width in design pixels (like Text.maxWidth); 0 = the label wraps only at `
     * `. With autoSize the button is at most maxWidth plus its margins wide and grows taller instead.
     * @since 0.2.0
     */
    maxWidth: number;
    /**
     * true: the widget is at least its design `size` and grows to fit its label at the current text size (ui.textScale) and language, re-laid out when either changes (needs no script). Width and height are set every frame, so writing `size` while this is on sets the NEW design size; turn it off to keep a size. A Button, Toggle or Slider label wraps at its `maxWidth` (and the widget grows taller); with no maxWidth the label does not wrap. autoSize makes room for the full-size label, so autoShrink only works on a widget that does not grow. false (default): the widget keeps its size and a big label sticks out of it (Button labels are clipped).
     * @since 0.2.0
     */
    autoSize: boolean;
    /**
     * true: when the text does not fit its box at the current text size (ui.textScale) and language, the font is made smaller until it does, never under `minFontSize` (so a German label in a fixed button stays inside at 200 % text, and a long translation is smaller instead of cut). It is decided every frame from the laid-out size, with no script. If it still does not fit at minFontSize it is drawn there and ui.overflowed(id) is true. false (default): the size is never reduced.
     * @since unreleased
     */
    autoShrink: boolean;
    /**
     * autoShrink floor in design pixels, before ui.textScale (the floor is minFontSize times the player's text size, capped by maxTextScale, so the accessibility setting keeps working). Never above fontSize.
     * @since unreleased
     */
    minFontSize: number;
  }
  /**
   * Check box with a label: a square box at the left (a filled inner square in accentColor when on) and the label to its right. Flips on click or ui_submit; the event is ui.change {id, value: bool}.
   * 
   * Category: UI
   * @since 0.1.6
   */
  export interface ToggleComponent {
    /**
     * Size [w, h] in design pixels. The default depends on the kind (Button 240 x 56, Toggle 240 x 40, Slider 320 x 40, TextField 320 x 48, Panel and ScrollList 320 x 240, TouchStick 200 x 200, TouchButton 96 x 96, Captions 960 x 180, Video 640 x 360). A Panel with fit = true recomputes it every frame.
     * @since 0.1.6
     */
    get size(): Vec2;
    set size(value: Vec2Like);
    /**
     * Which point of the widget sits on the position: [0.5, 0.5] = its centre (default), [0, 1] = top-left corner, [1, 0] = bottom-right. Same meaning as Shape2D.pivot in screen space: +Y is down on screen but pivot [0, 1] is still the visual top-left. Layout does not care about the pivot of its children.
     * @since 0.1.6
     */
    get pivot(): Vec2;
    set pivot(value: Vec2Like);
    /**
     * Screen point the position is relative to, as a fraction of the screen: [0, 0] top-left (default), [1, 0] top-right, [0.5, 0.5] centre. Anchor [0.5, 0.5] with position [0, 0] centres the widget on any aspect ratio. The anchor of the widget itself is used, not its parent's: children of a Panel normally keep anchor [0, 0] and are placed by the Panel's layout.
     * @since 0.1.6
     */
    get anchor(): Vec2;
    set anchor(value: Vec2Like);
    /**
     * Screen space only. true: the anchor names a point of the SAFE area, the screen minus the notch, rounded corners and system bars of a phone (screen.safeArea in scripts), instead of the whole screen: anchor [0, 0] is the top-left corner of the safe area, [1, 1] its bottom-right. Keeps HUD and buttons out of the notch. On a screen without cutouts (desktop, most tablets) it changes nothing. Default false (true on TouchStick and TouchButton).
     * @since 0.2.0
     */
    safeArea: boolean;
    /**
     * Draw order of the background; higher is on top. Defaults to 200, above HUD Text (layer 100). The label draws at layer + 1 and the focus ring at layer + 2. Pointer hit-testing follows the same order: the highest layer, then the latest entity, under the pointer is the hovered widget.
     * @since 0.1.6
     */
    layer: number;
    /**
     * Background colour, multiplied with `texture` when there is one. Hovered widgets are brightened, pressed ones darkened, non-interactable ones drawn at half alpha. Accepts [r,g,b,a], "#rrggbb" or a name.
     * @since 0.1.6
     */
    get color(): Color;
    set color(value: ColorLike);
    /**
     * Optional background image (project path), drawn as a 9-slice (see `slice`) with nearest-neighbour sampling, so pixel art stays crisp. Empty draws a solid rectangle of `color`. (asset path: texture)
     * @since 0.1.6
     */
    texture: string;
    /**
     * 9-slice borders in TEXTURE pixels [left, top, right, bottom]. The four corners are drawn unscaled (1 texture pixel = 1 design pixel), the edges stretch along one axis and the centre along both, so one small image gives panels of any size. [0, 0, 0, 0] (default) stretches the whole image. When the widget is smaller than left + right (or top + bottom) the borders shrink proportionally.
     * @since 0.1.6
     */
    get slice(): Vec3 & { w: number };
    set slice(value: readonly number[] | { x: number; y: number; z: number; w: number });
    /**
     * Font of the label: project path of a .ttf, empty = the built-in font (same values as Text.font). (asset path: font)
     * @since 0.1.6
     */
    font: string;
    /**
     * Localization key, e.g. "menu.play" (docs/LOCALIZATION.md). Empty (default) = not translated. With a key, the runtime writes the translation into the widget's own text: Button.text, Toggle.label, Slider.label, or TextField.placeholder (never TextField.text, which is what the player typed). It does so when a scene or prefab loads, every frame and when the language changes, so that field is overwritten at run time while `key` is set. A key that no string table has keeps the text written in the field and logs one warning.
     * @since 0.2.0
     */
    key: string;
    /**
     * Values for the {placeholders} of `key`, an object of name -> string or number: {"score": 12} fills "Score: {score}" (and `count` picks the form of a plural entry). Set it once from a script (`entity.set("Text", { keyArgs: { score } })` or `scene.set_component`) instead of rewriting the text every frame: the engine formats the translation with them when the text is localized, when the args change and when the language changes, so a language switch keeps them. Empty (default) = no arguments. Ignored while `key` is empty. Returns a plain-object COPY; assign a new value to write.
     * @since unreleased
     */
    keyArgs: any;
    /**
     * Label glyph height in design pixels.
     * @since 0.1.6
     */
    fontSize: number;
    /**
     * > 0: the player's text size (ui.textScale) stops growing this text at this scale, so a heading or a round button label does not outgrow its place: 1.3 means it is drawn at most 1.3 times its fontSize however big the option is. It only limits growth: at a text size below the cap it is drawn at the player's size. 0 (default) = no cap. Measuring (autoSize, layout, ui.measureText, ui.rectOf) and drawing use the same capped size.
     * @since unreleased
     */
    maxTextScale: number;
    /**
     * Label colour.
     * @since 0.1.6
     */
    get textColor(): Color;
    set textColor(value: ColorLike);
    /**
     * Colour of the focus ring, the slider fill and knob, the toggle check mark and the text caret.
     * @since 0.1.6
     */
    get accentColor(): Color;
    set accentColor(value: ColorLike);
    /**
     * false: the widget is drawn at half alpha and is never hovered, focused or clicked, so it sends no ui events. A focused widget that becomes non-interactable loses focus.
     * @since 0.1.6
     */
    interactable: boolean;
    /**
     * Focus rule: nothing takes keyboard / gamepad focus by itself, except that when NOTHING is focused the first widget with autoFocus = true (reading order: top, then left) takes it. Mark the first item of each menu; HUD buttons then stay out of gamepad play (Space / A must never click a HUD button). When the focused widget disappears (inactive, destroyed, not interactable) autoFocus applies again. When every visible autoFocus widget has interactable = false (a greyed-out buy button), the first interactable widget in reading order takes the focus instead, so the gamepad is never left with nothing focused.
     * @since 0.1.6
     */
    autoFocus: boolean;
    /**
     * Runtime: true while the widget has keyboard / gamepad focus. Written by the UI every frame; move focus with ui.focus(entity). Read-only.
     * @since 0.1.6
     */
    readonly focused: boolean;
    /**
     * Runtime: the pointer (mouse or first touch) is over this widget, the top-most visible interactable one. Read-only.
     * @since 0.1.6
     */
    readonly hovered: boolean;
    /**
     * Runtime: the pointer is held down on this widget. Read-only.
     * @since 0.1.6
     */
    readonly pressed: boolean;
    /**
     * Text to the right of the box.
     * @since 0.1.6
     */
    label: string;
    /**
     * > 0 wraps the label at this width in design pixels (like Text.maxWidth); 0 = one line. With autoSize the toggle is at most maxWidth plus the box and margins wide and grows taller instead.
     * @since unreleased
     */
    maxWidth: number;
    /**
     * true: the widget is at least its design `size` and grows to fit its label at the current text size (ui.textScale) and language, re-laid out when either changes (needs no script). Width and height are set every frame, so writing `size` while this is on sets the NEW design size; turn it off to keep a size. A Button, Toggle or Slider label wraps at its `maxWidth` (and the widget grows taller); with no maxWidth the label does not wrap. autoSize makes room for the full-size label, so autoShrink only works on a widget that does not grow. false (default): the widget keeps its size and a big label sticks out of it (Button labels are clipped).
     * @since 0.2.0
     */
    autoSize: boolean;
    /**
     * true: when the text does not fit its box at the current text size (ui.textScale) and language, the font is made smaller until it does, never under `minFontSize` (so a German label in a fixed button stays inside at 200 % text, and a long translation is smaller instead of cut). It is decided every frame from the laid-out size, with no script. If it still does not fit at minFontSize it is drawn there and ui.overflowed(id) is true. false (default): the size is never reduced.
     * @since unreleased
     */
    autoShrink: boolean;
    /**
     * autoShrink floor in design pixels, before ui.textScale (the floor is minFontSize times the player's text size, capped by maxTextScale, so the accessibility setting keeps working). Never above fontSize.
     * @since unreleased
     */
    minFontSize: number;
    /**
     * true = checked. Scripts may write it; no event is sent for a write.
     * @since 0.1.6
     */
    value: boolean;
  }
  /**
   * Horizontal value slider: label in the left 35% (when not empty), the track in the next 50% (85% without a label) with a fill and a knob in accentColor, the value in the last 15% (with labelAbove the label is above the track and the track gets the 85%). Left / right (ui_left / ui_right, d-pad, stick) change the value while focused; dragging the track with the mouse sets it. Event: ui.change {id, value: number}.
   * 
   * Category: UI
   * @since 0.1.6
   */
  export interface SliderComponent {
    /**
     * Size [w, h] in design pixels. The default depends on the kind (Button 240 x 56, Toggle 240 x 40, Slider 320 x 40, TextField 320 x 48, Panel and ScrollList 320 x 240, TouchStick 200 x 200, TouchButton 96 x 96, Captions 960 x 180, Video 640 x 360). A Panel with fit = true recomputes it every frame.
     * @since 0.1.6
     */
    get size(): Vec2;
    set size(value: Vec2Like);
    /**
     * Which point of the widget sits on the position: [0.5, 0.5] = its centre (default), [0, 1] = top-left corner, [1, 0] = bottom-right. Same meaning as Shape2D.pivot in screen space: +Y is down on screen but pivot [0, 1] is still the visual top-left. Layout does not care about the pivot of its children.
     * @since 0.1.6
     */
    get pivot(): Vec2;
    set pivot(value: Vec2Like);
    /**
     * Screen point the position is relative to, as a fraction of the screen: [0, 0] top-left (default), [1, 0] top-right, [0.5, 0.5] centre. Anchor [0.5, 0.5] with position [0, 0] centres the widget on any aspect ratio. The anchor of the widget itself is used, not its parent's: children of a Panel normally keep anchor [0, 0] and are placed by the Panel's layout.
     * @since 0.1.6
     */
    get anchor(): Vec2;
    set anchor(value: Vec2Like);
    /**
     * Screen space only. true: the anchor names a point of the SAFE area, the screen minus the notch, rounded corners and system bars of a phone (screen.safeArea in scripts), instead of the whole screen: anchor [0, 0] is the top-left corner of the safe area, [1, 1] its bottom-right. Keeps HUD and buttons out of the notch. On a screen without cutouts (desktop, most tablets) it changes nothing. Default false (true on TouchStick and TouchButton).
     * @since 0.2.0
     */
    safeArea: boolean;
    /**
     * Draw order of the background; higher is on top. Defaults to 200, above HUD Text (layer 100). The label draws at layer + 1 and the focus ring at layer + 2. Pointer hit-testing follows the same order: the highest layer, then the latest entity, under the pointer is the hovered widget.
     * @since 0.1.6
     */
    layer: number;
    /**
     * Background colour, multiplied with `texture` when there is one. Hovered widgets are brightened, pressed ones darkened, non-interactable ones drawn at half alpha. Accepts [r,g,b,a], "#rrggbb" or a name.
     * @since 0.1.6
     */
    get color(): Color;
    set color(value: ColorLike);
    /**
     * Optional background image (project path), drawn as a 9-slice (see `slice`) with nearest-neighbour sampling, so pixel art stays crisp. Empty draws a solid rectangle of `color`. (asset path: texture)
     * @since 0.1.6
     */
    texture: string;
    /**
     * 9-slice borders in TEXTURE pixels [left, top, right, bottom]. The four corners are drawn unscaled (1 texture pixel = 1 design pixel), the edges stretch along one axis and the centre along both, so one small image gives panels of any size. [0, 0, 0, 0] (default) stretches the whole image. When the widget is smaller than left + right (or top + bottom) the borders shrink proportionally.
     * @since 0.1.6
     */
    get slice(): Vec3 & { w: number };
    set slice(value: readonly number[] | { x: number; y: number; z: number; w: number });
    /**
     * Font of the label: project path of a .ttf, empty = the built-in font (same values as Text.font). (asset path: font)
     * @since 0.1.6
     */
    font: string;
    /**
     * Localization key, e.g. "menu.play" (docs/LOCALIZATION.md). Empty (default) = not translated. With a key, the runtime writes the translation into the widget's own text: Button.text, Toggle.label, Slider.label, or TextField.placeholder (never TextField.text, which is what the player typed). It does so when a scene or prefab loads, every frame and when the language changes, so that field is overwritten at run time while `key` is set. A key that no string table has keeps the text written in the field and logs one warning.
     * @since 0.2.0
     */
    key: string;
    /**
     * Values for the {placeholders} of `key`, an object of name -> string or number: {"score": 12} fills "Score: {score}" (and `count` picks the form of a plural entry). Set it once from a script (`entity.set("Text", { keyArgs: { score } })` or `scene.set_component`) instead of rewriting the text every frame: the engine formats the translation with them when the text is localized, when the args change and when the language changes, so a language switch keeps them. Empty (default) = no arguments. Ignored while `key` is empty. Returns a plain-object COPY; assign a new value to write.
     * @since unreleased
     */
    keyArgs: any;
    /**
     * Label glyph height in design pixels.
     * @since 0.1.6
     */
    fontSize: number;
    /**
     * > 0: the player's text size (ui.textScale) stops growing this text at this scale, so a heading or a round button label does not outgrow its place: 1.3 means it is drawn at most 1.3 times its fontSize however big the option is. It only limits growth: at a text size below the cap it is drawn at the player's size. 0 (default) = no cap. Measuring (autoSize, layout, ui.measureText, ui.rectOf) and drawing use the same capped size.
     * @since unreleased
     */
    maxTextScale: number;
    /**
     * Label colour.
     * @since 0.1.6
     */
    get textColor(): Color;
    set textColor(value: ColorLike);
    /**
     * Colour of the focus ring, the slider fill and knob, the toggle check mark and the text caret.
     * @since 0.1.6
     */
    get accentColor(): Color;
    set accentColor(value: ColorLike);
    /**
     * false: the widget is drawn at half alpha and is never hovered, focused or clicked, so it sends no ui events. A focused widget that becomes non-interactable loses focus.
     * @since 0.1.6
     */
    interactable: boolean;
    /**
     * Focus rule: nothing takes keyboard / gamepad focus by itself, except that when NOTHING is focused the first widget with autoFocus = true (reading order: top, then left) takes it. Mark the first item of each menu; HUD buttons then stay out of gamepad play (Space / A must never click a HUD button). When the focused widget disappears (inactive, destroyed, not interactable) autoFocus applies again. When every visible autoFocus widget has interactable = false (a greyed-out buy button), the first interactable widget in reading order takes the focus instead, so the gamepad is never left with nothing focused.
     * @since 0.1.6
     */
    autoFocus: boolean;
    /**
     * Runtime: true while the widget has keyboard / gamepad focus. Written by the UI every frame; move focus with ui.focus(entity). Read-only.
     * @since 0.1.6
     */
    readonly focused: boolean;
    /**
     * Runtime: the pointer (mouse or first touch) is over this widget, the top-most visible interactable one. Read-only.
     * @since 0.1.6
     */
    readonly hovered: boolean;
    /**
     * Runtime: the pointer is held down on this widget. Read-only.
     * @since 0.1.6
     */
    readonly pressed: boolean;
    /**
     * Text at the left (or above the track with labelAbove); empty gives the track the extra room.
     * @since 0.1.6
     */
    label: string;
    /**
     * > 0 wraps the label at this width in design pixels (like Text.maxWidth); 0 = one line. With autoSize the slider grows taller for the extra lines.
     * @since unreleased
     */
    maxWidth: number;
    /**
     * true: the label is drawn above the track on the slider's full width (wrapping at maxWidth or the width) and the track, knob and value sit in a row of 28 px at the bottom, so a long label does not squeeze the track. The slider needs a height of the label plus 28 px (autoSize adds it). false (default): the label is in the left 35%.
     * @since unreleased
     */
    labelAbove: boolean;
    /**
     * true: the widget is at least its design `size` and grows to fit its label at the current text size (ui.textScale) and language, re-laid out when either changes (needs no script). Width and height are set every frame, so writing `size` while this is on sets the NEW design size; turn it off to keep a size. A Button, Toggle or Slider label wraps at its `maxWidth` (and the widget grows taller); with no maxWidth the label does not wrap. autoSize makes room for the full-size label, so autoShrink only works on a widget that does not grow. false (default): the widget keeps its size and a big label sticks out of it (Button labels are clipped).
     * @since 0.2.0
     */
    autoSize: boolean;
    /**
     * true: when the text does not fit its box at the current text size (ui.textScale) and language, the font is made smaller until it does, never under `minFontSize` (so a German label in a fixed button stays inside at 200 % text, and a long translation is smaller instead of cut). It is decided every frame from the laid-out size, with no script. If it still does not fit at minFontSize it is drawn there and ui.overflowed(id) is true. false (default): the size is never reduced.
     * @since unreleased
     */
    autoShrink: boolean;
    /**
     * autoShrink floor in design pixels, before ui.textScale (the floor is minFontSize times the player's text size, capped by maxTextScale, so the accessibility setting keeps working). Never above fontSize.
     * @since unreleased
     */
    minFontSize: number;
    /**
     * Current value, always within [min, max] and snapped to `step` by the UI. Scripts may write it; no event is sent for a write.
     * @since 0.1.6
     */
    value: number;
    /**
     * Smallest value.
     * @since 0.1.6
     */
    min: number;
    /**
     * Largest value.
     * @since 0.1.6
     */
    max: number;
    /**
     * Keyboard / gamepad increment, and the grid the value is snapped to (also when dragging). 0 = continuous: keys move (max - min) / 20 per press and dragging is not snapped.
     * @since 0.1.6
     */
    step: number;
    /**
     * Draw the value at the right. Without `format`: "60%" when min is 0 and max is 1, else the number with up to 2 decimals.
     * @since 0.1.6
     */
    showValue: boolean;
    /**
     * Pattern of the shown value, e.g. "{v}%" or "{v:1}x". {v} is the value with up to 2 decimals (trailing zeros dropped), {v:N} the value with exactly N decimals (0 to 6), {percent} the value times 100 rounded to a whole number (a 0.3..1 opacity slider shows 30%..100% with "{percent}%"; {percent} does not depend on min and max). A doubled brace writes one brace; any other {name} is drawn as it is, so a typo is visible. Empty = the default of showValue. It sizes autoSize and draws in the value column only; ui.state `value` stays the number. Use formatKey for a pattern per language.
     * @since unreleased
     */
    format: string;
    /**
     * Localization key whose translation is the pattern, written into `format` like `key` writes the label ("slider.percent": "{v} %" in French). "" = none. A key no table has is reported once and `format` stays as it is.
     * @since unreleased
     */
    formatKey: string;
  }
  /**
   * Single-line text input. While focused it appends the typed characters (Input text), Backspace removes the last one (it repeats while held) and Enter submits. There is no caret movement: the caret stays at the end. Events: ui.change {id, value} on every edit (one per frame), ui.submit {id, value} on Enter. Left / right do nothing in a TextField and Space types a space (ui_submit is ignored).
   * 
   * Category: UI
   * @since 0.1.6
   */
  export interface TextFieldComponent {
    /**
     * Size [w, h] in design pixels. The default depends on the kind (Button 240 x 56, Toggle 240 x 40, Slider 320 x 40, TextField 320 x 48, Panel and ScrollList 320 x 240, TouchStick 200 x 200, TouchButton 96 x 96, Captions 960 x 180, Video 640 x 360). A Panel with fit = true recomputes it every frame.
     * @since 0.1.6
     */
    get size(): Vec2;
    set size(value: Vec2Like);
    /**
     * Which point of the widget sits on the position: [0.5, 0.5] = its centre (default), [0, 1] = top-left corner, [1, 0] = bottom-right. Same meaning as Shape2D.pivot in screen space: +Y is down on screen but pivot [0, 1] is still the visual top-left. Layout does not care about the pivot of its children.
     * @since 0.1.6
     */
    get pivot(): Vec2;
    set pivot(value: Vec2Like);
    /**
     * Screen point the position is relative to, as a fraction of the screen: [0, 0] top-left (default), [1, 0] top-right, [0.5, 0.5] centre. Anchor [0.5, 0.5] with position [0, 0] centres the widget on any aspect ratio. The anchor of the widget itself is used, not its parent's: children of a Panel normally keep anchor [0, 0] and are placed by the Panel's layout.
     * @since 0.1.6
     */
    get anchor(): Vec2;
    set anchor(value: Vec2Like);
    /**
     * Screen space only. true: the anchor names a point of the SAFE area, the screen minus the notch, rounded corners and system bars of a phone (screen.safeArea in scripts), instead of the whole screen: anchor [0, 0] is the top-left corner of the safe area, [1, 1] its bottom-right. Keeps HUD and buttons out of the notch. On a screen without cutouts (desktop, most tablets) it changes nothing. Default false (true on TouchStick and TouchButton).
     * @since 0.2.0
     */
    safeArea: boolean;
    /**
     * Draw order of the background; higher is on top. Defaults to 200, above HUD Text (layer 100). The label draws at layer + 1 and the focus ring at layer + 2. Pointer hit-testing follows the same order: the highest layer, then the latest entity, under the pointer is the hovered widget.
     * @since 0.1.6
     */
    layer: number;
    /**
     * Background colour, multiplied with `texture` when there is one. Hovered widgets are brightened, pressed ones darkened, non-interactable ones drawn at half alpha. Accepts [r,g,b,a], "#rrggbb" or a name.
     * @since 0.1.6
     */
    get color(): Color;
    set color(value: ColorLike);
    /**
     * Optional background image (project path), drawn as a 9-slice (see `slice`) with nearest-neighbour sampling, so pixel art stays crisp. Empty draws a solid rectangle of `color`. (asset path: texture)
     * @since 0.1.6
     */
    texture: string;
    /**
     * 9-slice borders in TEXTURE pixels [left, top, right, bottom]. The four corners are drawn unscaled (1 texture pixel = 1 design pixel), the edges stretch along one axis and the centre along both, so one small image gives panels of any size. [0, 0, 0, 0] (default) stretches the whole image. When the widget is smaller than left + right (or top + bottom) the borders shrink proportionally.
     * @since 0.1.6
     */
    get slice(): Vec3 & { w: number };
    set slice(value: readonly number[] | { x: number; y: number; z: number; w: number });
    /**
     * Font of the label: project path of a .ttf, empty = the built-in font (same values as Text.font). (asset path: font)
     * @since 0.1.6
     */
    font: string;
    /**
     * Localization key, e.g. "menu.play" (docs/LOCALIZATION.md). Empty (default) = not translated. With a key, the runtime writes the translation into the widget's own text: Button.text, Toggle.label, Slider.label, or TextField.placeholder (never TextField.text, which is what the player typed). It does so when a scene or prefab loads, every frame and when the language changes, so that field is overwritten at run time while `key` is set. A key that no string table has keeps the text written in the field and logs one warning.
     * @since 0.2.0
     */
    key: string;
    /**
     * Values for the {placeholders} of `key`, an object of name -> string or number: {"score": 12} fills "Score: {score}" (and `count` picks the form of a plural entry). Set it once from a script (`entity.set("Text", { keyArgs: { score } })` or `scene.set_component`) instead of rewriting the text every frame: the engine formats the translation with them when the text is localized, when the args change and when the language changes, so a language switch keeps them. Empty (default) = no arguments. Ignored while `key` is empty. Returns a plain-object COPY; assign a new value to write.
     * @since unreleased
     */
    keyArgs: any;
    /**
     * Label glyph height in design pixels.
     * @since 0.1.6
     */
    fontSize: number;
    /**
     * > 0: the player's text size (ui.textScale) stops growing this text at this scale, so a heading or a round button label does not outgrow its place: 1.3 means it is drawn at most 1.3 times its fontSize however big the option is. It only limits growth: at a text size below the cap it is drawn at the player's size. 0 (default) = no cap. Measuring (autoSize, layout, ui.measureText, ui.rectOf) and drawing use the same capped size.
     * @since unreleased
     */
    maxTextScale: number;
    /**
     * Label colour.
     * @since 0.1.6
     */
    get textColor(): Color;
    set textColor(value: ColorLike);
    /**
     * Colour of the focus ring, the slider fill and knob, the toggle check mark and the text caret.
     * @since 0.1.6
     */
    get accentColor(): Color;
    set accentColor(value: ColorLike);
    /**
     * false: the widget is drawn at half alpha and is never hovered, focused or clicked, so it sends no ui events. A focused widget that becomes non-interactable loses focus.
     * @since 0.1.6
     */
    interactable: boolean;
    /**
     * Focus rule: nothing takes keyboard / gamepad focus by itself, except that when NOTHING is focused the first widget with autoFocus = true (reading order: top, then left) takes it. Mark the first item of each menu; HUD buttons then stay out of gamepad play (Space / A must never click a HUD button). When the focused widget disappears (inactive, destroyed, not interactable) autoFocus applies again. When every visible autoFocus widget has interactable = false (a greyed-out buy button), the first interactable widget in reading order takes the focus instead, so the gamepad is never left with nothing focused.
     * @since 0.1.6
     */
    autoFocus: boolean;
    /**
     * Runtime: true while the widget has keyboard / gamepad focus. Written by the UI every frame; move focus with ui.focus(entity). Read-only.
     * @since 0.1.6
     */
    readonly focused: boolean;
    /**
     * Runtime: the pointer (mouse or first touch) is over this widget, the top-most visible interactable one. Read-only.
     * @since 0.1.6
     */
    readonly hovered: boolean;
    /**
     * Runtime: the pointer is held down on this widget. Read-only.
     * @since 0.1.6
     */
    readonly pressed: boolean;
    /**
     * The text, UTF-8. Scripts may write it; no event is sent for a write.
     * @since 0.1.6
     */
    text: string;
    /**
     * Hint drawn at half alpha while `text` is empty.
     * @since 0.1.6
     */
    placeholder: string;
    /**
     * Longest text, in characters (code points). 0 = unlimited.
     * @since 0.1.6
     */
    maxLength: number;
    /**
     * Runtime: the caret is in the visible half of its blink (a 1 second cycle of the UI's own unscaled clock; it restarts visible on every edit). Drawn only while focused. Read-only.
     * @since 0.1.6
     */
    readonly caret: boolean;
  }
  /**
   * Scrolling container: its children are stacked in a column (aligned left, packed at the top) at -scroll, and everything drawn by them and their descendants (widgets, Text, Sprite, Shape2D) is CLIPPED to the list's rectangle. The mouse wheel over the list scrolls it (the innermost list under the pointer), and focusing a widget inside scrolls just enough to show it.
   * 
   * Category: UI
   * @since 0.1.6
   */
  export interface ScrollListComponent {
    /**
     * Size [w, h] in design pixels. The default depends on the kind (Button 240 x 56, Toggle 240 x 40, Slider 320 x 40, TextField 320 x 48, Panel and ScrollList 320 x 240, TouchStick 200 x 200, TouchButton 96 x 96, Captions 960 x 180, Video 640 x 360). A Panel with fit = true recomputes it every frame.
     * @since 0.1.6
     */
    get size(): Vec2;
    set size(value: Vec2Like);
    /**
     * Which point of the widget sits on the position: [0.5, 0.5] = its centre (default), [0, 1] = top-left corner, [1, 0] = bottom-right. Same meaning as Shape2D.pivot in screen space: +Y is down on screen but pivot [0, 1] is still the visual top-left. Layout does not care about the pivot of its children.
     * @since 0.1.6
     */
    get pivot(): Vec2;
    set pivot(value: Vec2Like);
    /**
     * Screen point the position is relative to, as a fraction of the screen: [0, 0] top-left (default), [1, 0] top-right, [0.5, 0.5] centre. Anchor [0.5, 0.5] with position [0, 0] centres the widget on any aspect ratio. The anchor of the widget itself is used, not its parent's: children of a Panel normally keep anchor [0, 0] and are placed by the Panel's layout.
     * @since 0.1.6
     */
    get anchor(): Vec2;
    set anchor(value: Vec2Like);
    /**
     * Screen space only. true: the anchor names a point of the SAFE area, the screen minus the notch, rounded corners and system bars of a phone (screen.safeArea in scripts), instead of the whole screen: anchor [0, 0] is the top-left corner of the safe area, [1, 1] its bottom-right. Keeps HUD and buttons out of the notch. On a screen without cutouts (desktop, most tablets) it changes nothing. Default false (true on TouchStick and TouchButton).
     * @since 0.2.0
     */
    safeArea: boolean;
    /**
     * Draw order of the background; higher is on top. Defaults to 200, above HUD Text (layer 100). The label draws at layer + 1 and the focus ring at layer + 2. Pointer hit-testing follows the same order: the highest layer, then the latest entity, under the pointer is the hovered widget.
     * @since 0.1.6
     */
    layer: number;
    /**
     * Background colour, multiplied with `texture` when there is one. Hovered widgets are brightened, pressed ones darkened, non-interactable ones drawn at half alpha. Accepts [r,g,b,a], "#rrggbb" or a name.
     * @since 0.1.6
     */
    get color(): Color;
    set color(value: ColorLike);
    /**
     * Optional background image (project path), drawn as a 9-slice (see `slice`) with nearest-neighbour sampling, so pixel art stays crisp. Empty draws a solid rectangle of `color`. (asset path: texture)
     * @since 0.1.6
     */
    texture: string;
    /**
     * 9-slice borders in TEXTURE pixels [left, top, right, bottom]. The four corners are drawn unscaled (1 texture pixel = 1 design pixel), the edges stretch along one axis and the centre along both, so one small image gives panels of any size. [0, 0, 0, 0] (default) stretches the whole image. When the widget is smaller than left + right (or top + bottom) the borders shrink proportionally.
     * @since 0.1.6
     */
    get slice(): Vec3 & { w: number };
    set slice(value: readonly number[] | { x: number; y: number; z: number; w: number });
    /**
     * Gap in design pixels between children.
     * @since 0.1.6
     */
    spacing: number;
    /**
     * Space [left, top, right, bottom] between the list's edge and its children.
     * @since 0.1.6
     */
    get padding(): Vec3 & { w: number };
    set padding(value: readonly number[] | { x: number; y: number; z: number; w: number });
    /**
     * Runtime: pixels scrolled from the top. Scripts may write it; it is clamped to [0, content height - inner height] every frame.
     * @since 0.1.6
     */
    scroll: number;
    /**
     * Pixels scrolled per mouse-wheel notch.
     * @since 0.1.6
     */
    scrollSpeed: number;
    /**
     * true: when the parent is a Panel with layout column, `size.y` is set every frame to the height the other children leave. In a Panel with `fit` that is the screen height (minus the safe-area insets) minus the panel's padding, the gaps and the other children, so the panel ends exactly as tall as the screen at most (never below 64 px; if the other children do not leave that, the panel is taller than the screen and warns). In a Panel without fit it is the panel's own inner height minus the others. Several fill lists share the room equally. Ignored when the parent is not a column Panel. `size.x` is yours.
     * @since 0.2.0
     */
    fill: boolean;
    /**
     * true: like `fill`, but the list is only as tall as its content (padding, children and gaps) when that is less than the room the other children leave, so inside a `fit` Panel a short list makes a short panel and a long one stops at the screen height and scrolls. The room is computed as for `fill` (it needs a parent Panel with layout column; ignored otherwise; never below 64 px). `fill` and `shrink` together: `fill` wins. Several shrink lists share the room: each takes what it needs, and a list that needs more than an equal share takes what the shorter ones leave. `size.x` is yours.
     * @since unreleased
     */
    shrink: boolean;
  }
  /**
   * On-screen analog stick for phones and tablets (docs/MOBILE.md): a disc in `color` with a knob that follows the finger. A finger that lands on it moves a stick of the TOUCH PAD, a virtual gamepad the action bindings read like a real one, so actions bound to GamepadLeftStickLeft/Right/Up/Down (or the right stick) work with no change to the game; the default ui_* actions include the left stick, so it also walks menus. Full tilt is the edge of the disc (half the shorter side); the pad deadzone (input.deadzone) applies like on a real stick. That finger is the stick's until it lifts, even outside the disc: it is not in input.touches, the Touch binding or the mouse. Several fingers work at once (a stick and buttons). Defaults: 200 x 200, inside the safe area, shown only while the player uses touch (touchOnly).
   * 
   * Category: UI
   * @since 0.2.0
   */
  export interface TouchStickComponent {
    /**
     * Size [w, h] in design pixels. The default depends on the kind (Button 240 x 56, Toggle 240 x 40, Slider 320 x 40, TextField 320 x 48, Panel and ScrollList 320 x 240, TouchStick 200 x 200, TouchButton 96 x 96, Captions 960 x 180, Video 640 x 360). A Panel with fit = true recomputes it every frame.
     * @since 0.2.0
     */
    get size(): Vec2;
    set size(value: Vec2Like);
    /**
     * Which point of the widget sits on the position: [0.5, 0.5] = its centre (default), [0, 1] = top-left corner, [1, 0] = bottom-right. Same meaning as Shape2D.pivot in screen space: +Y is down on screen but pivot [0, 1] is still the visual top-left. Layout does not care about the pivot of its children.
     * @since 0.2.0
     */
    get pivot(): Vec2;
    set pivot(value: Vec2Like);
    /**
     * Screen point the position is relative to, as a fraction of the screen: [0, 0] top-left (default), [1, 0] top-right, [0.5, 0.5] centre. Anchor [0.5, 0.5] with position [0, 0] centres the widget on any aspect ratio. The anchor of the widget itself is used, not its parent's: children of a Panel normally keep anchor [0, 0] and are placed by the Panel's layout.
     * @since 0.2.0
     */
    get anchor(): Vec2;
    set anchor(value: Vec2Like);
    /**
     * Screen space only. true: the anchor names a point of the SAFE area, the screen minus the notch, rounded corners and system bars of a phone (screen.safeArea in scripts), instead of the whole screen: anchor [0, 0] is the top-left corner of the safe area, [1, 1] its bottom-right. Keeps HUD and buttons out of the notch. On a screen without cutouts (desktop, most tablets) it changes nothing. Default false (true on TouchStick and TouchButton).
     * @since 0.2.0
     */
    safeArea: boolean;
    /**
     * Draw order of the background; higher is on top. Defaults to 200, above HUD Text (layer 100). The label draws at layer + 1 and the focus ring at layer + 2. Pointer hit-testing follows the same order: the highest layer, then the latest entity, under the pointer is the hovered widget.
     * @since 0.2.0
     */
    layer: number;
    /**
     * Background colour, multiplied with `texture` when there is one. Hovered widgets are brightened, pressed ones darkened, non-interactable ones drawn at half alpha. Accepts [r,g,b,a], "#rrggbb" or a name.
     * @since 0.2.0
     */
    get color(): Color;
    set color(value: ColorLike);
    /**
     * Optional background image (project path), drawn as a 9-slice (see `slice`) with nearest-neighbour sampling, so pixel art stays crisp. Empty draws a solid rectangle of `color`. (asset path: texture)
     * @since 0.2.0
     */
    texture: string;
    /**
     * 9-slice borders in TEXTURE pixels [left, top, right, bottom]. The four corners are drawn unscaled (1 texture pixel = 1 design pixel), the edges stretch along one axis and the centre along both, so one small image gives panels of any size. [0, 0, 0, 0] (default) stretches the whole image. When the widget is smaller than left + right (or top + bottom) the borders shrink proportionally.
     * @since 0.2.0
     */
    get slice(): Vec3 & { w: number };
    set slice(value: readonly number[] | { x: number; y: number; z: number; w: number });
    /**
     * Which stick of the touch pad it moves.
     * @since 0.2.0
     */
    stick: "left" | "right";
    /**
     * Colour of the knob, a disc 45% as wide as the stick.
     * @since 0.2.0
     */
    get knobColor(): Color;
    set knobColor(value: ColorLike);
    /**
     * true (default): drawn and listed as visible only while the last input came from a finger (input.lastDevice "touch"; a phone or tablet starts that way), so it hides when the player picks up a gamepad or a keyboard and comes back on the next touch. A finger landing on it always works. false: always drawn (desktop previews, screenshots, tests).
     * @since 0.2.0
     */
    touchOnly: boolean;
    /**
     * Runtime: the finger's offset from the centre over the radius [x, y], length <= 1, +Y up; [0, 0] when no finger holds it. Before the deadzone; read actions (input.vector) for the value the game should use. Read-only.
     * @since 0.2.0
     */
    readonly value: Vec2;
    /**
     * Runtime: a finger holds the stick. Read-only.
     * @since 0.2.0
     */
    readonly pressed: boolean;
    /**
     * Runtime: drawn this frame (see touchOnly). Read-only.
     * @since 0.2.0
     */
    readonly shown: boolean;
  }
  /**
   * On-screen button for phones and tablets (docs/MOBILE.md): a disc in `color` (darker while held) with an optional label. While a finger holds it, `button` of the TOUCH PAD is down, a virtual gamepad the action bindings read like a real one: a TouchButton with button "A" fires every action bound to GamepadA, with no change to the game. The finger is the button's until it lifts, even if it slides off, and it is not in input.touches, the Touch binding or the mouse. Several fingers work at once. Defaults: 96 x 96, inside the safe area, shown only while the player uses touch (touchOnly). It is not focusable and sends no ui events.
   * 
   * Category: UI
   * @since 0.2.0
   */
  export interface TouchButtonComponent {
    /**
     * Size [w, h] in design pixels. The default depends on the kind (Button 240 x 56, Toggle 240 x 40, Slider 320 x 40, TextField 320 x 48, Panel and ScrollList 320 x 240, TouchStick 200 x 200, TouchButton 96 x 96, Captions 960 x 180, Video 640 x 360). A Panel with fit = true recomputes it every frame.
     * @since 0.2.0
     */
    get size(): Vec2;
    set size(value: Vec2Like);
    /**
     * Which point of the widget sits on the position: [0.5, 0.5] = its centre (default), [0, 1] = top-left corner, [1, 0] = bottom-right. Same meaning as Shape2D.pivot in screen space: +Y is down on screen but pivot [0, 1] is still the visual top-left. Layout does not care about the pivot of its children.
     * @since 0.2.0
     */
    get pivot(): Vec2;
    set pivot(value: Vec2Like);
    /**
     * Screen point the position is relative to, as a fraction of the screen: [0, 0] top-left (default), [1, 0] top-right, [0.5, 0.5] centre. Anchor [0.5, 0.5] with position [0, 0] centres the widget on any aspect ratio. The anchor of the widget itself is used, not its parent's: children of a Panel normally keep anchor [0, 0] and are placed by the Panel's layout.
     * @since 0.2.0
     */
    get anchor(): Vec2;
    set anchor(value: Vec2Like);
    /**
     * Screen space only. true: the anchor names a point of the SAFE area, the screen minus the notch, rounded corners and system bars of a phone (screen.safeArea in scripts), instead of the whole screen: anchor [0, 0] is the top-left corner of the safe area, [1, 1] its bottom-right. Keeps HUD and buttons out of the notch. On a screen without cutouts (desktop, most tablets) it changes nothing. Default false (true on TouchStick and TouchButton).
     * @since 0.2.0
     */
    safeArea: boolean;
    /**
     * Draw order of the background; higher is on top. Defaults to 200, above HUD Text (layer 100). The label draws at layer + 1 and the focus ring at layer + 2. Pointer hit-testing follows the same order: the highest layer, then the latest entity, under the pointer is the hovered widget.
     * @since 0.2.0
     */
    layer: number;
    /**
     * Background colour, multiplied with `texture` when there is one. Hovered widgets are brightened, pressed ones darkened, non-interactable ones drawn at half alpha. Accepts [r,g,b,a], "#rrggbb" or a name.
     * @since 0.2.0
     */
    get color(): Color;
    set color(value: ColorLike);
    /**
     * Optional background image (project path), drawn as a 9-slice (see `slice`) with nearest-neighbour sampling, so pixel art stays crisp. Empty draws a solid rectangle of `color`. (asset path: texture)
     * @since 0.2.0
     */
    texture: string;
    /**
     * 9-slice borders in TEXTURE pixels [left, top, right, bottom]. The four corners are drawn unscaled (1 texture pixel = 1 design pixel), the edges stretch along one axis and the centre along both, so one small image gives panels of any size. [0, 0, 0, 0] (default) stretches the whole image. When the widget is smaller than left + right (or top + bottom) the borders shrink proportionally.
     * @since 0.2.0
     */
    get slice(): Vec3 & { w: number };
    set slice(value: readonly number[] | { x: number; y: number; z: number; w: number });
    /**
     * The pad button it holds down: actions bound to "Gamepad" + this name (GamepadA, GamepadDpadUp...) fire. Bind the game's actions to pad buttons in factoria.json input.actions to use them.
     * @since 0.2.0
     */
    button: "A" | "B" | "X" | "Y" | "Start" | "Back" | "Guide" | "DpadLeft" | "DpadRight" | "DpadUp" | "DpadDown" | "LeftShoulder" | "RightShoulder" | "LeftThumb" | "RightThumb";
    /**
     * Label centred on the button, e.g. "A" or "Jump". Empty (default) draws none.
     * @since 0.2.0
     */
    text: string;
    /**
     * Localization key, e.g. "touch.jump" (docs/LOCALIZATION.md). Empty (default) = not translated. With a key, the runtime writes the translation into `text` when a scene loads, every frame and when the language changes. A key that no string table has keeps `text` and logs one warning.
     * @since unreleased
     */
    key: string;
    /**
     * Values for the {placeholders} of `key`, an object of name -> string or number: {"score": 12} fills "Score: {score}" (and `count` picks the form of a plural entry). Set it once from a script (`entity.set("Text", { keyArgs: { score } })` or `scene.set_component`) instead of rewriting the text every frame: the engine formats the translation with them when the text is localized, when the args change and when the language changes, so a language switch keeps them. Empty (default) = no arguments. Ignored while `key` is empty. Returns a plain-object COPY; assign a new value to write.
     * @since unreleased
     */
    keyArgs: any;
    /**
     * Font of the label: project path of a .ttf, empty = the built-in font. (asset path: font)
     * @since 0.2.0
     */
    font: string;
    /**
     * Label glyph height in design pixels.
     * @since 0.2.0
     */
    fontSize: number;
    /**
     * true: when the text does not fit its box at the current text size (ui.textScale) and language, the font is made smaller until it does, never under `minFontSize` (so a German label in a fixed button stays inside at 200 % text, and a long translation is smaller instead of cut). It is decided every frame from the laid-out size, with no script. If it still does not fit at minFontSize it is drawn there and ui.overflowed(id) is true. false (default): the size is never reduced.
     * @since unreleased
     */
    autoShrink: boolean;
    /**
     * autoShrink floor in design pixels, before ui.textScale (the floor is minFontSize times the player's text size, capped by maxTextScale, so the accessibility setting keeps working). Never above fontSize.
     * @since unreleased
     */
    minFontSize: number;
    /**
     * > 0: the player's text size (ui.textScale) stops growing this text at this scale, so a heading or a round button label does not outgrow its place: 1.3 means it is drawn at most 1.3 times its fontSize however big the option is. It only limits growth: at a text size below the cap it is drawn at the player's size. 0 (default) = no cap. Measuring (autoSize, layout, ui.measureText, ui.rectOf) and drawing use the same capped size.
     * @since unreleased
     */
    maxTextScale: number;
    /**
     * Label colour.
     * @since 0.2.0
     */
    get textColor(): Color;
    set textColor(value: ColorLike);
    /**
     * true (default): drawn and listed as visible only while the last input came from a finger (input.lastDevice "touch"; a phone or tablet starts that way), so it hides when the player picks up a gamepad or a keyboard and comes back on the next touch. A finger landing on it always works. false: always drawn (desktop previews, screenshots, tests).
     * @since 0.2.0
     */
    touchOnly: boolean;
    /**
     * Runtime: a finger holds the button. Read-only.
     * @since 0.2.0
     */
    readonly pressed: boolean;
    /**
     * Runtime: drawn this frame (see touchOnly). Read-only.
     * @since 0.2.0
     */
    readonly shown: boolean;
  }
  /**
   * The subtitles of the game (docs/TEXT.md, "Captions"): draws the lines that `audio.play(path, { caption })` and `ui.caption(text, seconds)` put on the caption list, the newest `maxLines` of them, at the bottom of this entity's rectangle on a background that hugs the text. Text is drawn like Text: it follows ui.textScale, the localization font chain and right-to-left languages. Put ONE per scene (or in a persistent HUD). Without any Captions entity captions are still tracked (game.captions() in tests lists them) but nothing is drawn, and the log says so once. An inactive Captions entity draws nothing either: that is how a "Subtitles" option turns them off. Defaults: bottom centre of the safe area, 960 x 180, over a dark background.
   * 
   * Category: UI
   * @since 0.2.0
   */
  export interface CaptionsComponent {
    /**
     * Size [w, h] in design pixels. The default depends on the kind (Button 240 x 56, Toggle 240 x 40, Slider 320 x 40, TextField 320 x 48, Panel and ScrollList 320 x 240, TouchStick 200 x 200, TouchButton 96 x 96, Captions 960 x 180, Video 640 x 360). A Panel with fit = true recomputes it every frame.
     * @since 0.2.0
     */
    get size(): Vec2;
    set size(value: Vec2Like);
    /**
     * Which point of the widget sits on the position: [0.5, 0.5] = its centre (default), [0, 1] = top-left corner, [1, 0] = bottom-right. Same meaning as Shape2D.pivot in screen space: +Y is down on screen but pivot [0, 1] is still the visual top-left. Layout does not care about the pivot of its children.
     * @since 0.2.0
     */
    get pivot(): Vec2;
    set pivot(value: Vec2Like);
    /**
     * Screen point the position is relative to, as a fraction of the screen: [0, 0] top-left (default), [1, 0] top-right, [0.5, 0.5] centre. Anchor [0.5, 0.5] with position [0, 0] centres the widget on any aspect ratio. The anchor of the widget itself is used, not its parent's: children of a Panel normally keep anchor [0, 0] and are placed by the Panel's layout.
     * @since 0.2.0
     */
    get anchor(): Vec2;
    set anchor(value: Vec2Like);
    /**
     * Screen space only. true: the anchor names a point of the SAFE area, the screen minus the notch, rounded corners and system bars of a phone (screen.safeArea in scripts), instead of the whole screen: anchor [0, 0] is the top-left corner of the safe area, [1, 1] its bottom-right. Keeps HUD and buttons out of the notch. On a screen without cutouts (desktop, most tablets) it changes nothing. Default false (true on TouchStick and TouchButton).
     * @since 0.2.0
     */
    safeArea: boolean;
    /**
     * Draw order of the background; higher is on top. Defaults to 200, above HUD Text (layer 100). The label draws at layer + 1 and the focus ring at layer + 2. Pointer hit-testing follows the same order: the highest layer, then the latest entity, under the pointer is the hovered widget.
     * @since 0.2.0
     */
    layer: number;
    /**
     * Background colour, multiplied with `texture` when there is one. Hovered widgets are brightened, pressed ones darkened, non-interactable ones drawn at half alpha. Accepts [r,g,b,a], "#rrggbb" or a name.
     * @since 0.2.0
     */
    get color(): Color;
    set color(value: ColorLike);
    /**
     * Optional background image (project path), drawn as a 9-slice (see `slice`) with nearest-neighbour sampling, so pixel art stays crisp. Empty draws a solid rectangle of `color`. (asset path: texture)
     * @since 0.2.0
     */
    texture: string;
    /**
     * 9-slice borders in TEXTURE pixels [left, top, right, bottom]. The four corners are drawn unscaled (1 texture pixel = 1 design pixel), the edges stretch along one axis and the centre along both, so one small image gives panels of any size. [0, 0, 0, 0] (default) stretches the whole image. When the widget is smaller than left + right (or top + bottom) the borders shrink proportionally.
     * @since 0.2.0
     */
    get slice(): Vec3 & { w: number };
    set slice(value: readonly number[] | { x: number; y: number; z: number; w: number });
    /**
     * How many captions show at once. When more are on the list the oldest are not drawn (they stay on the list until their sound ends or their seconds run out).
     * @since 0.2.0
     */
    maxLines: number;
    /**
     * Space [left, top, right, bottom] between the edge of the background and the text.
     * @since 0.2.0
     */
    get padding(): Vec3 & { w: number };
    set padding(value: readonly number[] | { x: number; y: number; z: number; w: number });
    /**
     * Font of the captions: project path of a .ttf, empty = the built-in font (same values as Text.font). (asset path: font)
     * @since 0.2.0
     */
    font: string;
    /**
     * Glyph height in design pixels, before ui.textScale.
     * @since 0.2.0
     */
    fontSize: number;
    /**
     * Colour of the caption text.
     * @since 0.2.0
     */
    get textColor(): Color;
    set textColor(value: ColorLike);
    /**
     * Colour of the speaker's name, drawn before the line ("Mara:"). Captions without a speaker have no name.
     * @since 0.2.0
     */
    get speakerColor(): Color;
    set speakerColor(value: ColorLike);
    /**
     * Where the block of captions sits inside the rectangle's width, and how the lines align in it. Same values as Text.align: start / end follow the language (start = right in Arabic or Hebrew).
     * @since 0.2.0
     */
    align: "left" | "center" | "right" | "start" | "end";
    /**
     * Gap in design pixels between two captions.
     * @since 0.2.0
     */
    spacing: number;
    /**
     * Runtime: what is drawn now, [{text, speaker}] oldest first, at most `maxLines`. Written by the engine every frame from the caption list; do not edit it. Read-only. Returns a plain-object COPY; assign a new value to write.
     * @since 0.2.0
     */
    readonly lines: any;
  }
  /**
   * A video on the screen (docs/MENUS.md, "Studio intro"): plays an .mpg file (MPEG-1 video with MP2 sound, the same decoder on every platform) in this entity's rectangle, the way an image fills a widget. Convert any other video with `factoria call assets.import '{"source":"intro.mp4"}'` (needs ffmpeg: `factoria setup ffmpeg`). The sound plays on the mixer bus `bus` at `volume`. Time follows the game clock: the video pauses with the game (time.scale 0) and a headless run shows the same pictures at the same times as a windowed one. Control it from a script with `entity.video.play()`, `pause()`, `stop()`, `seek(seconds)` and read `time`, `duration`, `playing`; when it reaches its end the game event `video.ended` ({id, path}) fires once (`entity.video.on("ended", fn)`). The picture is decoded on the CPU: keep videos at most about 1280 x 720. Defaults: 640 x 360, a black background (shown as bars where the picture does not fill the rectangle), starts playing at once.
   * 
   * Category: UI
   * @since unreleased
   */
  export interface VideoComponent {
    /**
     * Size [w, h] in design pixels. The default depends on the kind (Button 240 x 56, Toggle 240 x 40, Slider 320 x 40, TextField 320 x 48, Panel and ScrollList 320 x 240, TouchStick 200 x 200, TouchButton 96 x 96, Captions 960 x 180, Video 640 x 360). A Panel with fit = true recomputes it every frame.
     * @since unreleased
     */
    get size(): Vec2;
    set size(value: Vec2Like);
    /**
     * Which point of the widget sits on the position: [0.5, 0.5] = its centre (default), [0, 1] = top-left corner, [1, 0] = bottom-right. Same meaning as Shape2D.pivot in screen space: +Y is down on screen but pivot [0, 1] is still the visual top-left. Layout does not care about the pivot of its children.
     * @since unreleased
     */
    get pivot(): Vec2;
    set pivot(value: Vec2Like);
    /**
     * Screen point the position is relative to, as a fraction of the screen: [0, 0] top-left (default), [1, 0] top-right, [0.5, 0.5] centre. Anchor [0.5, 0.5] with position [0, 0] centres the widget on any aspect ratio. The anchor of the widget itself is used, not its parent's: children of a Panel normally keep anchor [0, 0] and are placed by the Panel's layout.
     * @since unreleased
     */
    get anchor(): Vec2;
    set anchor(value: Vec2Like);
    /**
     * Screen space only. true: the anchor names a point of the SAFE area, the screen minus the notch, rounded corners and system bars of a phone (screen.safeArea in scripts), instead of the whole screen: anchor [0, 0] is the top-left corner of the safe area, [1, 1] its bottom-right. Keeps HUD and buttons out of the notch. On a screen without cutouts (desktop, most tablets) it changes nothing. Default false (true on TouchStick and TouchButton).
     * @since unreleased
     */
    safeArea: boolean;
    /**
     * Draw order of the background; higher is on top. Defaults to 200, above HUD Text (layer 100). The label draws at layer + 1 and the focus ring at layer + 2. Pointer hit-testing follows the same order: the highest layer, then the latest entity, under the pointer is the hovered widget.
     * @since unreleased
     */
    layer: number;
    /**
     * Background colour, multiplied with `texture` when there is one. Hovered widgets are brightened, pressed ones darkened, non-interactable ones drawn at half alpha. Accepts [r,g,b,a], "#rrggbb" or a name.
     * @since unreleased
     */
    get color(): Color;
    set color(value: ColorLike);
    /**
     * Optional background image (project path), drawn as a 9-slice (see `slice`) with nearest-neighbour sampling, so pixel art stays crisp. Empty draws a solid rectangle of `color`. (asset path: texture)
     * @since unreleased
     */
    texture: string;
    /**
     * 9-slice borders in TEXTURE pixels [left, top, right, bottom]. The four corners are drawn unscaled (1 texture pixel = 1 design pixel), the edges stretch along one axis and the centre along both, so one small image gives panels of any size. [0, 0, 0, 0] (default) stretches the whole image. When the widget is smaller than left + right (or top + bottom) the borders shrink proportionally.
     * @since unreleased
     */
    get slice(): Vec3 & { w: number };
    set slice(value: readonly number[] | { x: number; y: number; z: number; w: number });
    /**
     * Project path of the video (.mpg). Changing it opens the new file (and starts it again when `autoplay`). A file that is missing or is not MPEG-1 video is logged once and the entity draws only its background. (asset path: video)
     * @since unreleased
     */
    path: string;
    /**
     * true (default): `playing` becomes true as soon as the file is open. false: it waits for `entity.video.play()` or `playing = true`, showing the first picture.
     * @since unreleased
     */
    autoplay: boolean;
    /**
     * true: at the end the video starts over from the beginning, picture and sound (no `video.ended` event). false: it stops on its last picture and fires `video.ended`.
     * @since unreleased
     */
    loop: boolean;
    /**
     * Loudness of the sound, 0 (silent) to 1 (full), before the bus volume.
     * @since unreleased
     */
    volume: number;
    /**
     * Mixer bus of the sound: "sfx" (default), "music" or "ui". The bus volumes of a Settings menu apply to it like to any other sound. Any other name plays on sfx.
     * @since unreleased
     */
    bus: string;
    /**
     * How the picture fills the rectangle: contain (default) shows all of it, with bars of `color` where the shapes differ; cover fills the rectangle and cuts off what overflows; stretch fills it and distorts the picture.
     * @since unreleased
     */
    fit: "contain" | "cover" | "stretch";
    /**
     * Colour multiplied with the picture: white (default) leaves it as it is, alpha below 1 fades the video over what is behind it. `color` (the background) is a separate colour.
     * @since unreleased
     */
    get tint(): Color;
    set tint(value: ColorLike);
    /**
     * Runtime: true while the video advances. Set true to play (from the start when it had ended), false to pause. Becomes false when the video ends.
     * @since unreleased
     */
    playing: boolean;
    /**
     * Runtime: true once the video reached its end (never while `loop`); false again after a seek or a restart. Read-only.
     * @since unreleased
     */
    readonly ended: boolean;
    /**
     * Runtime: seconds into the video, 0 .. duration. Assign to seek (the picture and the sound jump there).
     * @since unreleased
     */
    time: number;
    /**
     * Runtime: length of the video in seconds; 0 while the file is not open. Read-only.
     * @since unreleased
     */
    readonly duration: number;
  }
  /**
   * Attaches JavaScript behaviour to the entity. `path` is an ES module whose default export is a class extending Behaviour (see docs/SCRIPTING.md).
   * 
   * Category: Scripting
   */
  export interface ScriptComponent {
    /**
     * Project-relative path of the script, e.g. "scripts/player.js". (asset path: script)
     */
    path: string;
    /**
     * JSON object of tunable values assigned onto the behaviour instance (this.speed = props.speed) before onStart. Lets one script serve many entities with different settings. Returns a plain-object COPY; assign a new value to write.
     */
    props: any;
    /**
     * false = the script receives no callbacks.
     */
    enabled: boolean;
  }
  /**
   * Scene-wide settings stored under "settings" in the scene file: lighting, fog, gravity and background music.
   * 
   * Category: Scene
   */
  export interface SceneSettingsComponent {
    /**
     * Base light added to all lit 3D surfaces so shadows are not pitch black. It is also the base light of lit 2D visuals (Sprite.lit, Tilemap.lit): a lit sprite shows its texture multiplied by this colour plus the Light2D lights. Raise it to [1, 1, 1] and the lit sprites look unlit.
     */
    get ambientLight(): Color;
    set ambientLight(value: ColorLike);
    /**
     * 2D gravity [x, y] in world units/s^2 (default 980 pixels/s^2 downwards).
     */
    get gravity2D(): Vec2;
    set gravity2D(value: Vec2Like);
    /**
     * 3D gravity [x, y, z] in m/s^2 (default 9.81 downwards).
     */
    get gravity3D(): Vec3;
    set gravity3D(value: Vec3Like);
    /**
     * Color distant 3D objects fade to.
     */
    get fogColor(): Color;
    set fogColor(value: ColorLike);
    /**
     * Fog thickness; 0 disables fog.
     */
    fogDensity: number;
    /**
     * Top color of the 3D background gradient (used when a perspective camera clears).
     */
    get skyColor(): Color;
    set skyColor(value: ColorLike);
    /**
     * Bottom color of the 3D background gradient.
     */
    get horizonColor(): Color;
    set horizonColor(value: ColorLike);
    /**
     * Looping background music asset path. Empty = none. (asset path: audio)
     */
    music: string;
    /**
     * Volume of the background music, 0..1.
     */
    musicVolume: number;
  }
  /** Component views by name, as returned by entity.get(name). */
  export interface Components {
    EntityInfo: EntityInfoComponent;
    Transform: TransformComponent;
    Camera: CameraComponent;
    Sprite: SpriteComponent;
    Parallax: ParallaxComponent;
    Light2D: Light2DComponent;
    SpriteAnimator: SpriteAnimatorComponent;
    Shape2D: Shape2DComponent;
    Text: TextComponent;
    Tilemap: TilemapComponent;
    ParticleEmitter: ParticleEmitterComponent;
    MeshRenderer: MeshRendererComponent;
    Light: LightComponent;
    Animator: AnimatorComponent;
    RigidBody2D: RigidBody2DComponent;
    Collider2D: Collider2DComponent;
    Joint2D: Joint2DComponent;
    RigidBody3D: RigidBody3DComponent;
    Collider3D: Collider3DComponent;
    Joint3D: Joint3DComponent;
    CharacterController3D: CharacterController3DComponent;
    NavMesh3D: NavMesh3DComponent;
    NavLink3D: NavLink3DComponent;
    AudioSource: AudioSourceComponent;
    AudioListener: AudioListenerComponent;
    Panel: PanelComponent;
    Button: ButtonComponent;
    Toggle: ToggleComponent;
    Slider: SliderComponent;
    TextField: TextFieldComponent;
    ScrollList: ScrollListComponent;
    TouchStick: TouchStickComponent;
    TouchButton: TouchButtonComponent;
    Captions: CaptionsComponent;
    Video: VideoComponent;
    Script: ScriptComponent;
    SceneSettings: SceneSettingsComponent;
  }
  /** Field objects accepted by entity.add(name, fields) / entity.set(name, fields) and world.spawn. */
  export interface ComponentInit {
    EntityInfo: { id?: string; name?: string; active?: boolean };
    Transform: { position?: Vec3Like; rotation?: Vec3Like; scale?: Vec3Like };
    Camera: { projection?: "orthographic" | "perspective"; fov?: number; orthoSize?: number; nearPlane?: number; farPlane?: number; clearColor?: ColorLike; clear?: boolean; primary?: boolean; depth?: number; bloom?: boolean; bloomThreshold?: number; bloomIntensity?: number; bloomRadius?: number; bloomScreenSpace?: boolean; colorFilter?: "none" | "greyscale" | "highContrast" | "protanopia" | "deuteranopia" | "tritanopia" };
    Sprite: { texture?: string; region?: RectLike; size?: Vec2Like; pivot?: Vec2Like; color?: ColorLike; flipX?: boolean; flipY?: boolean; layer?: number; space?: "world" | "screen"; pixelArt?: boolean; blend?: "alpha" | "additive" | "multiply"; anchor?: Vec2Like; safeArea?: boolean; slice?: readonly number[] | { x: number; y: number; z: number; w: number }; lit?: boolean; normalMap?: string };
    Parallax: { factor?: Vec2Like; repeatX?: boolean; repeatY?: boolean; repeatSize?: Vec2Like };
    Light2D: { type?: "point" | "directional"; color?: ColorLike; intensity?: number; radius?: number; falloff?: number; height?: number; direction?: number; elevation?: number };
    SpriteAnimator: { columns?: number; rows?: number; firstFrame?: number; lastFrame?: number; fps?: number; loop?: boolean; playing?: boolean; time?: number; frame?: number };
    Shape2D: { shape?: "rectangle" | "circle" | "line" | "triangle" | "diamond" | "polygon" | "star"; size?: Vec2Like; color?: ColorLike; filled?: boolean; thickness?: number; layer?: number; space?: "world" | "screen"; pivot?: Vec2Like; blend?: "alpha" | "additive" | "multiply"; anchor?: Vec2Like; safeArea?: boolean; sides?: number; points?: number; innerRadius?: number; lit?: boolean };
    Text: { text?: string; key?: string; keyArgs?: any; font?: string; fontSize?: number; color?: ColorLike; align?: "left" | "center" | "right" | "start" | "end"; pivot?: Vec2Like; maxWidth?: number; maxHeight?: number; autoShrink?: boolean; minFontSize?: number; maxTextScale?: number; layer?: number; space?: "world" | "screen"; anchor?: Vec2Like; safeArea?: boolean };
    Tilemap: { tileset?: string; tileSize?: Vec2Like; columns?: number; width?: number; height?: number; tiles?: any; solidTiles?: any; color?: ColorLike; layer?: number; lit?: boolean; normalMap?: string };
    ParticleEmitter: { emitting?: boolean; rate?: number; burst?: number; maxParticles?: number; lifetime?: number; lifetimeVariance?: number; speed?: number; speedVariance?: number; direction?: number; spread?: number; gravity?: Vec3Like; startSize?: number; endSize?: number; startColor?: ColorLike; endColor?: ColorLike; texture?: string; worldSpace?: boolean; is3D?: boolean; layer?: number; blend?: "alpha" | "additive" | "multiply"; autoDestroy?: boolean; space?: "world" | "screen"; anchor?: Vec2Like; safeArea?: boolean };
    MeshRenderer: { mesh?: string; texture?: string; normalMap?: string; normalScale?: number; color?: ColorLike; metallic?: number; roughness?: number; emissive?: ColorLike; unlit?: boolean; castShadows?: boolean; receiveShadows?: boolean; uvScale?: Vec2Like; material?: string; materialParams?: any; materialColors?: any };
    Light: { type?: "directional" | "point" | "spot"; color?: ColorLike; intensity?: number; range?: number; spotAngle?: number; castShadows?: boolean };
    Animator: { model?: string; clip?: string; speed?: number; loop?: boolean; playing?: boolean; fade?: number; params?: any; states?: any; transitions?: any; events?: any; state?: string; time?: number; values?: any };
    RigidBody2D: { type?: "static" | "dynamic" | "kinematic"; gravityScale?: number; linearDamping?: number; angularDamping?: number; fixedRotation?: boolean; bullet?: boolean; velocity?: Vec2Like; angularVelocity?: number };
    Collider2D: { shape?: "box" | "circle" | "capsule"; size?: Vec2Like; radius?: number; offset?: Vec2Like; isTrigger?: boolean; friction?: number; restitution?: number; density?: number; layer?: number; mask?: number; oneWay?: boolean };
    Joint2D: { type?: "revolute" | "distance" | "prismatic" | "weld"; connected?: EntityLike; anchor?: Vec2Like; connectedAnchor?: Vec2Like; axis?: Vec2Like; collideConnected?: boolean; length?: number; enableLimit?: boolean; lowerLimit?: number; upperLimit?: number; enableMotor?: boolean; motorSpeed?: number; maxMotorTorque?: number; enableSpring?: boolean; springHertz?: number; dampingRatio?: number };
    RigidBody3D: { type?: "static" | "dynamic" | "kinematic"; mass?: number; gravityScale?: number; linearDamping?: number; velocity?: Vec3Like; angularVelocity?: Vec3Like; rollWithMotion?: boolean; rollingFriction?: number; angularDamping?: number; lockRotation?: boolean };
    Collider3D: { shape?: "box" | "sphere" | "capsule" | "convex" | "mesh"; size?: Vec3Like; radius?: number; height?: number; mesh?: string; offset?: Vec3Like; isTrigger?: boolean; friction?: number; restitution?: number; layer?: number; mask?: number; navObstacle?: boolean; navWalkable?: boolean };
    Joint3D: { type?: "hinge" | "ball" | "fixed"; connected?: EntityLike; anchor?: Vec3Like; connectedAnchor?: Vec3Like; autoAnchor?: boolean; axis?: Vec3Like; useLimits?: boolean; lowerLimit?: number; upperLimit?: number; useMotor?: boolean; motorSpeed?: number; maxMotorTorque?: number; collideConnected?: boolean; damping?: number };
    CharacterController3D: { radius?: number; height?: number; center?: Vec3Like; stepOffset?: number; slopeLimit?: number; skin?: number; layer?: number; mask?: number; velocity?: Vec3Like; carriedByPlatforms?: boolean; applyWeight?: boolean; mass?: number; pushStrength?: number };
    NavMesh3D: { size?: Vec3Like; cellSize?: number; cellHeight?: number; agentRadius?: number; agentHeight?: number; stepHeight?: number; maxSlope?: number; autoBake?: boolean; enabled?: boolean };
    NavLink3D: { end?: Vec3Like; bidirectional?: boolean; cost?: number };
    AudioSource: { clip?: string; volume?: number; pitch?: number; loop?: boolean; playOnStart?: boolean; playing?: boolean; spatial?: boolean; range?: number };
    AudioListener: { volume?: number };
    Panel: { size?: Vec2Like; pivot?: Vec2Like; anchor?: Vec2Like; safeArea?: boolean; layer?: number; color?: ColorLike; texture?: string; slice?: readonly number[] | { x: number; y: number; z: number; w: number }; layout?: "none" | "row" | "column" | "grid"; spacing?: number; padding?: readonly number[] | { x: number; y: number; z: number; w: number }; columns?: number; align?: "start" | "center" | "end"; justify?: "start" | "center" | "end"; direction?: "ltr" | "auto" | "rtl"; fit?: boolean; uniformSize?: boolean; fallbackLayout?: "none" | "row" | "column" | "grid" };
    Button: { size?: Vec2Like; pivot?: Vec2Like; anchor?: Vec2Like; safeArea?: boolean; layer?: number; color?: ColorLike; texture?: string; slice?: readonly number[] | { x: number; y: number; z: number; w: number }; font?: string; key?: string; keyArgs?: any; fontSize?: number; maxTextScale?: number; textColor?: ColorLike; accentColor?: ColorLike; interactable?: boolean; autoFocus?: boolean; text?: string; maxWidth?: number; autoSize?: boolean; autoShrink?: boolean; minFontSize?: number };
    Toggle: { size?: Vec2Like; pivot?: Vec2Like; anchor?: Vec2Like; safeArea?: boolean; layer?: number; color?: ColorLike; texture?: string; slice?: readonly number[] | { x: number; y: number; z: number; w: number }; font?: string; key?: string; keyArgs?: any; fontSize?: number; maxTextScale?: number; textColor?: ColorLike; accentColor?: ColorLike; interactable?: boolean; autoFocus?: boolean; label?: string; maxWidth?: number; autoSize?: boolean; autoShrink?: boolean; minFontSize?: number; value?: boolean };
    Slider: { size?: Vec2Like; pivot?: Vec2Like; anchor?: Vec2Like; safeArea?: boolean; layer?: number; color?: ColorLike; texture?: string; slice?: readonly number[] | { x: number; y: number; z: number; w: number }; font?: string; key?: string; keyArgs?: any; fontSize?: number; maxTextScale?: number; textColor?: ColorLike; accentColor?: ColorLike; interactable?: boolean; autoFocus?: boolean; label?: string; maxWidth?: number; labelAbove?: boolean; autoSize?: boolean; autoShrink?: boolean; minFontSize?: number; value?: number; min?: number; max?: number; step?: number; showValue?: boolean; format?: string; formatKey?: string };
    TextField: { size?: Vec2Like; pivot?: Vec2Like; anchor?: Vec2Like; safeArea?: boolean; layer?: number; color?: ColorLike; texture?: string; slice?: readonly number[] | { x: number; y: number; z: number; w: number }; font?: string; key?: string; keyArgs?: any; fontSize?: number; maxTextScale?: number; textColor?: ColorLike; accentColor?: ColorLike; interactable?: boolean; autoFocus?: boolean; text?: string; placeholder?: string; maxLength?: number };
    ScrollList: { size?: Vec2Like; pivot?: Vec2Like; anchor?: Vec2Like; safeArea?: boolean; layer?: number; color?: ColorLike; texture?: string; slice?: readonly number[] | { x: number; y: number; z: number; w: number }; spacing?: number; padding?: readonly number[] | { x: number; y: number; z: number; w: number }; scroll?: number; scrollSpeed?: number; fill?: boolean; shrink?: boolean };
    TouchStick: { size?: Vec2Like; pivot?: Vec2Like; anchor?: Vec2Like; safeArea?: boolean; layer?: number; color?: ColorLike; texture?: string; slice?: readonly number[] | { x: number; y: number; z: number; w: number }; stick?: "left" | "right"; knobColor?: ColorLike; touchOnly?: boolean };
    TouchButton: { size?: Vec2Like; pivot?: Vec2Like; anchor?: Vec2Like; safeArea?: boolean; layer?: number; color?: ColorLike; texture?: string; slice?: readonly number[] | { x: number; y: number; z: number; w: number }; button?: "A" | "B" | "X" | "Y" | "Start" | "Back" | "Guide" | "DpadLeft" | "DpadRight" | "DpadUp" | "DpadDown" | "LeftShoulder" | "RightShoulder" | "LeftThumb" | "RightThumb"; text?: string; key?: string; keyArgs?: any; font?: string; fontSize?: number; autoShrink?: boolean; minFontSize?: number; maxTextScale?: number; textColor?: ColorLike; touchOnly?: boolean };
    Captions: { size?: Vec2Like; pivot?: Vec2Like; anchor?: Vec2Like; safeArea?: boolean; layer?: number; color?: ColorLike; texture?: string; slice?: readonly number[] | { x: number; y: number; z: number; w: number }; maxLines?: number; padding?: readonly number[] | { x: number; y: number; z: number; w: number }; font?: string; fontSize?: number; textColor?: ColorLike; speakerColor?: ColorLike; align?: "left" | "center" | "right" | "start" | "end"; spacing?: number };
    Video: { size?: Vec2Like; pivot?: Vec2Like; anchor?: Vec2Like; safeArea?: boolean; layer?: number; color?: ColorLike; texture?: string; slice?: readonly number[] | { x: number; y: number; z: number; w: number }; path?: string; autoplay?: boolean; loop?: boolean; volume?: number; bus?: string; fit?: "contain" | "cover" | "stretch"; tint?: ColorLike; playing?: boolean; time?: number };
    Script: { path?: string; props?: any; enabled?: boolean };
    SceneSettings: { ambientLight?: ColorLike; gravity2D?: Vec2Like; gravity3D?: Vec3Like; fogColor?: ColorLike; fogDensity?: number; skyColor?: ColorLike; horizonColor?: ColorLike; music?: string; musicVolume?: number };
  }
  /**
   * The native plugins of this game (factoria.json "plugins"): plugins.<plugin>.<function>(...args).
   */
  export interface PluginsAPI {
    readonly [plugin: string]: Record<string, (...args: any[]) => any> | undefined;
  }
}

/**
 * Test API for tests/*.test.js, run headless by `factoria test`.
 */
declare module "factoria:test" {
  import type { Entity, WorldAPI, TimeAPI, Json, Vec2Like, GamepadButton, GamepadAxis } from "factoria";
  /**
   * Matchers returned by expect().
   */
  export interface Expectation {
    /**
     * Strict equality (Object.is).
     */
    toBe(expected: unknown): void;
    /**
     * Deep equality (vectors compared by value).
     */
    toEqual(expected: unknown): void;
    toBeCloseTo(expected: number, digits?: number): void;
    toBeGreaterThan(n: number): void;
    toBeGreaterThanOrEqual(n: number): void;
    toBeLessThan(n: number): void;
    toBeLessThanOrEqual(n: number): void;
    toBeTruthy(): void;
    toBeFalsy(): void;
    toBeNull(): void;
    toBeUndefined(): void;
    toBeDefined(): void;
    toBeNaN(): void;
    toContain(item: unknown): void;
    toHaveLength(n: number): void;
    toMatch(pattern: string | RegExp): void;
    /**
     * Every field of `subset` is in the received object with an equal value, recursively; the object may have more fields. Arrays must have the same length and each element matches its subset.
     */
    toMatchObject(subset: object): void;
    toBeInstanceOf(cls: Function): void;
    toThrow(expected?: string | RegExp | Function): void;
    /**
     * For expect(game.audioLog()): passes when a clip was played (path = project-relative path, file name like "jump.wav", or RegExp). times = exact count; plays whose clip failed to load do not count.
     */
    toContainPlayed(path: string | RegExp, options?: { times?: number; bus?: "sfx" | "music" | "ui"; source?: EntityLike }): void;
    /**
     * Same as toContainPlayed.
     */
    toHavePlayed(path: string | RegExp, options?: { times?: number; bus?: "sfx" | "music" | "ui"; source?: EntityLike }): void;
    /**
     * Negates the matcher.
     */
    readonly not: Expectation;
  }

  export interface TestFn {
    (name: string, fn: () => void | Promise<void>): void;
    skip(name: string, fn: () => void | Promise<void>): void;
  }

  export interface DescribeFn {
    (name: string, fn: () => void): void;
    skip(name: string, fn: () => void): void;
  }

  /**
   * One entry of game.captions(): a subtitle that is on the caption list.
   */
  export interface CaptionEntry {
    /**
     * The text shown, in the current language when it has a key.
     */
    readonly text: string;
    /**
     * The speaker's name, "" for none.
     */
    readonly speaker: string;
    /**
     * The localization key, "" for a plain-text caption.
     */
    readonly key: string;
    /**
     * "audio:<clip path>" for the caption of a sound, "ui" for ui.caption.
     */
    readonly source: string;
  }

  /**
   * One entry of game.spoken(): a ui.speak call (or ui.speak command) that was recorded instead of spoken.
   */
  export interface SpokenLine {
    /**
     * The text, as given.
     */
    readonly text: string;
    /**
     * The game language (i18n.language) when it was asked; "" when the game has no localization.
     */
    readonly language: string;
    /**
     * True when the call interrupted what was being said (the default), false when it queued.
     */
    readonly interrupt: boolean;
  }

  /**
   * One entry of game.audioLog(): a play request from audio.play/audio.music, an AudioSource component or scene music.
   */
  export interface AudioPlay {
    /**
     * Increasing id.
     */
    readonly seq: number;
    /**
     * time.frame when the sound was requested.
     */
    readonly frame: number;
    /**
     * time.elapsed (seconds) when the sound was requested.
     */
    readonly time: number;
    /**
     * Project-relative clip path.
     */
    readonly path: string;
    readonly volume: number;
    readonly pitch: number;
    readonly pan: number;
    readonly bus: "sfx" | "music" | "ui";
    readonly loop: boolean;
    /**
     * Started with audio.music() or SceneSettings.music.
     */
    readonly music: boolean;
    /**
     * Id of the entity whose AudioSource played it; "" for scripts and music.
     */
    readonly source: string;
    /**
     * false when the clip could not be loaded (the error is in the log).
     */
    readonly ok: boolean;
  }

  /**
   * A gamepad driven by a test, from game.gamepad(index). Like keyDown/keyUp, press/release/axis act at once and the game sees them on the next step.
   */
  export interface TestGamepad {
    /**
     * Holds a button down until release(); connects the pad. Unknown names throw with a suggestion.
     */
    press(button: GamepadButton): void;
    release(button: GamepadButton): void;
    /**
     * Press, step one frame, release, step one frame (like game.tap).
     */
    tap(button: GamepadButton): void;
    /**
     * Sets a stick (-1..1, +Y up) or trigger (0..1) as the device would; it stays until set again. Bound actions see it after the deadzone, so axis("LeftX", -1) is a full push left.
     */
    axis(axis: GamepadAxis, value: number): void;
    /**
     * Plugs the pad in (input.gamepad(i).connected becomes true).
     */
    connect(): void;
    /**
     * Unplugs the pad; what it held is released.
     */
    disconnect(): void;
    /**
     * Plugs the pad in as that family, so input.gamepad(i).type and input.buttonName() answer for it (tests start with "generic" pads, which use the Xbox names). An unknown family throws with a suggestion.
     */
    setType(type: "generic" | "xbox" | "playstation" | "nintendo" | "steamdeck"): void;
  }

  /**
   * One request the game made to the platform backend, as the fake backend logged it.
   */
  export interface TestPlatformCall {
    /**
     * 1, 2, 3... in the order of the requests.
     */
    readonly seq: number;
    /**
     * The engine frame it was made in (counted from the start of the test file or the last reset).
     */
    readonly frame: number;
    /**
     * "achievements.unlock", "purchases.buy"... (docs/PLATFORM.md lists them).
     */
    readonly method: string;
    /**
     * The arguments the backend got, with the store's id (storeId) filled in.
     */
    readonly args: Json;
    /**
     * False when the request failed or was rejected; absent while it is waiting for an answer (delayFrames).
     */
    readonly ok?: boolean;
    /**
     * The answer, when ok.
     */
    readonly result?: Json;
    /**
     * The error, when not ok.
     */
    readonly error?: { code: string; message: string; hint: string };
  }

  /**
   * The fake store, for tests: script what it answers, send it events, look at what it holds. Each test file starts with a fresh one; the real backends are never touched by tests. Backed by the platform.* commands. See docs/PLATFORM.md.
   */
  export interface TestPlatform {
    /**
     * Queues the next answer(s) of a platform method (first in, first out, one per request). answer is { error: "network", message?, hint? } to reject, { result: value } to resolve with exactly that value, or any other object, which is merged into the default result: game.platform.respond("purchases.buy", { status: "cancelled" }). An unknown method throws with a suggestion.
     */
    respond(method: string, answer: Json, times?: number): void;
    /**
     * Sends an event as the store would; platform.on listeners get it at the next game.step(). A purchased "purchase" also records an unfinished transaction.
     */
    emit(event: "purchase" | "overlay" | "player", data?: Json): void;
    /**
     * Takes a purchase back, as a refund does: restore() no longer lists the product, its unfinished transaction is dropped and platform.on("purchase") listeners get { status: "revoked", productId, transactionId, receipt } at the next game.step(). Throws when the player owns no such product, listing the owned ones.
     */
    revoke(productId: string): void;
    /**
     * How the fake's test ad ends from now on: watched to the end (the default: rewarded), closedEarly (not rewarded), noFill (no ad: ads.available() is false) or consentRefused (also answers denied in ads.consent()). options.gdpr, options.tracking and options.privacyOptions set what ads.consent() answers (with privacyOptions "required", platform.ads.privacyOptions() counts a form shown); a denied gdpr stops every ad. reset() restores the defaults. state().fake.ads counts the ads shown and rewarded.
     */
    ad(outcome: "watched" | "closedEarly" | "noFill" | "consentRefused", options?: { gdpr?: "granted" | "denied" | "notRequired" | "unknown"; tracking?: "authorized" | "denied" | "notDetermined" | "restricted" | "notRequired"; privacyOptions?: "required" | "notRequired" | "unknown" }): void;
    /**
     * Fresh fake: nothing unlocked, bought or saved, no scripted answers, signed in.
     */
    reset(): void;
    /**
     * An unknown option throws with a "did you mean". backend "none" makes the fake behave as the none backend, the case of an exported game without a store plugin (platform.has false for every service, every call rejects "unavailable", signIn answers signed out) until platform.reset(). signedIn false rejects every call but signIn() with "notSignedIn"; delayFrames n holds each answer for n frames (0 = answered at once), so a test can check a "waiting" state and game.step(n) to get the answer.
     */
    set(options: { signedIn?: boolean; delayFrames?: number; backend?: "fake" | "none" }): void;
    /**
     * What the platform holds: { backend, services, player, catalog, pending, fake: { achievements, stats, leaderboards, cloud, owned, unfinished, presence, scripted, calls... } }.
     */
    state(): Json;
    /**
     * Every request the game made, oldest first (the request log of state().fake.calls).
     */
    calls(): TestPlatformCall[];
  }

  /**
   * Drives the running game from a test.
   */
  export interface TestGame {
    /**
     * Same as the script `game.paused`: true while time.scale is 0; setting it keeps and restores time.scale. Reading a member the test game does not have (game.pasued) throws with a did-you-mean.
     */
    paused: boolean;
    /**
     * Same as the script `game.today()`: 2026-01-01 at the start of every test, or the date of --date, until game.setDate().
     */
    today(): { readonly year: number; readonly month: number; readonly day: number; readonly weekday: number; readonly utcOffsetMinutes: number; readonly iso: string };
    /**
     * Same as the script `game.focused`.
     */
    readonly focused: boolean;
    /**
     * Sets the date game.today() answers, "YYYY-MM-DD", until the test ends (the next test starts from the run's date again). An impossible date such as "2026-02-29" or a wrong shape throws with what is wrong and how to fix it. Example: game.setDate("2026-10-23"); expect(game.today().weekday).toBe(5).
     */
    setDate(iso: string): void;
    /**
     * The app goes to the background, as on a phone: the game.on("suspend") handlers run at once and, with pauseOnSuspend (the default), the game and the music freeze (game.paused is true) unless a handler paused it itself. Every test starts running.
     */
    suspend(): void;
    /**
     * The app comes back: undoes the freeze suspend() made (a pause the game made itself stays) and runs the game.on("resume") handlers.
     */
    resume(): void;
    /**
     * The window gains the focus: game.focused becomes true and the game.on("focus") handlers run. Does nothing when it already had it.
     */
    focus(): void;
    /**
     * The window loses the focus: game.focused becomes false and the game.on("blur") handlers run. Does not pause anything (a window that lost the focus keeps running).
     */
    blur(): void;
    /**
     * Loads a scene immediately (reseeds the RNG). Behaviours are constructed right away (game.find(id).behaviour works); onStart runs on the first step().
     */
    load(path: string): void;
    /**
     * Files the engine has read from the disk since the run started. Read it twice and compare to prove that something read nothing: const before = game.fileReads(); scene.load(...); game.step(); expect(game.fileReads()).toBe(before). A file read ahead by scene.preload / assets.preload counts when it is preloaded, not when it is used.
     */
    fileReads(): number;
    /**
     * Simulates frames at the fixed rate.
     */
    step(frames?: number): void;
    /**
     * Holds an action down until release().
     */
    press(action: string): void;
    release(action: string): void;
    /**
     * Press for one frame, then release.
     */
    tap(action: string): void;
    keyDown(key: string): void;
    keyUp(key: string): void;
    /**
     * Types text as the keyboard would: input.text returns it until the next step(). Control characters are skipped, as the real keyboard does; press Enter and Backspace with keyDown()/keyUp() or tap().
     */
    typeText(text: string): void;
    /**
     * Drags a Slider to `value` as a player would: clamped to [min, max], snapped to step, the slider takes focus and ui.change {id, value} is sent when the number changed (ui.on listeners get it at the next step()). Writing Slider.value from a script sends nothing; this does. Throws when the entity has no Slider, or is inactive or not interactable.
     */
    setSlider(id: string, value: number): void;
    /**
     * Presses the system Back button of Android. The input.onBack handlers run at the next step(); when none consumes it the game asks to quit (game.quitRequested in game.state()).
     */
    pressBack(): void;
    /**
     * Pretends the device has a notch, rounded corners or system bars: insets in design pixels from each edge (0 for those left out), or the profile of a typical phone. screen.safeArea, screen.insets and the items with `safeArea: true` follow at once (take a step() before checking layout of UI widgets). A negative or non-number inset throws. Reset to "none" before every test.
     */
    setSafeArea(insets: { left?: number; top?: number; right?: number; bottom?: number } | "none" | "phone-portrait" | "phone-landscape"): void;
    /**
     * Pretends the game runs on another device: game.device follows at once (window.supports too, for the window features). Fields left out keep the headless values { formFactor: "desktop", gpuBackend: "headless", memoryGB: 8, tier: "high" }. An unknown field (with a suggestion) or a bad value throws. Reset before every test. Example: game.setDevice({ formFactor: "phone", tier: "low" }).
     */
    setDevice(overrides: { formFactor?: "desktop" | "phone" | "tablet"; gpuBackend?: string; memoryGB?: number; tier?: "low" | "medium" | "high" }): void;
    /**
     * What the renderer drew in the picture now, drawing a frame first when none has been drawn since the last change (a headless test may not have drawn one; game.state().renderStats stays zero until a frame is drawn). triangles and lights (the 3D lights) count the main pass, lights2d the Light2D lights shading 2D visuals (at most 16: directional first, then the point lights that reach the camera view; lights2dDropped are the ones left out), shadowCasters the meshes drawn into the shadow map, textureMB the GPU texture memory, width and height the size of the picture (design size * window.renderScale). The numbers perf.measure records and perf.check budgets. Throws without graphics. Example: expect(game.renderStats().triangles).toBeLessThan(200000).
     */
    renderStats(): { drawCalls: number; sprites: number; shapes: number; textGlyphs: number; particles: number; meshes: number; meshesCulled: number; meshBatches: number; triangles: number; shadowCasters: number; lights: number; lightsDropped: number; lights2d: number; lights2dDropped: number; materials: number; materialFallbacks: string[]; textureMB: number; width: number; height: number; renderScale: number };
    /**
     * Pretends the player's system has these accessibility settings: game.accessibility follows at once. Keys left out are the defaults (textScale 1, the others false); textScale is clamped to 0.5 - 4. An unknown key (with a suggestion), a non-boolean or a textScale that is not a number above 0 throws. Reset to the defaults before every test. Example: game.setAccessibility({ textScale: 1.5, reduceMotion: true }).
     */
    setAccessibility(settings: { textScale?: number; reduceMotion?: boolean; highContrast?: boolean; screenReader?: boolean }): void;
    /**
     * Sets the text the next storage load reads, in place of the save file (tests never touch the real storage.json), and drops the data already loaded: storage.get() and storage.corrupt then answer as at a start with that file. Pass a valid JSON object to start from a saved game, or broken text ("{\"hi") to test the damaged-save path: storage.corrupt is true and the data is empty. null goes back to an empty storage. Reset before every test file.
     */
    setStorageText(text: string | null): void;
    /**
     * The pulses input.vibrate() asked for since the test started, in seconds, oldest first (cleared before each test).
     */
    vibrations(): number[];
    /**
     * Drives gamepad 0..3 (default 0); a bad index throws. Actions bound to Gamepad* names react like they do to a real pad.
     */
    gamepad(index?: number): TestGamepad;
    /**
     * Holds a mouse button (default left) until mouseUp(): input.mouse.down(button) follows. With mouseMove() it tests a drag.
     */
    mouseDown(button?: "left" | "right" | "middle"): void;
    /**
     * Releases a mouse button held with mouseDown().
     */
    mouseUp(button?: "left" | "right" | "middle"): void;
    /**
     * Turns the mouse wheel by dy notches for the next frame (input.mouse.wheel); a non-number throws.
     */
    wheel(dy: number): void;
    /**
     * True once the game asked to quit during this test (game.quit(), or Back that no input.onBack handler consumed). A test run never stops because of it. Cleared before each test.
     */
    readonly quitRequested: boolean;
    /**
     * Pretends the device has these languages (BCP 47 tags, best first): i18n.systemLanguages answers them so a first-run language choice can be tested. An empty list means no system language. Reset (empty) before each test. Example: game.setSystemLanguages(["es-ES", "en"]).
     */
    setSystemLanguages(languages: string[]): void;
    /**
     * Resets what the tests of one file share (each file already starts clean): storage clears the save data and any setStorageText text; platform runs platform.reset (nothing bought or unlocked, no scripted answers, no leaderboard scores) and restores the test ad and consent answers. Both default to true; an unknown key throws with a suggestion.
     */
    resetState(options?: { storage?: boolean; platform?: boolean }): void;
    mouseMove(screenPos: Vec2Like): void;
    /**
     * Presses and releases a mouse button at the position (two steps). Pass a widget id or an Entity instead of a position to use the centre of its laid-out rectangle (safe area included; ui.rectOf).
     */
    click(target: Vec2Like | Entity | string, button?: "left" | "right" | "middle"): void;
    /**
     * Loads a scene given as JSON ({ format: "factoria.scene/1", entities: [...] }) instead of a file.
     */
    loadJson(scene: Json): void;
    /**
     * A finger down at screenPos for `frames` frames (input.touches[0].pressed on the first), then released. Like a finger on a device it also moves the mouse there and holds the left mouse button (see touchStart). Pass a widget id or an Entity instead of a position to use the centre of its laid-out rectangle (safe area included; ui.rectOf).
     */
    touch(target: Vec2Like | Entity | string, frames?: number): void;
    /**
     * Finger down (stays down until touchEnd). The first finger also drives the mouse as on a device: the mouse moves to screenPos and the left button goes down (input.mouse.pressed("left") on the first frame), so a script that reads both the mouse and touches sees both. Other fingers do not touch the mouse. Pass a widget id or an Entity instead of a position to use the centre of its laid-out rectangle (safe area included; ui.rectOf).
     */
    touchStart(target: Vec2Like | Entity | string, id?: number): void;
    /**
     * Moves a finger; the first finger drags the mouse with it.
     */
    touchMove(screenPos: Vec2Like, id?: number): void;
    /**
     * Lifts a finger; when it is the first finger, the left mouse button is released where it lifted.
     */
    touchEnd(id?: number): void;
    find(idOrName: string): Entity | null;
    readonly world: WorldAPI;
    readonly time: TimeAPI;
    /**
     * Saves a PNG of the game (needs graphics). options.scale (0.25 to 4, default 1) renders the same frame at that multiple of the design size, sharp, not upscaled: a 1280x720 game at scale 1.5 gives a 1920x1080 PNG with the same HUD and visible area (store screenshots). options.simulate converts the saved PNG to what a colour-blind viewer sees (greyscale, protanopia, deuteranopia, tritanopia: Machado 2009 matrices, severity 1.0, in linear light on the sRGB pixels) so a test or an AI checks that hazards read without their colour; the player's view (Camera.colorFilter) is not changed.
     */
    screenshot(path: string, options?: { scale?: number; simulate?: "none" | "greyscale" | "protanopia" | "deuteranopia" | "tritanopia" }): void;
    /**
     * JSON dump of the game state.
     */
    state(): Json;
    /**
     * Sounds played since the current test started (cleared before each test), oldest first. Assert with expect(game.audioLog()).toContainPlayed("assets/sfx/jump.wav").
     */
    audioLog(): AudioPlay[];
    /**
     * Empties the audio log (e.g. after setup, before the action under test).
     */
    clearAudioLog(): void;
    /**
     * What ui.speak was asked to say since the current test started (cleared before each test), oldest first: { text, language, interrupt }. Headless runs and tests speak nothing, they only record. Example: expect(game.spoken().map((l) => l.text)).toEqual(["Play", "Options"]).
     */
    spoken(): SpokenLine[];
    /**
     * Empties the list of spoken lines (e.g. after setup, before the action under test).
     */
    clearSpoken(): void;
    /**
     * The captions on the list now (cleared before each test), oldest first: { text, speaker, key, source }. `text` is in the current language, `key` is "" for plain text, `source` is "audio:<clip path>" or "ui". The Captions component draws the newest maxLines of them. Example: expect(game.captions().map((c) => c.text)).toEqual(["Welcome"]).
     */
    captions(): CaptionEntry[];
    /**
     * The fake store: game.platform.respond(...), emit(...), set(...), state(), calls().
     */
    readonly platform: TestPlatform;
  }

  /**
   * Declares a test.
   */
  export const test: TestFn;

  /**
   * Groups tests.
   */
  export const describe: DescribeFn;

  /**
   * Starts an assertion.
   */
  export function expect(value: unknown): Expectation;

  /**
   * What robust() hands to the check on each run.
   */
  export interface RobustRun {
    /**
     * 0 for the unperturbed run, then 1, 2, ...
     */
    run: number;
    /**
     * How many runs robust() makes.
     */
    runs: number;
    /**
     * Moves each entity (Entity or id) by a small repeatable offset of up to `nudge` metres on every axis. Does nothing on run 0. An id that is not in the scene throws.
     */
    nudge(...targets: (Entity | string)[]): void;
    /**
     * nudge() for every entity with a RigidBody3D or RigidBody2D. Call it after game.load and before the first game.step.
     */
    nudgeBodies(): void;
  }

  /**
   * Runs `check` `runs` times (default 5) under small perturbations (positions nudged by up to `nudge` metres, default 0.005; run 0 is unperturbed) and fails when any run fails, saying which one. Use it where a level test would otherwise assert something that depends on rounding (a chaotic rope bridge, an exact frame count): physics is exact per build but may differ on another compiler or CPU. The check must load its own scene (game.load) so each run starts fresh. The offsets are a hash of run, entity id and axis, not the RNG, so a test nudges the same way on every platform.
   */
  export function robust(check: (p: RobustRun) => void, options?: { runs?: number; nudge?: number }): void;

  /**
   * Runs before each test of the enclosing describe().
   */
  export function beforeEach(fn: () => void): void;

  /**
   * Runs after each test of the enclosing describe().
   */
  export function afterEach(fn: () => void): void;

  /**
   * The game under test.
   */
  export const game: TestGame;

}


```
