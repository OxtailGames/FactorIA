// Private helpers shared by the string-table checks of project.validate (validate_localization.cpp) and the translator exchange
// (translations.cpp): reading locales/<language>.json the way the game does, placeholders, UTF-8 for messages.
// Everything here reads through fa::fs, so wrap the call in a tooling_detail::ProjectRootScope.
#pragma once

#include <cstdint>
#include <optional>
#include <set>
#include <string>
#include <string_view>

#include "fa/core/i18n.h"
#include "fa/core/json.h"

namespace fa::localization_detail {

// The string table of one language as the game reads it, or why it cannot be read.
struct TableFile {
    std::string language;
    std::string file;                  // "locales/es.json"
    bool exists = false;
    Json document;                     // the file as written (an object when `table` is set)
    std::optional<StringTable> table;  // nullopt: missing, not JSON, or not a string table
    std::string pointer, message, hint;  // what is wrong when `table` is empty; the JSON pointer is "" for the file as a whole
};
TableFile read_table(const std::string& language);

// The {names} a text uses ("{{" and "}}" are literal braces, not placeholders), and those of every form of an entry.
std::set<std::string> placeholders_of(std::string_view text);
std::set<std::string> placeholders_of(const StringEntry& entry);
std::string describe_names(const std::set<std::string>& names);  // "{count}, {name}" or "no placeholders"

// Every text of an entry with where it is in the file: a plain string, or one per plural form ("/coins/one").
struct EntryText {
    std::string pointer;
    std::string form;  // "" for a plain string, else "one", "other"...
    const std::string* text = nullptr;
};
std::vector<EntryText> texts_of(const StringEntry& entry);

// One code point for a message: `U+65E5 '日'`.
std::string describe_code_point(std::uint32_t cp);
// The start of a text for a message: at most `limit` code points, "..." when cut, line breaks shown as \n.
std::string excerpt(std::string_view text, std::size_t limit = 40);

}  // namespace fa::localization_detail
