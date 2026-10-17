// Translator exchange: the string tables of a localized game as a spreadsheet (CSV) or XLIFF 1.2 files, and what translators
// send back as updates of locales/<language>.json. Commands i18n.export and i18n.import; docs/LOCALIZATION.md, "Translators".
//
// A plural entry is exchanged as one row per form, the key written `items#one`, `items#other` (the `$name` of a table is the
// row `$name`). The file formats are public so tests and tools can read what the commands write.
#pragma once

#include <map>
#include <string>
#include <string_view>
#include <vector>

#include "fa/core/command.h"
#include "fa/core/types.h"

namespace fa {

// What export writes: one row per string, with the text of the source (default) language and of each language to translate.
struct TranslationSheet {
    struct Row {
        std::string key;                 // "menu.play", "items#one", "$name"
        std::string source;              // the text in the source language
        std::vector<std::string> texts;  // the text in each of `languages` ("" = not translated yet)
        std::string note;                // for the translator: the placeholders to keep, the plural form
    };
    std::string sourceLanguage;
    std::vector<std::string> languages;  // the languages to translate into
    std::vector<Row> rows;
};

// CSV: UTF-8 with a byte order mark (so Excel opens it as UTF-8), columns `key, <source>, <language>...`, RFC 4180 quoting
// (fields with the delimiter, a quote or a line break are quoted, quotes doubled), CRLF line ends.
std::string write_csv(const TranslationSheet& sheet, char delimiter = ',');
// XLIFF 1.2, one file for the language at `languageIndex`: source = the source text, target = the translation (empty with state
// "needs-translation" when there is none), trans-unit id and resname = the key. `original` names the table the source came from.
std::string write_xliff(const TranslationSheet& sheet, std::size_t languageIndex, const std::string& original);

// What a translator's file holds: per language the texts in file order. CSV columns and XLIFF target languages are kept as
// written (the importer maps them to the game's languages); the source column of a CSV is not told apart here.
struct TranslationRow {
    std::string key;
    std::string text;
    std::size_t line = 0;  // where it is in the file (CSV row, XLIFF line), for messages
};
struct TranslationFile {
    std::string format;                      // "csv" | "xliff"
    std::vector<std::string> languages;      // in file order
    std::map<std::string, std::vector<TranslationRow>> rows;
};

// Readers. The delimiter of a CSV (comma, semicolon or tab: what Excel writes in the user's language) is found in its first
// line; a BOM is skipped. Errors name the line and say what to fix.
Result<TranslationFile> read_csv(std::string_view text);
Result<TranslationFile> read_xliff(std::string_view text);
// CSV or XLIFF by the file's extension, else by what its first characters look like. `name` is the file name.
Result<TranslationFile> read_translation_file(std::string_view text, std::string_view name);

// i18n.export, i18n.import.
void register_translation_commands(CommandRegistry& registry, const std::string& projectDir);

}  // namespace fa
