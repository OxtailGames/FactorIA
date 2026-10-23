// Localization: string tables, plural forms, {placeholders} and language matching. Pure logic over fa::fs and fa::Json;
// the pass that writes translations into Text and widgets is fa/scene/localize.h, run by fa_runtime (docs/LOCALIZATION.md).
//
// A string table is locales/<language>.json: an object whose nested objects flatten to dotted keys.
//   { "$name": "Español", "menu": { "play": "Jugar" }, "items": { "one": "{count} objeto", "other": "{count} objetos" } }
//   -> menu.play, items (a plural entry: an object whose keys are all CLDR categories and that has "other").
// Keys starting with `$` are metadata and never strings of the game; "$name" is the language's own name.
#pragma once

#include <cstdint>
#include <map>
#include <optional>
#include <set>
#include <string>
#include <string_view>
#include <vector>

#include "fa/core/json.h"
#include "fa/core/log.h"
#include "fa/core/types.h"

namespace fa {

// ---- Language tags (BCP 47: "en", "pt-BR", "zh-Hans") ------------------------------------------------------------------
// "es_ES.UTF-8" -> "es-ES", "ZH-hant-tw" -> "zh-Hant-TW". Keeps language[-Script][-REGION] (variants and extensions are
// dropped). "" for text that is no tag: empty, "C", "POSIX".
std::string normalize_language_tag(std::string_view raw);
// True when `tag` is written the canonical way (what normalize_language_tag returns): "pt-BR", not "pt-br" or "pt_BR".
bool is_language_tag(std::string_view tag);
// True for a language written right to left (Arabic, Hebrew, Persian, Urdu, Pashto, Sindhi, Uyghur, Yiddish, Dhivehi, Kurdish
// Sorani), by its base language or its script (a "-Arab" or "-Hebr" tag).
bool is_rtl_language(std::string_view tag);
// "pt-BR" -> "pt" ("zh-Hans-CN" -> "zh-Hans" -> "zh"); "" for a tag without a region or script.
std::string base_language(std::string_view tag);
// The language of the project that suits the user's languages (system order, best first), or "" when none does:
// exact tag, then language + script (zh-CN and zh-SG are zh-Hans, zh-TW, zh-HK and zh-MO zh-Hant), then the base
// language, then another variant of the same base language whose script does not clash ("pt" for a project with "pt-BR").
std::string best_language_match(const std::vector<std::string>& systemLanguages, const std::vector<std::string>& projectLanguages);

// ---- Plural forms (CLDR cardinal rules) --------------------------------------------------------------------------------
enum class PluralCategory : std::uint8_t { Zero, One, Two, Few, Many, Other };
const char* plural_category_name(PluralCategory category);                    // "zero" .. "other"
bool parse_plural_category(std::string_view name, PluralCategory& out);       // exact lower-case names
// The form `count` takes in `language` (a tag: only the language and, for Portuguese, the region matter). Written for en, es,
// pt, fr, de, it, nl, ru, uk, pl, cs, ar, he, ja, zh, ko, tr; ca, sv, nb, da, fi, sk and the other languages without a
// rule of their own follow the English one (one / other), vi, th, id, ms have a single form. A number with decimals is
// treated as having visible decimals (CLDR's v > 0); the rules that ignore decimals (fr, pt) still apply.
PluralCategory plural_category(std::string_view language, double count);
// The forms a plural entry in `language` needs: the categories plural_category() gives whole counts, in the order zero ..
// other (always with Other). With `everyCount` also the forms only a fraction (cs: "many") or a round million (es, fr, it,
// pt: "many") picks; a table may leave those out (the entry then falls back to "other"), but they are not a mistake.
// `factoria validate` compares a table's plural entries with it.
std::vector<PluralCategory> plural_categories(std::string_view language, bool everyCount = false);

// ---- String tables ------------------------------------------------------------------------------------------------------
struct StringEntry {
    std::string text;                                  // a plain string
    std::map<PluralCategory, std::string> forms;       // a plural entry (non-empty): one text per category, always has Other
    std::string pointer;                               // where the entry is in the file: "/menu/play" ("/coins" for a plural entry)
    bool plural() const { return !forms.empty(); }
};

struct StringTable {
    std::string language;  // "es"
    std::string file;      // "locales/es.json": where it was read, for messages
    std::string name;      // "$name": the language's own name ("Español"), "" when the file has none
    std::map<std::string, StringEntry> entries;  // flattened keys, sorted
};

// Flattens a parsed table. Errors name the file and the JSON pointer: not an object, a value that is no string, an object
// of plural categories without "other", two spellings of one key ("a.b" and {"a": {"b"}}).
Result<StringTable> parse_string_table(const Json& document, std::string_view language, std::string_view file);

// Replaces {name} with args.name (strings as they are, numbers without a trailing ".0", booleans, null as ""); "{{" and "}}"
// are literal braces. A placeholder with no argument stays as written and its name is appended to *missing.
// `{v:number}` / `{v:number:1}` write a number with the separators and digits of `language` (fa/core/number_format.h; "" =
// English), with that many decimals (0-9) or as many as the number has; `{t:duration}` / `{t:duration:0}` write seconds
// as "1:23.4". A bad format, a bad decimals count or a value that is no number shows the value as it is and appends the
// reason to *problems.
std::string format_message(std::string_view text, const Json& args, std::vector<std::string>* missing = nullptr,
                           std::string_view language = {}, std::vector<std::string>* problems = nullptr);

// ---- The localization of a running game ----------------------------------------------------------------------------------
class I18n {
public:
    // One thing wrong with a table file at load: a missing file is a warning, a file that does not parse is an error.
    struct Problem {
        LogLevel level = LogLevel::Warn;
        std::string text;
    };

    // The languages of the game (BCP 47 tags, `defaultLanguage` among them) and the language it starts in (default:
    // `defaultLanguage`). Drops every table and every warning already given. No languages = localization off.
    void configure(std::string defaultLanguage, std::vector<std::string> languages);
    bool enabled() const { return !languages_.empty(); }

    // Reads locales/<language>.json (through fa::fs, so a packed game works) of every language. A table that fails is left
    // out; the game keeps running through the fallback chain. Calling it again re-reads everything (hot reload).
    std::vector<Problem> load_tables();
    // Adds or replaces a table (tests, tools). The language must be one of configure()'s.
    Result<void> add_table(StringTable table);

    const std::vector<std::string>& languages() const { return languages_; }
    const std::string& default_language() const { return default_; }
    const std::string& language() const { return current_; }
    // The current language is written right to left (is_rtl_language); false when localization is off.
    bool rtl() const { return enabled() && is_rtl_language(current_); }

    // `requested` as one of the game's languages: the same tag in any case or spelling ("pt_br"), else the best match
    // ("es-MX" -> "es", "zh-CN" -> "zh-Hans"). The error says what is available, with "did you mean".
    Result<std::string> resolve_language(std::string_view requested) const;
    // Switches the language (through resolve_language); returns the language now in use.
    Result<std::string> set_language(std::string_view requested);

    // The text of `key` in the current language, else its base language, else the default language; with {placeholders}
    // from `args` (an object) and, for a plural entry, the form for args.count in the language of the table it came from.
    // nullopt when no table has the key.
    std::optional<std::string> translate(std::string_view key, const Json& args = nullptr) const;
    // translate(), or the key itself (warning once per key) when no table has it.
    std::string t(std::string_view key, const Json& args = nullptr) const;
    // A number / a time in the current language (format_number / format_duration; English when localization is off).
    // decimals < 0: as many as the number has. For duration, decimals < 0 means 1.
    std::string number(double value, int decimals = -1) const;
    std::string duration(double seconds, int decimals = 1) const;
    bool has(std::string_view key) const;  // some table of the fallback chain has the key
    // The language's own name (`$name`), else the tag.
    std::string name(std::string_view language) const;

    const StringTable* table(std::string_view language) const;  // nullptr when not loaded
    // Keys of the default language's table that `language`'s own table lacks (the fallback chain does not count).
    std::vector<std::string> missing_keys(std::string_view language) const;

    // Logs `message` as a warning the first time `id` is seen (cleared by configure()).
    void warn_once(const std::string& id, const std::string& message) const;

private:
    void rebuild_chain();

    std::string default_, current_;
    std::vector<std::string> languages_;
    std::map<std::string, StringTable> tables_;
    std::vector<const StringTable*> chain_;  // the tables to look in for the current language, best first
    mutable std::set<std::string> warned_;
};

}  // namespace fa
