# Text: fonts, languages and text size

Every piece of text the engine draws goes through one layout: a `Text` component, the label of a `Button`, `Toggle`,
`Slider` or `TextField`, the debug overlay (`debug.text`), and the size `ui.measureText` and `entity.bounds()` report.
What you measure is what is drawn. This page says what that layout does, what a game has to ship for each language, and
what it does not do.

## What a game must ship

The built-in font is DejaVu Sans (`font: ""`): Latin, Greek, Cyrillic, Hebrew and Arabic letters, and common symbols
such as ★ ☆ ✓ ✗ ♥ ♪ ← → (a star rating needs no extra font; colour emoji such as ⭐ are not in it). `font: "builtin:pixel"`
is Press Start 2P (Latin only, for a retro look). **Nothing else is built in.** A game that shows Chinese, Japanese,
Korean, Thai, an Indic script or any other script DejaVu Sans lacks must ship a font that has it, as a `.ttf` file in the
project (`assets/fonts/`):

| Language | A free font (SIL Open Font License) |
|---|---|
| Japanese, Korean, Simplified or Traditional Chinese | Noto Sans JP, Noto Sans KR, Noto Sans SC, Noto Sans TC |
| Arabic, Persian, Urdu | Noto Sans Arabic (DejaVu Sans has the basic letters too) |
| Thai, Devanagari, Bengali, ... | the Noto Sans family has one font per script |

Keep the font's license file (`OFL.txt`) next to it: the OFL lets you ship and embed the font, and asks that its license
travels with it. `factoria export` writes the notices of the engine, not of your fonts. CJK fonts are big (a few MB to
10 MB): the player downloads what you ship, so subset the font to the characters the game uses if size matters (fontTools'
`pyftsubset` with `--layout-features='*'` keeps the shaping tables). A variable font (`NotoSansJP[wght].ttf`) draws its
default weight: instance it to a static file first (`fontTools.varLib.instancer`).

Colour emoji are not supported (the engine draws outlines of TrueType fonts only): an emoji draws as nothing, with a
warning. Draw emoji as sprites.

## The font chain

Each character is drawn by the first font of a chain that has a glyph for it:

1. the Text's own `font` (`""` = DejaVu Sans, or a project path, or `builtin:pixel`);
2. the fallback fonts, in the order they were registered (`Renderer::set_fallback_fonts`, a list of project paths or
   `builtin:pixel`; a fallback font is only loaded when some text needs it, and one that cannot be read is skipped with one
   logged error);
3. DejaVu Sans, always last.

So a game can keep `font: ""` on every Text and register `NotoSansJP`, `NotoSansKR` and `NotoSansArabic` as fallbacks: a
string of any language draws, each character from the first font that has it. Changing the list takes effect on the next
frame, for the Text already on screen too. A combining mark or joiner is shaped with its base letter, in the same font
when that font has it. Line height comes from the Text's own font (the first of the chain), whatever fonts the characters
come from; a fallback font with very tall letters can touch the next line, so give a CJK Text a CJK `font`.

### Fonts per language (`factoria.json`)

A localized game lists the fallback fonts in `factoria.json` (the `localization` section of
[LOCALIZATION.md](LOCALIZATION.md)); the engine hands the list to the renderer when the game starts and again at every
language switch:

```json
"localization": {
  "defaultLanguage": "en",
  "languages": ["en", "ja", "ar"],
  "fallbackFonts": ["assets/fonts/NotoSansArabic-Regular.ttf"],
  "languageFonts": { "ja": ["assets/fonts/NotoSansJP-Regular.ttf"] }
}
```

- `languageFonts[tag]` is the list for one language; it comes first while the game runs in `tag`. `fallbackFonts` follows
  for every language (the right place for a font every menu needs, such as one that has the names of all the languages).
- A language you did not list a font for draws with `fallbackFonts` and DejaVu Sans, so a Japanese player never loads
  `NotoSansKR` and a Korean player never loads `NotoSansJP`: a font is only read when some text needs it.
- A game without a `localization` section keeps the old way: give the Text the font it needs through its `font` field, or
  call `Renderer::set_fallback_fonts` from C++.
- The path of a font that is missing or is not a font is an error of `factoria validate`, at its JSON pointer.
  `factoria validate` also checks that these fonts have a glyph for every character of the string tables and of the texts
  written in scenes: [LOCALIZATION.md](LOCALIZATION.md), "Checks".

A character no font of the chain has draws as nothing, and the engine logs one warning per Text font that names the
characters (`U+65E5 '日'`) and what to do. To check text before it is drawn (a translation table, a scene) without a
window or a GPU, C++ tools use `fa::FontCoverage::load(chain)->missing(utf8)` or `fa::missing_glyphs(utf8, chain)` from
`fa/render/fonts.h`: they list the code points no font of the chain has. Spaces, controls, zero-width joiners, direction
marks and variation selectors never count, and a font that is missing or cannot be parsed is an error, not "missing
glyphs".

## Shaping

Text is shaped with HarfBuzz before it is drawn, so the font's own rules apply: kerning (`AV` sits closer than `A` + `V`),
ligatures (`fi` is one glyph in DejaVu Sans), combining accents, Arabic joining (a letter takes its initial, medial or
final form and the dots are marks placed on it), and the reordering and conjuncts of scripts such as Devanagari when the
font has the rules. Glyphs are rasterized from the glyph the shaper chose, so a ligature or a joined form is drawn exactly.
The engine's own tests cover Latin, Japanese, Chinese, Korean and Arabic; other scripts rely on HarfBuzz and the font, so
look at a screenshot (`game.screenshot`) of the first Text you write in a new script.

## Right-to-left text

Text is reordered with the Unicode bidirectional algorithm. The base direction of a text is the direction of its first
strong character: a text that starts with Arabic or Hebrew letters is a right-to-left paragraph, one that starts with Latin
letters or CJK is left-to-right (so is one with no letters at all). The text is wrapped in reading order first, then every
line is put in screen order, so `maxWidth` breaks an Arabic sentence where a reader expects it. Mixed text follows the
algorithm: `abc العربية 123` shows `abc 123 العربية` (the digits after Arabic letters read left to right, and sit where the
Arabic run starts).

**`align` is explicit and does not follow the text direction**: `"left"` is the left edge of the box and `"right"` the
right edge, for Arabic too. For an Arabic or Hebrew label, set `align: "right"` (and `pivot: [1, 1]`, or an `anchor` on the
right side of the screen) when it should hug the right edge. The first line of an unwrapped Text starts at the pivot as
usual.
`align: "start"` and `"end"` are the direction-aware values: start is the left edge in a left-to-right language and the
right edge in a right-to-left one (`i18n.direction`), so one Text serves English and Arabic. Panels mirror their rows with
`direction: "auto"` (docs/LOCALIZATION.md, section 6).

## Line breaking

With `maxWidth` > 0 a line breaks at spaces, and between two Japanese, Chinese or Korean characters (ideographs, kana and
Hangul syllables), so text written without spaces wraps. A simple kinsoku rule keeps closing punctuation (`。、」）！？`,
the prolonged sound mark `ー`, small kana, `…`) off the start of a line and opening brackets (`「（`) off the end. A space at
a break is not drawn, and a wrapped line starts with no spaces. `\n` always starts a new line, and a tab is four spaces.
A word (or an unbreakable run) wider than `maxWidth` stays on its own line and sticks out.

This is not the full Unicode line breaking algorithm (UAX #14): hyphens, numbers with units and the scripts that need a
dictionary to find word boundaries (Thai, Khmer, Lao) do not get break opportunities inside a word; wrap those with
explicit `\n` or spaces.

## Measuring

`ui.measureText(text, { fontSize, font, maxWidth, space, maxTextScale, autoShrink, minFontSize, maxHeight })` returns
`{ width, height, fontSize }` of exactly the layout that is drawn (`fontSize` is the size it is laid out at, in pixels), shaped and wrapped, with the fallback fonts. `space` is `"screen"` (the default: a HUD label, a widget label) or
`"world"`; it matters only for the text size option below. It is exact in tests, `factoria call` and headless runs
(they draw with an offscreen renderer); only when no graphics device can be created does it approximate 0.6 ×
`fontSize` per character and warn once. A wrapped text is as wide as its `maxWidth` and as tall as its lines.

## Text size (`ui.textScale`)

Players ask for bigger text. `ui.textScale` (a number from 0.5 to 3, 1 = normal) multiplies the font size of every
screen-space `Text` (`space: "screen"`) and of the labels of `Button`, `Toggle`, `Slider` and `TextField`; the engine
re-measures them, so `ui.measureText` and a layout `Panel` that fits its content follow it. World-space `Text` is part of
the world and is never scaled, nor is its `entity.bounds()`; debug text is not scaled either.

```js
import { ui, storage, math } from "factoria";
ui.textScale = math.clamp(storage.get("textScale") ?? 1, 0.5, 3);  // at start
// in the options menu:
ui.textScale = 1.5;
storage.set("textScale", ui.textScale);
```

- Setting a number outside 0.5 to 3 (or not a number) throws an error that says so: clamp a value you saved earlier
  (`math.clamp`). Over MCP or `factoria call` the command is `ui.set_text_scale {"scale": 1.5}`, and `ui.state` reports
  `textScale`.
- **The engine does not save it.** The game keeps the option (`storage`) and sets it at start; every test file starts at 1,
  and `project.test` restores the game's value afterwards.
- **Widgets that fit their label.** A `Button`, `Toggle` or `Slider` keeps its `size` unless it has `"autoSize": true`:
  then it is at least that size and grows to its label at the current text size and language (set it once in the scene;
  nothing to call when `ui.textScale` or the language changes). A `Button` label may have `
` (every line is centred),
  `maxWidth` wraps it (the button grows taller instead of wider), and a label that still does not fit is clipped to the
  button. A column `Panel` with `fit` grows with its children; put a `ScrollList` with `"fill": true` in it and the list
  takes the height the other children leave, so the column never ends below the screen. A `fit` Panel that is larger
  than the screen logs one warning naming it, and `factoria validate` reports it for the design size. Check the result
  with `game.screenshot` at `ui.textScale = 3`. A panel can switch to another layout when it would not fit:
  `"layout": "column", "fallbackLayout": "row"` (a row of buttons with `"fallbackLayout": "column"` stacks them); a
  script reads `Panel.usingFallback`. After changing a text, `ui.layout()` applies the sizes at once, so read
  `Button.size` or `ui.rectOf(...)` right away instead of measuring labels and adding margins. Put
  `"uniformSize": true` on the Panel that holds `autoSize` widgets and they all take the size of the largest one.
  Widgets without `autoSize` keep their rectangles and a wrapped Text keeps its `maxWidth`: text at 3× may not fit a
  small button.
- Fonts are rasterized at the scaled size, so scaled text stays sharp.

### Text that fits: `autoShrink`, `maxTextScale`, `ui.overflowed`

A fixed place for a text (a card, a HUD row, a heading, a round touch button) may not have room for 200 % text or for a
longer translation. Three fields say what to do, with no script; layout, `autoSize`, `ui.measureText`, `ui.rectOf` and
the renderers all use the same size, so what a test measures is what is drawn:

- **`autoShrink`** (with `minFontSize`, default 10) on `Text`, `Button`, `Toggle`, `Slider` and `TouchButton`: when the
  laid-out text is wider or taller than its box at the current text size, the font is made smaller until it fits, never
  under `minFontSize` times the player's text size (the floor grows with the option, so the accessibility setting still
  works). The box of a `Text` is `maxWidth` x `maxHeight` (set `maxHeight` to one line to keep a card title on one line;
  0 = that axis is not checked); of a widget label, the room the widget leaves it (a button's rectangle minus its
  margins, the right of a toggle's box, the left 35 % of a slider, a touch button's disc). `autoSize` makes room for the
  full-size label instead, so use `autoShrink` on widgets that keep their size.
- **`maxTextScale`** on `Text`, `Button`, `Toggle`, `Slider`, `TextField` and `TouchButton`: `ui.textScale` stops growing
  that text at this scale (`1.3` = at most 30 % bigger), for a heading or a round button label. It only limits growth:
  at 0.8 the text is drawn at 0.8. `0` (default) = no cap. `autoSize` and layout measure the capped size.
- **`Toggle.maxWidth`, `Slider.maxWidth`** wrap the label at that width like `Button.maxWidth` (an `autoSize` widget
  grows taller instead of wider), and **`Slider.labelAbove`** puts the label above the track on the full width, with the
  track, knob and value in a 28 px row under it.
- **`ui.overflowed(entityOrId)`** is `true` when a text still does not fit its box at the size it is drawn at (after
  the scale, the cap and the shrink did what they could). `ui.state` has `"overflowed": true` on those widgets and Texts.
  A test: `ui.textScale = 2; game.step(1); expect(ui.overflowed("play_button")).toBe(false);`
- **`ui.check_layout`** runs that test for you on every scene, language and text scale (and a pseudo-localized pass), and
  also lists overlapping and off-screen texts: see [LOCALIZATION.md](LOCALIZATION.md), section 7.

## Captions

Subtitles for sounds and hints. One `Captions` component (a UI widget: `anchor`, `pivot`, `safeArea`, `size`, `layer`)
draws the lines on the caption list, the newest `maxLines`, at the bottom of its rectangle on a background that hugs
them (`color`, `padding`). Text uses `font`, `fontSize`, `textColor` and, before it, the speaker's name in
`speakerColor`; it follows `ui.textScale`, the localization font chain and right-to-left languages like `Text`.

- `audio.play(path, { caption, captionKey, speaker, captionSeconds })`: the line shows while that sound plays and goes
  when it ends or is stopped (`audio.stop`, `audio.stopAll`). `caption` is plain text, `captionKey` a localization key (the
  line changes language while it shows; `caption` is its fallback). A looping sound needs `captionSeconds`.
- `ui.caption(text, seconds, { key, speaker })` and `ui.clearCaptions()`: lines without a sound, timed by the engine
  clock. Same as the `ui.caption` and `ui.clear_captions` commands.
- With no `Captions` entity the lines are still tracked (`game.captions()` in tests lists them) but not drawn, and the
  log says so once. An inactive `Captions` entity draws nothing: switch it off for a "Subtitles" option
  (docs/MENUS.md, "Captions").

## Limits

- Outline fonts only: no colour emoji, no bitmap-only fonts, no SDF/MSDF atlases; a variable font draws its default
  instance.
- Horizontal text only: no vertical writing (tategaki) and no text on a path.
- One font size, color and font per Text: no inline styles, bold or italic (use a bold or italic font file).
- The glyph size is capped between 4 and 400 pixels.
