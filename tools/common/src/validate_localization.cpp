// project.validate: the string tables (locales/<language>.json), the `key`s of scenes and prefabs, and whether the fonts the game
// will use have a glyph for every character it shows. The "localization" section itself is checked by validate.cpp.
#include <algorithm>
#include <filesystem>
#include <map>
#include <optional>
#include <set>

#include "fa/core/fs.h"
#include "fa/core/i18n.h"
#include "fa/core/strings.h"
#include "fa/render/fonts.h"
#include "localization_check.h"
#include "localization_tables.h"
#include "util.h"

namespace fa::localization_detail {

namespace {

constexpr std::size_t kListed = 8;         // names in one message before "and N more"
constexpr std::size_t kExtraKeys = 10;     // stale keys of one table reported one by one
constexpr std::size_t kGlyphErrors = 25;   // texts with missing glyphs reported one by one per file

// The components that show text, and the field the text is in.
struct TextField {
    const char* component;
    const char* field;
};
constexpr TextField kTextFields[] = {
    {"Text", "text"}, {"Button", "text"}, {"Toggle", "label"}, {"Slider", "label"}, {"TextField", "placeholder"}};

std::string quote(const std::string& s) { return "'" + s + "'"; }

// "a, b, c and 3 more": the first `limit` items written by `describe`.
template <class T, class Describe>
std::string list_of(const std::vector<T>& items, std::size_t limit, Describe describe) {
    std::string out;
    for (std::size_t i = 0; i < items.size() && i < limit; ++i) out += (i ? ", " : "") + describe(items[i]);
    if (items.size() > limit) out += " and " + std::to_string(items.size() - limit) + " more";
    return out;
}

std::string list_names(const std::vector<std::string>& names, std::size_t limit = kListed) { return list_of(names, limit, quote); }

// "U+65E5 '日', U+672C '本' and 3 more"
std::string list_code_points(const std::vector<std::uint32_t>& cps, std::size_t limit = kListed) {
    return list_of(cps, limit, [](std::uint32_t cp) { return describe_code_point(cp); });
}

std::string font_name(const std::string& font) {
    if (font.empty()) return "DejaVu Sans (built-in)";
    if (font == "builtin:pixel") return "Press Start 2P (built-in)";
    return font;
}

// ---- fonts -------------------------------------------------------------------------------------------------------------------

// Each font file is read once. A chain misses a character when EVERY font of it lacks the character (DejaVu Sans included: it is
// the last font of every chain), which is the intersection of what each single font misses.
class Coverage {
public:
    // nullptr when the font cannot be used (see error()).
    const FontCoverage* get(const std::string& font) {
        auto it = loaded_.find(font);
        if (it == loaded_.end()) it = loaded_.emplace(font, FontCoverage::load({font})).first;
        return it->second.ok() ? &it->second.value() : nullptr;
    }
    const Error& error(const std::string& font) const { return loaded_.at(font).error(); }

    // Code points of `text` that no font of `chain` has. nullopt when a font of the chain cannot be used: that is reported
    // as a problem of the font, not as a flood of missing characters.
    std::optional<std::vector<std::uint32_t>> missing(const std::vector<std::string>& chain, std::string_view text) {
        std::vector<std::uint32_t> result;
        for (std::size_t i = 0; i < chain.size(); ++i) {
            const FontCoverage* coverage = get(chain[i]);
            if (!coverage) return std::nullopt;
            std::vector<std::uint32_t> lacks = coverage->missing(text);
            if (i == 0) {
                result = std::move(lacks);
            } else {
                std::erase_if(result, [&](std::uint32_t cp) { return std::find(lacks.begin(), lacks.end(), cp) == lacks.end(); });
            }
        }
        return result;
    }

private:
    std::map<std::string, Result<FontCoverage>> loaded_;
};

bool in_range(std::uint32_t cp, std::uint32_t lo, std::uint32_t hi) { return cp >= lo && cp <= hi; }

// The free font to suggest for these characters: Noto Sans (SIL Open Font License) has one family per script.
std::string suggest_font(const std::vector<std::uint32_t>& cps, const std::string& language) {
    const std::string base = to_lower(language.substr(0, language.find('-')));
    const bool traditional = language.find("Hant") != std::string::npos || language.find("-TW") != std::string::npos ||
                             language.find("-HK") != std::string::npos || language.find("-MO") != std::string::npos;
    bool han = false, kana = false, hangul = false, arabic = false, thai = false, devanagari = false, emoji = false, other = false;
    for (std::uint32_t cp : cps) {
        if (in_range(cp, 0x3040, 0x30FF) || in_range(cp, 0x31F0, 0x31FF)) kana = true;
        else if (in_range(cp, 0xAC00, 0xD7AF) || in_range(cp, 0x1100, 0x11FF) || in_range(cp, 0x3130, 0x318F)) hangul = true;
        else if (in_range(cp, 0x4E00, 0x9FFF) || in_range(cp, 0x3400, 0x4DBF) || in_range(cp, 0x3000, 0x303F) || in_range(cp, 0xFF00, 0xFFEF)) han = true;
        else if (in_range(cp, 0x0600, 0x06FF) || in_range(cp, 0x0750, 0x077F) || in_range(cp, 0xFB50, 0xFDFF) || in_range(cp, 0xFE70, 0xFEFF)) arabic = true;
        else if (in_range(cp, 0x0E00, 0x0E7F)) thai = true;
        else if (in_range(cp, 0x0900, 0x097F)) devanagari = true;
        else if (in_range(cp, 0x1F000, 0x1FAFF) || in_range(cp, 0x2600, 0x27BF)) emoji = true;
        else other = true;
    }
    std::vector<std::string> fonts;
    if (kana) fonts.push_back("Noto Sans JP");
    if (hangul) fonts.push_back("Noto Sans KR");
    if (han && !kana && !hangul) {
        if (base == "ja") fonts.push_back("Noto Sans JP");
        else if (base == "ko") fonts.push_back("Noto Sans KR");
        else if (base == "zh") fonts.push_back(traditional ? "Noto Sans TC" : "Noto Sans SC");
        else fonts.push_back("Noto Sans SC, TC, JP or KR (the one of your language)");
    }
    if (arabic) fonts.push_back("Noto Sans Arabic");
    if (thai) fonts.push_back("Noto Sans Thai");
    if (devanagari) fonts.push_back("Noto Sans Devanagari");
    if (other && fonts.empty()) fonts.push_back("the Noto Sans family for that script");
    if (fonts.empty() && emoji) return "Colour emoji fonts are not supported (only TrueType outlines): draw emoji as sprites.";
    std::string out = "A free font for them: " + join(fonts, " and ") + " (SIL Open Font License).";
    if (emoji) out += " Colour emoji are not supported: draw emoji as sprites.";
    return out;
}

// ---- the report ----------------------------------------------------------------------------------------------------------

enum class Where { Table, Literal, NoSection };

class Reporter {
public:
    Reporter(ValidationReport& r, const LocalizationSettings& s) : report_(r), settings_(s) {}

    void error(std::string file, std::string pointer, std::string message, std::string hint = {}) {
        report_.errors.push_back({std::move(file), std::move(pointer), std::move(message), std::move(hint)});
    }
    void warn(std::string file, std::string pointer, std::string message, std::string hint = {}) {
        report_.warnings.push_back({std::move(file), std::move(pointer), std::move(message), std::move(hint)});
    }

    // A text with characters that no font of its chain has: names the characters, the text, the file and what to do.
    void missing_glyphs(const std::string& file, const std::string& pointer, const std::string& what, const std::string& text,
                        const std::vector<std::uint32_t>& cps, const std::vector<std::string>& chain, Where where, const std::string& language) {
        PerFile& f = files_[file];
        f.all.insert(cps.begin(), cps.end());
        if (++f.count > kGlyphErrors) return;
        std::string fonts;
        for (const std::string& font : chain) fonts += (fonts.empty() ? "" : ", ") + font_name(font);
        if (std::find(chain.begin(), chain.end(), std::string()) == chain.end())  // the last resort of every chain
            fonts += std::string(fonts.empty() ? "" : ", ") + "DejaVu Sans (built-in)";
        error(file, pointer, what + " (\"" + excerpt(text) + "\") has " + (cps.size() == 1 ? "a character" : "characters") +
                                 " that no font of its chain has a glyph for, so the game would draw " + (cps.size() == 1 ? "it" : "them") +
                                 " as nothing: " + list_code_points(cps) + ". Fonts checked: " + fonts + ".",
              fix(cps, where, language));
    }

    // After the last text: the files that had more problems than were listed.
    void finish() {
        for (const auto& [file, f] : files_) {
            if (f.count <= kGlyphErrors) continue;
            const std::vector<std::uint32_t> all(f.all.begin(), f.all.end());
            error(file, "", std::to_string(f.count - kGlyphErrors) + " more text(s) have characters no font has a glyph for. All the missing characters of this file: " + list_code_points(all, 30) + ".",
                  "One font that covers them all, listed in factoria.json, fixes every one of these texts.");
        }
    }

private:
    struct PerFile {
        std::size_t count = 0;
        std::set<std::uint32_t> all;
    };

    std::string fix(const std::vector<std::uint32_t>& cps, Where where, const std::string& language) const {
        const std::string suggestion = suggest_font(cps, language.empty() ? settings_.defaultLanguage : language);
        if (suggestion.rfind("Colour emoji", 0) == 0) return suggestion;
        std::string where_to;
        switch (where) {
            case Where::Table:
                where_to = "put a .ttf that has them in assets/fonts/ and list it in factoria.json: localization.languageFonts.\"" + language +
                           "\" (used only while the game runs in " + language + ") or localization.fallbackFonts (every language)";
                break;
            case Where::Literal:
                where_to = "put a .ttf that has them in assets/fonts/ and list it in factoria.json: localization.fallbackFonts, or "
                           "localization.languageFonts.\"" + settings_.defaultLanguage + "\"; or set the component's \"font\" to it";
                break;
            case Where::NoSection:
                where_to = "put a .ttf that has them in assets/fonts/ and set the component's \"font\" to it (or add a \"localization\" section with "
                           "\"fallbackFonts\" to cover every text of the game)";
                break;
        }
        return "Either change the text, or " + where_to + ". " + suggestion + " See docs/TEXT.md.";
    }

    ValidationReport& report_;
    const LocalizationSettings& settings_;
    std::map<std::string, PerFile> files_;
};

// ---- the tables ----------------------------------------------------------------------------------------------------------

const char* const kExchangeHint =
    "`factoria call i18n.export` writes a spreadsheet (CSV) or XLIFF file for translators and `i18n.import` reads it back (docs/LOCALIZATION.md).";

void check_plural_forms(Reporter& out, const TableFile& t) {
    for (const auto& [key, entry] : t.table->entries) {
        if (!entry.plural()) continue;
        const std::vector<PluralCategory> needed = plural_categories(t.language);
        const std::vector<PluralCategory> allowed = plural_categories(t.language, true);
        const auto has = [&](const std::vector<PluralCategory>& list, PluralCategory c) { return std::find(list.begin(), list.end(), c) != list.end(); };
        for (PluralCategory c : needed) {
            if (entry.forms.count(c)) continue;
            int sample = 0;
            while (sample < 199 && plural_category(t.language, sample) != c) ++sample;
            out.warn(t.file, entry.pointer,
                     "The plural entry " + quote(key) + " has no \"" + plural_category_name(c) + "\" form, which '" + t.language +
                         "' uses for counts like " + std::to_string(sample) + ": those counts show the \"other\" form.",
                     "Add \"" + std::string(plural_category_name(c)) + "\" next to the other forms (CLDR plural rules: docs/LOCALIZATION.md).");
        }
        for (const auto& [category, text] : entry.forms) {
            if (has(allowed, category)) continue;
            std::string used;
            for (PluralCategory c : needed) used += (used.empty() ? "" : ", ") + std::string(plural_category_name(c));
            out.warn(t.file, entry.pointer + "/" + plural_category_name(category),
                     "The plural entry " + quote(key) + " has a \"" + plural_category_name(category) + "\" form, which no count picks in '" +
                         t.language + "' (it uses: " + used + "), so it is never shown.",
                     "Remove it, or move its text to the form the language uses.");
        }
    }
}

void compare_with_default(Reporter& out, const TableFile& def, const TableFile& t) {
    const auto& defaults = def.table->entries;
    const auto& own = t.table->entries;
    std::vector<std::string> missing, defaultKeys;
    for (const auto& [key, entry] : defaults) {
        defaultKeys.push_back(key);
        if (!own.count(key)) missing.push_back(key);
    }
    if (!missing.empty())
        out.warn(t.file, "",
                 "'" + t.language + "' lacks " + std::to_string(missing.size()) + " of the " + std::to_string(defaults.size()) +
                     " strings of the default language (" + def.language + "): " + list_names(missing) +
                     ". The game shows the text of " + def.language + " for them.",
                 std::string("Translate them in ") + t.file + ". " + kExchangeHint);

    std::size_t stale = 0;
    for (const auto& [key, entry] : own) {
        if (defaults.count(key)) continue;
        if (++stale > kExtraKeys) continue;
        const std::string close = closest_match(key, missing.empty() ? defaultKeys : missing);
        out.warn(t.file, entry.pointer,
                 "The key " + quote(key) + " is not in " + def.file + ", so the game never asks for it (a typo, or a string that was removed).",
                 close.empty() ? "Remove it, or add the key to " + def.file + "." : "Did you mean " + quote(close) + "?");
    }
    if (stale > kExtraKeys)
        out.warn(t.file, "", std::to_string(stale - kExtraKeys) + " more keys are not in " + def.file + ".",
                 "Remove the stale keys, or add them to " + def.file + ".");

    for (const auto& [key, entry] : own) {
        const auto it = defaults.find(key);
        if (it == defaults.end()) continue;
        const StringEntry& original = it->second;
        if (original.plural() != entry.plural()) {
            out.warn(t.file, entry.pointer,
                     entry.plural() ? "The key " + quote(key) + " is one plain string in " + def.file + " but has plural forms here."
                                    : "The key " + quote(key) + " has plural forms in " + def.file + " but is one plain string here: it shows the same text for every count.",
                     "Give the key the same shape in every language: either plural forms {\"one\": ..., \"other\": ...} or one string.");
            continue;
        }
        const std::set<std::string> want = placeholders_of(original), have = placeholders_of(entry);
        if (want != have)
            out.warn(t.file, entry.pointer,
                     "The key " + quote(key) + " uses " + describe_names(have) + " here but " + describe_names(want) + " in " + def.file +
                         ": the code fills the names of the default language, any other stays as written.",
                     "Keep the {names} of " + def.file + " (translate the text around them, not the names).");
    }
}

// ---- the whole check ------------------------------------------------------------------------------------------------------

void check_tables_and_keys(Reporter& out, const LocalizationSettings& s, const std::vector<SceneText>& texts,
                           const std::vector<PlatformCatalog::TextKeyRef>& catalogKeys, std::vector<TableFile>& tables,
                           const TableFile*& def) {
    for (const std::string& language : s.languages) tables.push_back(read_table(language));
    for (const TableFile& t : tables) {
        if (t.language == s.defaultLanguage) def = &t;
        if (!t.table) out.error(t.file, t.pointer, t.message, t.hint);
    }
    for (const TableFile& t : tables)
        if (t.table) check_plural_forms(out, t);
    if (def && def->table)
        for (const TableFile& t : tables)
            if (t.table && &t != def) compare_with_default(out, *def, t);

    // The keys the scenes use must exist in the default language's table: it is the last place the game looks.
    if (!def || !def->table) return;
    std::vector<std::string> known;
    for (const auto& [key, entry] : def->table->entries) known.push_back(key);
    for (const PlatformCatalog::TextKeyRef& k : catalogKeys) {
        if (def->table->entries.count(k.key)) continue;
        const std::string close = closest_match(k.key, known);
        out.error(kProjectFileName, k.pointer,
                  "The catalog names the key " + quote(k.key) + ", which " + def->file + " does not have: the store text would fall back to the plain text, or to the key itself.",
                  close.empty() ? "Add the key to " + def->file + " (and to the other languages' tables), or fix the spelling."
                                : "Did you mean " + quote(close) + "? Otherwise add the key to " + def->file + ".");
    }
    std::set<std::string> reported;
    for (const SceneText& t : texts) {
        if (t.key.empty()) continue;
        const auto it = def->table->entries.find(t.key);
        if (it == def->table->entries.end()) {
            const std::string close = closest_match(t.key, known);
            out.error(t.file, t.keyPointer,
                      t.component + " has the key " + quote(t.key) + ", which " + def->file + " does not have: the game would show the text written in the scene" +
                          " and log a warning.",
                      close.empty() ? "Add the key to " + def->file + " (and to the other languages' tables), or fix the spelling."
                                    : "Did you mean " + quote(close) + "? Otherwise add the key to " + def->file + ".");
        } else if (it->second.plural() && reported.insert(t.file + t.keyPointer).second) {
            out.warn(t.file, t.keyPointer,
                     t.component + " uses the key " + quote(t.key) + ", a plural entry: a component has no count, so it always shows the \"other\" form.",
                     "Write the text with i18n.t(\"" + t.key + "\", { count }) in a script instead, or use a key that is one string.");
        } else if (!placeholders_of(it->second).empty() && reported.insert(t.file + t.keyPointer).second) {
            out.warn(t.file, t.keyPointer,
                     t.component + " uses the key " + quote(t.key) + ", whose text has " + describe_names(placeholders_of(it->second)) +
                         ": a component has no arguments, so the placeholders would show as written.",
                     "Write the text with i18n.t(\"" + t.key + "\", { ... }) in a script instead, or use a key without placeholders.");
        }
    }
}

// Opening every font once: a font that is missing or not a font is an error of its own, at the place that names it.
void check_fonts(Reporter& out, Coverage& coverage, const std::string& dir, const LocalizationSettings& s, const std::vector<SceneText>& texts) {
    const auto settle = [&](const std::string& font, const std::string& file, const std::string& pointer, bool exists) {
        if (font.empty() || font == "builtin:pixel" || coverage.get(font)) return;
        if (!exists) return;  // a Text.font that is missing is reported as a missing asset
        const Error& e = coverage.error(font);
        out.error(file, pointer, e.message, e.hint);
    };
    for (std::size_t i = 0; i < s.fallbackFonts.size(); ++i)
        settle(s.fallbackFonts[i], kProjectFileName, "/localization/fallbackFonts/" + std::to_string(i), true);
    for (const auto& [language, fonts] : s.languageFonts)
        for (std::size_t i = 0; i < fonts.size(); ++i)
            settle(fonts[i], kProjectFileName, "/localization/languageFonts/" + language + "/" + std::to_string(i), true);
    std::set<std::string> seen;
    for (const SceneText& t : texts) {
        if (!t.fontKnown || t.font.empty() || !seen.insert(t.font).second) continue;
        settle(t.font, t.file, t.pointer.substr(0, t.pointer.rfind('/')) + "/font", fs::exists((std::filesystem::path(dir) / t.font).generic_string()));
    }
}

void check_glyphs(Reporter& out, Coverage& coverage, const LocalizationSettings& s, const std::vector<SceneText>& texts,
                  const std::vector<TableFile>& tables) {
    // Tables: every string of a language, with the font of each component that shows its key (the built-in one when none does).
    std::map<std::string, std::set<std::string>> fontsOfKey;
    for (const SceneText& t : texts)
        if (!t.key.empty()) fontsOfKey[t.key].insert(t.fontKnown ? t.font : std::string());
    for (const TableFile& t : tables) {
        if (!t.table) continue;
        const std::vector<std::string> fallback = s.fallback_fonts_for(t.language);
        for (const auto& [key, entry] : t.table->entries) {
            const auto users = fontsOfKey.find(key);
            const std::set<std::string> fonts = users == fontsOfKey.end() ? std::set<std::string>{""} : users->second;
            for (const EntryText& e : texts_of(entry)) {
                for (const std::string& font : fonts) {
                    std::vector<std::string> chain{font};
                    chain.insert(chain.end(), fallback.begin(), fallback.end());
                    const auto lacks = coverage.missing(chain, *e.text);
                    if (!lacks || lacks->empty()) continue;
                    out.missing_glyphs(t.file, e.pointer, quote(key) + (e.form.empty() ? "" : " (" + e.form + ")"), *e.text, *lacks, chain, Where::Table,
                                       t.language);
                    break;  // one report per text, whichever component font showed it
                }
            }
        }
        // The language's own name is shown in language menus whatever language the game runs in.
        if (t.table->name.empty()) continue;
        std::vector<std::string> languagesLacking;
        std::vector<std::uint32_t> lost, lostInOwn;  // in every language / while the game runs in the language itself
        std::vector<std::string> ownChain;
        for (const std::string& running : s.languages) {
            std::vector<std::string> chain{""};
            const std::vector<std::string> fonts = s.fallback_fonts_for(running);
            chain.insert(chain.end(), fonts.begin(), fonts.end());
            const auto lacks = coverage.missing(chain, t.table->name);
            if (!lacks || lacks->empty()) continue;
            languagesLacking.push_back(running);
            for (std::uint32_t cp : *lacks)
                if (std::find(lost.begin(), lost.end(), cp) == lost.end()) lost.push_back(cp);
            if (running == t.language) {
                lostInOwn = *lacks;
                ownChain = std::move(chain);
            }
        }
        if (languagesLacking.empty()) continue;
        if (!ownChain.empty()) {
            out.missing_glyphs(t.file, "/$name", "The language name \"$name\"", t.table->name, lostInOwn, ownChain, Where::Table, t.language);
        } else {
            out.warn(t.file, "/$name",
                     "The language name \"" + t.table->name + "\" has no glyph for " + list_code_points(lost) + " while the game runs in " +
                         list_names(languagesLacking) + ": a language menu would draw it as nothing there.",
                     "List the font in localization.fallbackFonts (every language) instead of only in languageFonts. " + suggest_font(lost, t.language));
        }
    }
}

void check_literal_texts(Reporter& out, Coverage& coverage, const LocalizationSettings& s, const std::vector<SceneText>& texts) {
    const bool section = s.enabled();
    const std::vector<std::string> fallback = section ? s.fallback_fonts_for(s.defaultLanguage) : std::vector<std::string>();
    for (const SceneText& t : texts) {
        if (!t.fontKnown || t.text.empty() || (section && !t.key.empty())) continue;  // a keyed text is shown from the table
        std::vector<std::string> chain{t.font};
        chain.insert(chain.end(), fallback.begin(), fallback.end());
        const auto lacks = coverage.missing(chain, t.text);
        if (!lacks || lacks->empty()) continue;
        out.missing_glyphs(t.file, t.pointer, t.component + "." + t.field, t.text, *lacks, chain, section ? Where::Literal : Where::NoSection,
                           section ? s.defaultLanguage : std::string());
    }
}

}  // namespace

void collect_scene_texts(const std::string& file, const std::string& entityPointer, const Json& entity, std::vector<SceneText>& out) {
    if (!entity.is_object() || !entity.contains("components") || !entity["components"].is_object()) return;
    const Json& components = entity["components"];
    const bool instance = entity.contains("prefab") && entity["prefab"].is_string();
    for (const TextField& f : kTextFields) {
        const auto it = components.find(f.component);
        if (it == components.end() || !it->is_object()) continue;
        const auto string_of = [&](const char* name) -> std::optional<std::string> {
            const auto m = it->find(name);
            return m != it->end() && m->is_string() ? std::optional<std::string>(m->get<std::string>()) : std::nullopt;
        };
        const std::optional<std::string> text = string_of(f.field), key = string_of("key"), font = string_of("font");
        if (!text && (!key || key->empty())) continue;
        SceneText t;
        t.file = file;
        const std::string base = entityPointer + "/components/" + f.component;
        t.pointer = base + "/" + f.field;
        t.keyPointer = base + "/key";
        t.component = f.component;
        t.field = f.field;
        t.text = text.value_or("");
        t.key = key.value_or("");
        t.font = font.value_or("");
        t.fontKnown = font.has_value() || !instance;
        out.push_back(std::move(t));
    }
}

void check_localization_content(const std::string& projectDir, const LocalizationSettings& settings, const std::vector<SceneText>& texts,
                                const std::vector<PlatformCatalog::TextKeyRef>& catalogKeys, ValidationReport& report) {
    tooling_detail::ProjectRootScope scope(projectDir);
    Reporter out(report, settings);
    Coverage coverage;

    if (!settings.enabled()) {
        const bool keys = std::any_of(texts.begin(), texts.end(), [](const SceneText& t) { return !t.key.empty(); });
        const bool tables = !fs::list("locales", false, ".json").empty();
        if (keys || tables)
            out.warn(kProjectFileName, "",
                     std::string("factoria.json has no \"localization\" section, but ") +
                         (keys ? "scenes use `key` fields" : "the project has a locales/ folder") + (keys && tables ? " and a locales/ folder" : "") +
                         ": nothing is translated, every text shows what the scene says.",
                     "Add \"localization\": {\"defaultLanguage\": \"en\", \"languages\": [\"en\", \"es\"]} with a locales/<language>.json per "
                     "language (docs/LOCALIZATION.md).");
        for (const PlatformCatalog::TextKeyRef& k : catalogKeys)
            out.warn(kProjectFileName, k.pointer, "The catalog names the key " + quote(k.key) + ", but factoria.json has no \"localization\" section, so it is never translated.",
                     "Add the section (docs/LOCALIZATION.md) or write the text itself instead of the key.");
        // Component fonts that cannot be read are reported once; the glyph check skips chains with them.
        check_fonts(out, coverage, projectDir, settings, texts);
        check_literal_texts(out, coverage, settings, texts);
        out.finish();
        return;
    }

    std::vector<TableFile> tables;
    tables.reserve(settings.languages.size());
    const TableFile* def = nullptr;
    check_tables_and_keys(out, settings, texts, catalogKeys, tables, def);
    check_fonts(out, coverage, projectDir, settings, texts);
    check_glyphs(out, coverage, settings, texts, tables);
    check_literal_texts(out, coverage, settings, texts);
    out.finish();
}

}  // namespace fa::localization_detail
