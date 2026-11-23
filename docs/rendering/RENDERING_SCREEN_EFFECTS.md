Part of [RENDERING.md](../RENDERING.md): the camera effects the post pass draws for a moment. The post-processing stack they are drawn with is
described on [RENDERING_POSTPROCESS.md](RENDERING_POSTPROCESS.md), in "Post-processing: bloom, exposure, tonemap, colour grading, lens effects, colour filter".

# Rendering: transient screen effects

## Transient screen effects: shockwave, heat haze, radial blur, flash, fade

Five effects a game fires for a moment (an explosion, a heat shimmer, a dash, a damage flash, a scene change) and that the camera's
`post` pass draws over the finished picture. They are not part of the scene (no component, nothing saved: a scene load ends them),
they need no `PostProcess` and work with the editor's post bypass on. A script calls them on a camera, tools and tests use the
`feel.*` commands, an animation clip event or an effect document uses the same options as a feel action:

```js
camera.main.shockwave({ screen: [0.5, 0.4], strength: 0.05, duration: 0.7 });     // or { world: enemy.position }
camera.main.heatHaze({ region: [0, 0.5, 1, 0.5], duration: 3 });
camera.main.radialBlur({ intensity: 0.5, duration: 0.4 });                         // a dash
camera.main.flash({ color: "#ff3030", duration: 0.15 });                           // damage
camera.main.fadeOut({ color: "#000000", duration: 0.8 });                          // holds until fadeIn
camera.main.fadeIn({ duration: 0.8 });
```

Commands `feel.shockwave`, `feel.heatHaze`, `feel.radialBlur`, `feel.screenFlash` and `feel.fade`; actions `shockwave`, `heatHaze`,
`radialBlur`, `screenFlash` and `fade` (`feel.do`, [GAME_FEEL.md](../GAME_FEEL.md)); `feel.state` lists what is alive
(`screenEffects`) and `feel.cancel` ends them.

- **Which camera.** `camera` (a script) or `entity` (a command) picks one camera; without it every camera that draws to the screen
  draws it (a camera with a `renderTarget` only when you name it). Points are fractions of the CAMERA's rectangle, (0, 0) at its
  top-left, so a split screen shows an effect on its own half. `world` gives a world point instead, projected by each camera; it
  is not drawn behind a perspective camera.
- **Clock.** The feel clock: real time times `time.scale`, so `time.scale 0` holds an effect still, and a hit-stop does not
  stop it. No wall clock: the same steps draw the same pictures (a screenshot test can step the game to a frame and compare).
- **Shockwave.** A ring of radius `radius` (a fraction of the picture's height, default 0.6) and width `width` (0.1) that leaves
  the centre fast and slows down; inside it the picture is pushed away from the centre by up to `strength` (0.04, a fraction of the
  height), smoothly to nothing at the ring's edges, and the push dies out as the ring grows. A camera draws the newest 4.
- **Heat haze.** The picture inside `region` ([x, y, w, h], default all of it) is pushed sideways by a ripple that travels up
  (`frequency` ripples per picture height, `speed` cycles per second, `strength` 0.004), fading in and out over 0.15 s at its ends
  and to nothing at the edge of the region. A camera draws the newest 2.
- **Radial blur pulse.** The same blur as `PostProcess.radialBlurEnabled` (the picture streaks away from `screen` or `world`,
  `intensity` 0..1, `samples` 4..32), with an intensity that dies out over `duration`. With the PostProcess blur on as well, the
  stronger of the two is drawn at each moment (one blur per camera).
- **Flash and fade.** One colour is blended over the picture at the end of the pass, after the film grain and before the
  dither and the colour filter, so the accessibility filter still changes it. `flash` starts at `strength` (1) and falls to 0 over
  `duration` (`fade: false` holds it, then switches it off). `fadeOut` goes to the colour (default black) and STAYS until `fadeIn`
  or `feel.cancel`; `fadeIn` goes from the colour to the picture (when nothing was faded it starts from the full colour, the way
  to open a scene); a fade that interrupts another continues from the opacity the old one had reached. Several flashes and fades of
  one camera are mixed oldest first.
- **Accessibility.** With `feel.reduceMotion` on a shockwave, heat haze and radial blur are a quarter of their strength; with
  `feel.reducedEffects` a flash is capped at 0.35 and always fades. A fade is not changed.
- **A camera that is destroyed** ends its effects (a held fade included) on the next frame.
- **Known limit: the outline.** The shockwave and the heat haze move the place the final pass reads the scene, but the outline
  (`PostProcess.outlineEnabled`) is found in the unmoved picture's depth or coverage image: its lines do not follow the
  displacement and can show for a moment next to the bent edge.
- **Bounds and cost.** At most 16 effects are alive in the world: a new call never fails, it ends the oldest effect (a held fade
  is the last to go). Past a camera's 4 shockwaves and 2 hazes the older ones are not drawn. With nothing alive a frame costs
  nothing (no uniforms, no extra work in the pass); with one, the `post` pass reads the scene a few more times (the radial blur
  taps, at most 32) and the final pass exists even without a `PostProcess` (the frame is then one pass of the effects).
  `render.supports {"feature": "radialBlur"}` is true where this build draws the blur; the other four need nothing but the final pass.
