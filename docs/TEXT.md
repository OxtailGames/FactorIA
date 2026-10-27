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
10 MB): the player downloads what you ship, so cut the font to the characters the game uses with `assets.subset_font`
(`factoria call assets.subset_font '{"source":"NotoSansJP[wght].ttf","out":"assets/fonts/NotoSansJP-Regular-subset.ttf"}'`; no
Python needed). It keeps the characters of `locales/<language>.json` for the `locales` you name (default: every language of
`localization.languages`) plus ASCII, Latin-1, the full-width forms, the CJK punctuation line breaking needs and the
characters of `keep`, and it keeps the shaping tables (GSUB, GPOS, kerning). A variable font (`NotoSansJP[wght].ttf`) draws its
default weight, which for Noto is Thin: the command pins it to one instance (`wght` 400, or `axes` such as `{"wght": 700}`),
so the result is a static font. Run it again when a string changes; `factoria validate` then confirms every string has a glyph.

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
marks and variation selectors never count, the Thai SARA AM (U+0E33) and Lao AM (U+0EB3) count as the two parts the shaper
always draws them with (U+0E4D U+0E32, U+0ECD U+0EB2) whether or not the font has the composed character, so a font without
U+0E4D is reported, and a font that is missing or cannot be parsed is an error, not "missing
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

With `maxWidth` > 0 a line breaks after spaces (U+0020, the en/em/thin spaces U+2000-U+2006 and U+2008-U+200A, U+1680,
U+205F), after U+200B ZERO WIDTH SPACE (no width, never drawn), after a hyphen (`-` or U+2010, but not before a digit:
`-5` stays whole), and between two Japanese or Chinese characters (ideographs and kana), so text written without
spaces wraps. Hangul is not one of them: Korean is written with spaces between words and a line ends at one of them, never
inside a word (see `wordBreak` below). A simple kinsoku rule keeps closing punctuation (`。、」）！？`,
the prolonged sound mark `ー`, small kana, `…`) off the start of a line and opening brackets (`「（`) off the end. A space at
a break (U+200B included) is not drawn, and a wrapped line starts with no spaces. `\n` always starts a new line, and a tab is four spaces.
A word (or an unbreakable run) wider than `maxWidth` stays on its own line and sticks out.

The no-break spaces (U+00A0, U+2007, U+202F) never break. This is not the full Unicode line breaking algorithm (UAX #14):
numbers with units get no break rules. Thai, Khmer, Lao and Burmese are written without spaces and finding their word
boundaries needs a dictionary, which the engine does not have: unmarked text of those scripts does not break inside a run.
Translators mark the boundaries where a line may end with U+200B (a tool such as pythainlp can insert them): the line breaks
there, and the mark takes no width and draws nothing.

### `Text.wordBreak`: Korean keeps its words

Where a line may end inside a run of letters with no space:

| `wordBreak` | Hangul | Chinese, Japanese (ideographs, kana) |
|---|---|---|
| `auto` (default) | at spaces only | between any two characters |
| `normal` | between syllables too | between any two characters |
| `keepAll` | at spaces only | at spaces only |

`auto` is what Korean text needs: no setting, no check of the language. Use `keepAll` for Chinese or Japanese written with
spaces between words (a romanised or mixed line) where a break inside a word reads badly; a run longer than `maxWidth`
then overflows the box, as any unbreakable word does. `normal` is for a column so narrow that a Korean word wider than it
must be cut. Layout, `ui.rectOf` and autoShrink measure with the Text's `wordBreak`; `ui.measureText` has no such option and
measures with `auto`.

## Typewriter reveal: `Text.visibleCharacters`

`visibleCharacters` -1 (default) draws the whole text. `n >= 0` draws only its first `n` characters and nothing else
changes: the text is laid out as a whole (its wrapping, alignment, `autoShrink`, size, `ui.rectOf`, a Panel's fit) and then
clipped, so a dialogue box keeps the size of the full line while the line appears, and no word jumps to the next line
halfway. Set it from a script, a few characters per frame or second:

```js
const label = world.find("dlg_text").get("Text");
label.visibleCharacters = 0;
// each frame: label.visibleCharacters = Math.floor(elapsed * 45);
```

- It counts grapheme clusters, what a reader calls a character: a letter with its accents (`e` + U+0301), a Hangul syllable
  or conjoining jamo sequence, an emoji sequence (a family, a skin tone, a flag) and CR LF are one. Spaces and `\n` count; the
  tags of `markup` do not (they are not characters) and an `[icon:name]` picture is one.
- The order is the order of the text. A right-to-left line therefore appears from its right end, and a line that mixes
  directions appears in reading order.
- A ligature or a letter shaped together with the next one (Arabic joining) appears with its first character.
- Above the length of the text it draws everything; the glyph count of `RenderStats.textGlyphs` is that of the glyphs
  drawn.
- It applies to `Text` only. Widget labels (Button, Toggle, Slider) are not revealed.
- A script that wants the total can count `[...text].length` (code points; grapheme clusters are never more, so
  reaching it means everything shows).

## Rich text: bold, colours and icons

A `Text` with `markup: true` reads tags in its `text`, and so does the label of a `Button`, `Toggle`, `Slider` or
`TouchButton` that sets `markup: true`. One Text can then hold several colours, bold words and pictures, and it is still
one wrapped, aligned, measured text (`maxWidth`, `align`, `autoShrink` and `maxTextScale` work on the whole line, and
`ui.measureText` and `entity.bounds()` measure what is drawn).

| Tag | Effect |
|---|---|
| `[b]...[/b]` | bold |
| `[c:name]...[/c]` | a colour: a name of the project's `text.colors`, a built-in colour name (`red`) or `#rgb` / `#rrggbb` / `#rrggbbaa`. Tags nest: `[/c]` goes back to the outer colour. |
| `[icon:name]` | a picture of the project's `text.icons`, as tall as the line (its width follows the proportions of its region) |
| `[[` | a literal `[` |

```json
"text": {
  "colors": { "good": "#80dc80", "bad": [1, 0.48, 0.42, 1] },
  "icons":  { "fish": { "texture": "assets/atlas.png", "region": [0, 32, 24, 24] } },
  "fonts":  { "assets/fonts/Body-Regular.ttf": { "bold": "assets/fonts/Body-Bold.ttf" } }
}
```

```json
{ "Text": { "text": "Sold [b]3[/b] [icon:fish] for [c:good]120[/c]", "markup": true, "fontSize": 20, "maxWidth": 260 } }
```

- **Colours.** A run colour replaces the red, green and blue of the Text's `color`; the Text's alpha still applies, so
  fading a Text fades its runs. An icon is drawn untinted (only the Text's alpha applies). `region` is `[x, y, w, h]` in
  pixels of the texture, from its top-left corner.
- **Bold.** `[b]` and `Text.bold` (also a field of the widgets above) draw with the bold face of the font: the `bold`
  file next to the font in `text.fonts`. The key is the font as the Text names it (`"font": "assets/fonts/Body-Regular.ttf"`,
  `"builtin:pixel"`, or `""` for the built-in font). A font without a bold face is emboldened by the engine: it thickens the
  regular glyphs and widens each advance a little (about 4% of the font size, between 0.7 and 6 pixels). That is readable but
  never as good as a drawn bold face, so `factoria validate` warns once per font that markup or `bold` uses without a
  `text.fonts` entry. A glyph the bold face lacks (a CJK character, say) is drawn from the regular font chain, emboldened by
  the engine. There is no italic: use an italic font file as the Text's `font`.
- **Line breaking.** Tags take no room. Wrapping, including between CJK characters, works on the visible characters as for
  plain text; an icon is one unbreakable character that stays with the letters next to it (`9[icon:fish]` moves as one
  word) and may break from a space.
- **Mistakes never hide the sentence.** An unknown tag (`[x]`), a `[` without `]`, a colour or icon the project does not
  define, and a `[b]` or `[c:]` never closed are shown as written (an undefined icon is an empty square, an undefined
  colour keeps the Text's colour), with one warning in the log per text that says where and how to fix it. A stray `[/b]`
  or `[/c]` is dropped. `ui.markupProblems(text)` returns the same problems as a list (empty = clean), so a test can walk
  every string of the game. `factoria validate` checks the markup of every scene text that has `markup: true`, and that the files `text` names exist.
- **What it costs.** All the glyphs of a Text, whatever their colours and weights, are one batch and one draw call (they
  share the glyph atlas). Icons are pictures from a texture, which the glyph atlas cannot hold: each texture that a text
  draws icons from adds one more batch, however many icons it has.
- **Measuring.** `ui.measureText(text, { markup: true, bold: true, ... })` measures with the same layout. Without a
  renderer (no graphics device), tags are still skipped and an icon counts as two characters (0.6 em each) of a line 1.2
  em tall.
- **Localized text.** The tags travel in the string table: translators keep them and move them around the words. Put
  `markup: true` on the Text that shows the key.

## Measuring

`ui.measureText(text, { fontSize, font, maxWidth, space, maxTextScale, autoShrink, minFontSize, maxHeight, markup, bold })` returns
`{ width, height, fontSize }` of exactly the layout that is drawn (`fontSize` is the size it is laid out at, in pixels), shaped and wrapped, with the fallback fonts. `space` is `"screen"` (the default: a HUD label, a widget label) or
`"world"`; it matters only for the text size option below. It is exact in tests, `factoria call` and headless runs
(they draw with an offscreen renderer); only when no graphics device can be created does it approximate 0.6 ×
`fontSize` per character and warn once. A wrapped text is as wide as its widest line (at most `maxWidth`, and less for a short label, with a renderer and headless alike) and as tall as its lines. A `Text` with `align` center or right still lays its lines out inside the `maxWidth` box (the pivot is that box's), while its measured size, `ui.rectOf` and `ui.overflowed` use the widest line; widget labels are aligned inside their widest line.

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
  track, knob and value in a 28 px row under it. A `Toggle`'s box is one line of its label high (`fontSize` at the
  player's text size, times 1.2, plus 4 px), centred, and never taller than the widget minus 12 px: a wrapped label or
  an `autoSize` toggle that grew taller does not make the box bigger. `Toggle.autoShrink` and `minFontSize` work like
  the Button's and fit the label into the room right of the box. A `Button` with an `icon` (`iconPosition` `left` or
  `top`) gives the icon its side of the button: `autoSize` adds the icon's size and a 6 px gap, and `autoShrink` fits the
  label into what is left. With `iconPosition: "alone"` there is no label and `autoSize` fits the icon.
- **`ui.overflowed(entityOrId)`** is `true` when a text still does not fit its box at the size it is drawn at (after
  the scale, the cap and the shrink did what they could). `ui.state` has `"overflowed": true` on those widgets and Texts.
  A test: `ui.textScale = 2; game.step(1); expect(ui.overflowed("play_button")).toBe(false);`
- **`ui.check_layout`** runs that test for you on every scene, language and text scale (and a pseudo-localized pass), and
  also lists overlapping and off-screen texts (`steps` opens a panel first; a `ScrollList` row is judged by its visible part): see [LOCALIZATION.md](LOCALIZATION.md), section 7.

## Interface size (`ui.scale`)

`ui.textScale` makes the text bigger and leaves the boxes alone. `ui.scale` (a number from 0.5 to 3, 1 = as authored)
makes the whole interface bigger or smaller, as a player with a small screen or poor eyesight asks for: it multiplies
the `size`, `position` offset, `padding`, `spacing`, margins and font size of every screen-space widget (`Panel`,
`Button`, `Toggle`, `Slider`, `TextField`, `ScrollList`, `TouchStick`, `TouchButton`, `Captions`) and of every
screen-space `Text`, `Sprite` and `Shape2D`. `ui.textScale` comes on top of it for text, so at `ui.scale` 1.5 and
`ui.textScale` 2 a font is drawn 3 times as big.

A screen is laid out in **UI units**: a virtual screen of the design size divided by `ui.scale` (1280 x 720 at 1.5 is
853 x 480 UI units), with the safe-area insets divided the same way, and drawn `ui.scale` times as big. So the sizes you
write in scenes stay design pixels at scale 1; and the anchor does not move: a widget anchored to a corner stays in that
corner, a centred panel stays centred, and the children of a `Panel` stay inside it.

```js
import { ui, storage, math } from "factoria";
ui.scale = math.clamp(storage.get("uiScale") ?? ui.scale, 0.5, 3);  // at start; ui.scale is the factoria.json default until then
// in the options menu:
ui.scale = 1.5;
storage.set("uiScale", ui.scale);
```

- **Project default.** `"ui": { "scale": 1.25 }` in `factoria.json` is the size a game starts with (and the value of
  `ui.scale` at the start of every test file). A reload of the project applies it only if the file changed, so it never
  undoes the player's choice. The engine does not save the player's choice: the game keeps it in `storage` and sets it at
  start, as for `ui.textScale`. Setting a number outside 0.5 to 3 throws. Over MCP or `factoria call` the command is
  `ui.set_scale {"scale": 1.5}`; `ui.state` reports `uiScale`.
- **Units.** `Panel.size`, `Button.size`, the results of `ui.layout()` and `ui.measureText` are in UI units. `ui.rectOf`,
  the rectangles of `ui.state` and of the `ui.check_layout` warnings, the hit test, `game.input` clicks and the screenshot
  are on the screen, in design pixels, so they already include the scale: at 1.5 a button of `size` 100 has a `rectOf`
  width of 150. `screen.size` and `screen.safeArea` are the screen's design size and safe area, never divided by the scale
  (a panel of `size` 760 x 680 fits when `760 * ui.scale <= screen.size.x` and `680 * ui.scale <= screen.size.y`).
- **Panel limits.** `Panel.minSize` and `Panel.maxSize` (UI units, 0 = no limit on that axis) bound the size of a
  `Panel` with `fit: true` too: a `fit` Panel never shrinks below `minSize` or grows above `maxSize` (a column `Panel`
  that is "as tall as its rows, at least 300 and at most the screen" is `"minSize": [0, 300]`). When the two cross,
  `minSize` wins. This is what keeps a window of a fixed look when the labels are short or the language changes.
- **Events.** `ui.on("scale", (e) => ...)` and `ui.on("textScale", (e) => ...)` run once per change to another value
  with `{ type, value, previous }`, like `i18n.on("change")`, with the game events of the next frame; use them to redo
  what depends on the size of the interface (a layout your script computes, an `ui.measureText`) instead of keeping a
  list of widgets to resize. They end with the scene. Setting the value it already has sends nothing.
- **Laying out for every size.** The screen shrinks (in UI units) as the scale grows: a 760 x 680 panel fits 1280 x 720 at
  1 and 0.75 but not at 1.25. Give a panel that must fit a `ScrollList` with `fill`, or a `fallbackLayout`, check each
  size you offer with `ui.check_layout {"uiScales": [1, 1.25, 1.5]}` (crossed with `languages` and `textScales`) and look
  at it with `game.screenshot`. The menu kit's Options "Interface size" button offers only the sizes at which its own
  panel still fits.
- **Limits.** Screen-space particle emitters (`ParticleEmitter` with `space: "screen"`) are not scaled. A 9-slice border
  is scaled with the widget, so a themed button's border grows with it. At a scale under 1 a widget that was
  authored as large as the screen no longer covers it (its size is multiplied by the scale), so draw a backdrop with the
  camera clear colour or make it larger than the screen. World-space entities, and `Text` with `space: "world"`, are never scaled.

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

## Typing text

A `TextField` takes the characters in `input.text`, Backspace (it repeats while held) and Enter (`ui.submit`). Where those
come from depends on the device, and the game does not change for any of them:

- **Desktop.** The operating system's text input: composed text (shift, dead keys, IME) arrives as typed.
- **Phones and tablets.** The `TextField` raises the system keyboard when it gets the focus and hides it when it loses it
  (the UI does this by itself: [MOBILE.md](MOBILE.md#the-on-screen-keyboard)). iOS delivers composed text; Android
  delivers what each key types in its layout.
- **A gamepad alone.** The kit's on-screen keyboard ([MENUS.md](MENUS.md), "On-screen keyboard (gamepad players)"): the
  d-pad walks the keys, its layout follows the language's script.
- **Web.** The page gets typed text from the browser's **`keypress`** events (`keydown` and `keyup` give the keys: Backspace,
  Enter, arrows), the way sokol_app reads them, so a character reaches the game only when the browser generates a
  `keypress` for it. A real keyboard does; a browser pane's or automation tool's synthetic events may send `keydown`
  only, and then letters do not appear (the key still works as a button). To test typing in a page, send events the
  browser treats as typed (Chrome DevTools `Input.dispatchKeyEvent` with `text`, as `platforms/web/smoke.mjs` does for the
  CI check), or use the page's own keyboard. On a touch device a hidden `<input>` takes the focus while a `TextField`
  has it, which is what makes a phone browser show its keyboard; what it receives (typed text, Backspace) goes to the same
  `input.text` and Backspace. Text that a keyboard composes (predictive words, swipe, IME) arrives when the composition
  ends.

## Limits

- Outline fonts only: no colour emoji, no bitmap-only fonts, no SDF/MSDF atlases; a variable font draws its default
  instance.
- Horizontal text only: no vertical writing (tategaki) and no text on a path.
- One font size and one font per Text. Colours, bold and icons can change inside a line (`markup`, above); the font size, the
  font and italic cannot (use an italic font file as the Text's `font`).
- The glyph size is capped between 4 and 400 pixels.
- All glyphs of all fonts share one atlas (an 8-bit page). It starts at 1024 x 1024 and grows to 2048 and then 4096 when a
  glyph does not fit; at 4096 it clears. Every growth or clear is a log line ("glyph atlas is full ... growing it" / "...
  clearing it"), and every `Text` lays out again on its next draw. A frame that meets one is gathered again, so no text
  of that frame is drawn blank or with the glyphs of another text. What stays in the atlas is every glyph of every size
  drawn since the last clear: a screen with many scripts at many sizes at once (more than a 4096 page holds, in the order
  of a thousand large glyphs) clears every frame, which is slow: use fewer sizes. `RenderStats` (`glyphAtlasSize`,
  `glyphAtlasResets`) shows the page.
