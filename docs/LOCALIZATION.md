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
  language. They are read and validated here; how text is shaped and how glyphs fall back is described with the fonts.

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
answers from the fallbacks. `i18n.state` lists, per language, the keys of the default table it lacks.

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

## 6. Commands

- `i18n.state` (read-only): `{enabled, default, current, languages: [{code, name, file, loaded, keys, missing,
  missingKeys}], systemLanguages}`. `missing` counts the default table's keys that the language lacks; `missingKeys`
  lists up to 20.
- `i18n.set_language {"language": "es"}`: switches now; returns `{language, previous, changed}`. The choice is not saved.

Both are MCP tools and `factoria call` commands (`factoria call i18n.state`).
