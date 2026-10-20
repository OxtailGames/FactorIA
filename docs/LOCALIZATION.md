# Localization: one game, several languages

A localized game keeps its text in string tables, one file per language, and shows the table of the player's language.
Text and widgets name their string with a `key`; scripts ask for the rest with `i18n.t(key, args)`. A game that does not
declare languages is not localized: nothing here changes how it works.

FactorIA's own tests run the menu kit of [MENUS.md](MENUS.md) in English and Spanish (`tests/i18n.test.js` there switches
the language at run time and checks every Text and widget).

## 1. Declare the languages

`factoria.json`:

```json
"localization": {
  "defaultLanguage": "en",
  "languages": ["en", "es", "pt-BR", "zh-Hans"],
  "fallbackFonts": ["assets/fonts/NotoSans-Regular.ttf"],
  "languageFonts": { "zh-Hans": ["assets/fonts/NotoSansSC-Regular.ttf"] }
}
```

- `languages`: BCP 47 tags written the canonical way (`en`, `pt-BR`, `zh-Hans`: language in lower case, script
  capitalized, region in upper case). Each one needs `locales/<tag>.json`. One language is allowed.
- `defaultLanguage`: one of `languages` (default: the first). It is the language of the text written in scenes, and the
  last place a missing string is looked for.
- `fallbackFonts`, `languageFonts`: project-relative `.ttf` / `.otf` files for glyphs the Text's font lacks (CJK, Arabic,
  ...). `languageFonts[tag]` (the tag must be in `languages`) is tried before `fallbackFonts` when the game runs in that
  language. The engine gives the renderer the list of the current language when the game starts and at every switch
  (section 6; the font chain itself is in [TEXT.md](TEXT.md)).

A mistake is an error with the JSON pointer and the fix (`factoria validate` lists all of them; "did you mean" for a
tag written `pt_br` or a default language that is not in the list). No `"localization"` section = localization off.
Changing the section needs a restart; editing `locales/*.json` does not (hot reload).

## 2. String tables

`locales/<tag>.json`, UTF-8, read through `fa::fs` (so it works packed in an exported game):

```json
{
  "$name": "Español",
  "menu": { "play": "Jugar", "options": "Opciones" },
  "greeting": "¡Hola, {name}!",
  "coins": { "one": "{count} moneda", "other": "{count} monedas" }
}
```

- Nested objects are dotted keys: `menu.play`. Values are strings; any other value is an error that names the file and
  the JSON pointer.
- Keys that start with `$` are metadata. `$name` is the language's own name (`i18n.name(tag)`, for a language menu).
- A **plural entry** is an object whose keys are all of `zero`, `one`, `two`, `few`, `many`, `other` and that has
  `other`. `t("coins", { count: 1 })` picks the form of `count` with the CLDR rules of the table's language (written for
  en, es, pt, fr, de, it, nl, ru, uk, pl, cs, ar, he, ja, zh, ko, tr; others follow English; vi, th, id, ms have one
  form). A number with decimals counts as having them. Without a numeric `count` the `other` form is used and a
  warning says so. An ordinary group whose keys happen to be category names needs a different key name.
- `{name}` is replaced by `args.name` (strings as they are, numbers without a trailing `.0`, `null` as empty). `{{` and
  `}}` are literal braces. A placeholder without an argument stays as written and the log says which.

**Lookup.** The current language's table, then its base language's (`pt` for `pt-BR`, when the game has it), then
`defaultLanguage`'s. A key that no table has makes `t()` return the key itself and warn once in the log (category
`i18n`): the screen shows where a string is missing. A language whose file is missing or broken starts with a warning and
answers from the fallbacks. The command `i18n.state` (`fa.call("i18n.state")`, `factoria call i18n.state`) lists, per
language, the keys of the default table it lacks.

## 3. Which language the game starts in

1. `EngineConfig::language` (for programs that embed the engine) or the environment variable `FA_LANGUAGE` (e.g.
   `FA_LANGUAGE=es factoria run`). The config wins. A value that is not one of the game's languages is ignored, with a
   reason in the log and in `engine.info` `startupProblems`.
2. A **headless** run (`factoria run --headless`, `factoria test`, the MCP server) starts in `defaultLanguage`, so that
   results do not depend on the machine. Every test file starts there again.
3. A game with its **own window** (`factoria run` without `--headless`, an exported player) starts in the best match of the player's system
   languages (Windows: `GetUserPreferredUILanguages`; macOS and iOS: `NSLocale`; Android: `Locale.getDefault()`; Linux:
   `LANGUAGE`, `LC_ALL`, `LC_MESSAGES`, `LANG`), else `defaultLanguage`. Matching goes through the system languages in
   order: the same tag, then the same language and script (`zh-CN` is `zh-Hans`, `zh-TW` is `zh-Hant`), then the base
   language, then another variant of it that does not clash (`pt-PT` gets `pt-BR`).
4. The **editor** always runs in `defaultLanguage` and ignores `FA_LANGUAGE`: the scenes it saves hold that language's text.

The language is not saved between runs. A game that lets the player choose keeps the choice with `storage` and calls
`i18n.setLanguage` at start (`scripts/settings.js` in [MENUS.md](MENUS.md) does).

## 4. Text and widgets: the `key` field

`Text`, `Button`, `Toggle`, `Slider` and `TextField` have `key`. With a key, the engine writes the translation into
`Text.text`, `Button.text`, `Toggle.label`, `Slider.label` or `TextField.placeholder`:

```json
{ "id": "play", "components": { "Button": { "text": "Play", "key": "menu.play" } } }
```

- It runs when a scene loads, when a script spawns an entity, at the end of every frame, and at once when the
  language changes. It writes only when the string differs.
- **The field is overwritten while `key` is set**: a script that assigns `text` sees it replaced in the same frame.
  For text a script builds (`Score: 12`), leave `key` empty and write `i18n.t("hud.score", { score })` yourself, again on
  `i18n.on("change", ...)`.
- A key that no table has keeps the component's own text (write the default language's text there) and warns once. A
  game without a `"localization"` section does the same for every key.
- Saving a scene of a running game in another language would save the translations: edit and save scenes in the
  default language.

### Store catalog texts

The achievements and products of `factoria.json` `"platform"` (docs/PLATFORM.md) take their texts from the same tables:
`nameKey`, `descriptionKey` (achievements) and `titleKey`, `descriptionKey` (products) name a key instead of writing the
text, and `platform.achievements.list()` and `platform.purchases.products()` answer in the current language. The stores'
own screens are translated in each store's console (see PLATFORM.md, "Translated texts").

## 5. Scripts: the `i18n` object

```js
import { i18n, storage } from "factoria";

i18n.t("menu.play");                    // "Jugar"
i18n.t("greeting", { name: "Ana" });    // "¡Hola, Ana!"
i18n.t("coins", { count: 3 });          // "3 monedas"
i18n.has("menu.play");                  // true: a real string, not the key returned for a missing one
i18n.language; i18n.languages;          // "es"; ["en", "es", "pt-BR", "zh-Hans"]
i18n.defaultLanguage; i18n.systemLanguages;   // "en"; the player's languages (empty without a window)
i18n.name("es");                        // "Español"
i18n.setLanguage("es");                 // everything with a key changes now
const off = i18n.on("change", ({ language, previous }) => { /* write your own texts again */ });
```

- `setLanguage` accepts the tag as in `factoria.json` or close to it (`"pt_br"`, `"es-MX"` -> `"es"`); an unknown language
  throws with a "did you mean" and the game's languages. It is also the `i18n.set_language` command.
- `on("change", fn)` runs after every switch, with the frame; the returned function stops listening and listeners end
  with the scene, like `ui.on`: register in `onStart`. The game event `"i18n.change"` carries the same data.
- `t` never throws for a missing key. `t(5)` or `t("x", 3)` throws (a key is a string, `args` an object).
- Save the player's choice: `storage.set("language", i18n.language)` when it changes, and at start
  `i18n.setLanguage(storage.get("language", i18n.language))`.
- A script that starts when a panel first opens (an inactive entity's script) reads the language of that moment.

## 6. Fonts, right-to-left languages and text size

[TEXT.md](TEXT.md) describes how text is drawn; what a localized game has to do about it:

- **Fonts per language.** DejaVu Sans, the built-in font, has Latin, Greek, Cyrillic, Hebrew and Arabic letters; nothing
  else is built in. For Japanese, Korean, Chinese, Thai or an Indic script, ship a `.ttf` (Noto Sans has one per script)
  and list it in `factoria.json`: `languageFonts` for a font only that language needs, `fallbackFonts` for one every
  language needs (for example the font that draws the `$name` of every language in a language menu). A font is only
  read when some text needs it, and the list follows `i18n.setLanguage` at once, for the text already on screen too.
  `factoria validate` fails when a table string has a character no font of its chain has (section 7).
- **Right-to-left text.** Arabic and Hebrew are ordered with the Unicode bidirectional algorithm and joined by the
  shaper, with nothing to configure. `align` does not follow the text direction (`"left"` is always the left edge):
  give an Arabic or Hebrew label `align: "right"` and a pivot or anchor on the right. A menu laid out for English
  does not mirror itself; check it with `game.screenshot` after `FA_LANGUAGE=ar factoria run`.
- **Text size.** `ui.textScale` (0.5 to 3) makes every text bigger for players who ask: translations are longer than
  English, so give buttons, toggles and sliders `"autoSize": true`: they stay at their design size and grow to their
  label at the current language and text size (docs/TEXT.md, "Text size").

## 7. Checks: `factoria validate`

`factoria validate` (and `project.validate`) reads the section, every table, every `key` of every scene and prefab, and
the fonts. A line names the file, the JSON pointer inside it, what is wrong and how to fix it, with "did you mean" for
a key that is one letter off. Errors fail the validation; warnings do not.

| Finding | Level |
|---|---|
| A mistake in the `localization` section (a bad tag, a default language that is not in `languages`, a font for a language the game lacks) | error |
| `locales/<tag>.json` missing, not JSON, or a value that is not a string (file and pointer) | error |
| The default language has keys another language lacks: one line per language with the count and the first names | warning |
| A key a table has and the default table lacks (a typo or a removed string), with the closest key | warning |
| `{placeholders}` that differ from the default language's text, a key that is plain text in one table and plural in the other | warning |
| A plural entry without a form the language uses (`few` and `many` in Russian: the line says which counts show `other` instead), or with a form no count picks (`zero` in Japanese) | warning |
| A `key` of a Text or widget that the default table lacks (the game would show the scene's text and log a warning) | error |
| A `nameKey`, `descriptionKey` or `titleKey` of the platform catalog that the default table lacks (file `factoria.json`, pointer, closest key) | error |
| A `key` of a plural entry or of a text with `{placeholders}`: a component has no count or arguments | warning |
| `factoria.json` without a section but with `key` fields in scenes, or a `locales/` folder | warning |
| A character that no font of the chain has a glyph for | error |
| A font in `fallbackFonts`, `languageFonts` or a Text's `font` that is missing or is not a font file | error |

**Glyph check.** For every string, `factoria validate` asks the fonts the game would use, with `fa::FontCoverage`, and
does not need a window or a GPU. The chain it tries:

- A table string: the `font` of each Text or widget that shows its `key` (the built-in font when none does), then
  `languageFonts[language]` and `fallbackFonts` of the language of the table.
- A text written in a scene or prefab (no `key`): the component's `font`, then the fonts of the default language; in a
  game without a `localization` section, the component's `font` alone.
- The `$name` of a language, which a language menu draws whatever language the game runs in: an error when the
  language itself cannot draw it, a warning when only some other language of the game cannot.

The error names the first characters (`U+65E5 '日'`), the text, the file, the pointer or the table key, the fonts that were
tried, and the fix: change the text, or list a font that has them in `localization.languageFonts."<tag>"` or
`localization.fallbackFonts`, with the Noto Sans font for the script to download (SIL Open Font License). A font that
cannot be read is reported once, at the place that names it, and the strings that depend on it are not blamed. A file
with more than 25 such texts lists 25 and sums up the rest with every missing character.

An AI that adds a language: add the tag to `languages`, create `locales/<tag>.json` with the same keys (or export the
spreadsheet below), list a font if the script needs one, and run `factoria validate` until it is clean.

## 8. Translators: spreadsheet and XLIFF

A translator needs neither the repository nor JSON. `i18n.export` writes what they read, `i18n.import` puts what they
send back into `locales/`.

```
factoria call i18n.export '{"format": "csv"}'                      # build/translations/translations.csv
factoria call i18n.export '{"format": "xliff", "languages": ["ja"]}'  # build/translations/translations.ja.xlf
factoria call i18n.import '{"file": "build/translations/translations.csv", "dryRun": true}'
factoria call i18n.import '{"file": "build/translations/translations.csv"}'
```

**Rows.** One row per string, with the default language's text next to the text to translate. A nested key is written
dotted (`menu.play`), a plural entry is **one row per form**, the category after a `#`: `coins#one`, `coins#other`
(Russian gets `few` and `many` too; the forms a language needs are the CLDR categories of section 2). The row `$name`
is the language's own name. A placeholder (`{name}`, `{count}`) must stay in the translation exactly as in the source;
XLIFF files carry a note that says so.

**CSV** (`format: "csv"`, one file for every language): UTF-8 with a byte order mark, so Excel opens it with the accents
right; columns `key`, the default language, then one column per language to translate; fields with a comma, a quote or a
line break are quoted as in RFC 4180.

- Excel: open the file (Data > From Text/CSV, UTF-8), and **save as "CSV UTF-8"**, not plain "CSV", which uses the
  Windows code page and breaks the accents. If Excel is set to a language that writes decimals with a comma (Spanish,
  German, French...), it splits columns on `;`: export with `"delimiter": ";"`. Import reads commas, semicolons and tabs
  and finds out which one the file uses.
- LibreOffice Calc: open the file and choose UTF-8 and the separator in the import dialog; save as CSV with the same options.
- Google Sheets: File > Import > Upload, "Detect automatically"; File > Download > CSV.

**XLIFF 1.2** (`format: "xliff"`, one `translations.<tag>.xlf` per language): `source` is the default language's text,
`target` the translation (empty, `state="needs-translation"`, when there is none), and `id` and `resname` are the key.
Poedit, OmegaT and memoQ open XLIFF 1.2 files; any tool that reads the format works. Export once per language you send
to a different translator.

**Import.** `i18n.import {file, languages?, dryRun?}` takes a `.csv` or `.xlf` and updates `locales/<tag>.json` of every
language in the file (or only `languages`):

- Existing keys change in place: nested groups stay nested, flat `"menu.play"` keys stay flat, the order of the file is
  kept, the file is written with 2-space indentation. A key the table lacks is added (nested by its dots when the
  file is nested). A plural entry the table lacks needs its `other` row.
- **An empty cell never deletes a translation**; it is counted as `skippedEmpty`.
- The default language's own column is the source and is skipped. A column that is not a language of the game is an error
  with "did you mean" (`esp` -> `es`); nothing is written then, for any language.
- A warning (the row is reported and skipped, except placeholders, which are imported with the warning): a key the
  default language lacks (with the closest key), a `{placeholder}` that differs from the default text, a plural row on a
  plain string or the other way round.
- The result is `{file, format, dryRun, languages: {<tag>: {file, updated, added, unchanged, skippedEmpty, written,
  warnings}}}`. With `dryRun` nothing is written. A table is never written if the result would not load.

After an import, run `factoria validate`: it lists what is still missing, and the glyphs the new texts need.

## 9. Commands

- `i18n.state` (read-only): `{enabled, default, current, languages: [{code, name, file, loaded, keys, missing,
  missingKeys}], systemLanguages}`. `missing` counts the default table's keys that the language lacks; `missingKeys`
  lists up to 20.
- `i18n.set_language {"language": "es"}`: switches now; returns `{language, previous, changed}`. The choice is not saved.
- `i18n.export {format?, languages?, out?, delimiter?}` and `i18n.import {file, languages?, dryRun?}`: the files
  translators exchange (section 8). Both write files, `i18n.export` only under `out` (default `build/translations/`,
  never in `locales/`).

All are MCP tools and `factoria call` commands (`factoria call i18n.state`).
