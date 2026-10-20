[Back to the index](../README.md)

# Components: Camera

## Camera

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
| `colorFilter` | enum: none \\| greyscale \\| highContrast \\| protanopia \\| deuteranopia \\| tritanopia | `"none"` | Accessibility colour filter, the LAST post-process pass: it is applied to the whole finished frame (HUD included, after the bloom) on every graphics backend, so screenshots, factoria run --screenshot-at and --record-video show it too. A game's options screen sets it from the player's choice (it is not saved by itself). none (default): no pass, no cost. greyscale: Rec. 709 luminance in linear light. highContrast: contrast stretched 1.8x around mid grey, clipped. protanopia, deuteranopia, tritanopia: a daltonize correction for a player who lacks that cone: the loss is estimated with the Machado 2009 matrix (severity 1.0) and the lost information is shifted into the channels the player still sees (Fidaner's method), so colours that collapse together (red vs green) differ in brightness or in the remaining hue. To CHECK a game without changing what the player sees, use the `simulate` option of game.screenshot / --screenshot-simulate instead. (not released yet, on main after 0.1.6) |

