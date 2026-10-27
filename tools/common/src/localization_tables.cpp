#include "localization_tables.h"

#include <format>

#include "fa/core/fs.h"
#include "fa/core/strings.h"
#include "fa/core/utf8.h"

namespace fa::localization_detail {

namespace {

// parse_string_table puts "file#/pointer: " in front of its messages; the validation report keeps them in fields of their own.
void split_located(const std::string& file, std::string& message, std::string& pointer) {
    if (starts_with(message, file + "#")) {
        const std::string rest = message.substr(file.size() + 1);
        if (const std::size_t at = rest.find(": "); at != std::string::npos) {
            pointer = rest.substr(0, at);
            message = rest.substr(at + 2);
        }
    } else if (starts_with(message, file + ": ")) {
        message = message.substr(file.size() + 2);
    }
}

}  // namespace

TableFile read_table(const std::string& language) {
    TableFile t;
    t.language = language;
    t.file = "locales/" + language + ".json";
    t.exists = fs::exists(t.file);
    if (!t.exists) {
        t.message = t.file + " does not exist, although '" + language + "' is one of localization.languages";
        t.hint = "Create it (start from {\"menu\": {\"play\": \"...\"}}: `factoria call i18n.import` fills a new table from a translator's file), or remove '" +
                 language + "' from localization.languages in factoria.json.";
        return t;
    }
    auto document = load_json_file(t.file);
    if (!document.ok()) {
        t.message = document.error().message;
        t.hint = document.error().hint.empty() ? "Fix the JSON syntax." : document.error().hint;
        split_located(t.file, t.message, t.pointer);
        return t;
    }
    t.document = std::move(document.value());
    auto parsed = parse_string_table(t.document, language, t.file);
    if (!parsed.ok()) {
        t.message = parsed.error().message;
        t.hint = parsed.error().hint;
        split_located(t.file, t.message, t.pointer);
        return t;
    }
    t.table = std::move(parsed.value());
    return t;
}

std::set<std::string> placeholders_of(std::string_view text) {
    std::vector<std::string> names;
    format_message(text, Json::object(), &names);  // every placeholder is "missing" from an empty argument list
    return {names.begin(), names.end()};
}

std::set<std::string> placeholders_of(const StringEntry& entry) {
    if (!entry.plural() && !entry.select()) return placeholders_of(entry.text);
    std::set<std::string> names;
    for (const auto& [category, text] : entry.forms) names.merge(placeholders_of(text));
    for (const auto& [form, text] : entry.selects) names.merge(placeholders_of(text));
    return names;
}

std::string describe_names(const std::set<std::string>& names) {
    if (names.empty()) return "no placeholders";
    std::string out;
    for (const std::string& n : names) out += (out.empty() ? "{" : ", {") + n + "}";
    return out;
}

std::vector<EntryText> texts_of(const StringEntry& entry) {
    std::vector<EntryText> out;
    if (entry.select()) {
        for (const auto& [form, text] : entry.selects) out.push_back({entry.pointer + "/" + form, form, &text});
        return out;
    }
    if (!entry.plural()) {
        out.push_back({entry.pointer, "", &entry.text});
        return out;
    }
    for (const auto& [category, text] : entry.forms)
        out.push_back({entry.pointer + "/" + plural_category_name(category), plural_category_name(category), &text});
    return out;
}

std::string describe_code_point(std::uint32_t cp) {
    std::string out = std::format("U+{:04X}", cp);
    if (cp >= 0x20 && cp != 0x7F) {
        out += " '";
        utf8_append(out, cp);
        out += "'";
    }
    return out;
}

std::string excerpt(std::string_view text, std::size_t limit) {
    const std::u32string cps = utf8_decode(text);
    std::string out;
    for (std::size_t i = 0; i < cps.size() && i < limit; ++i) {
        if (cps[i] == U'\n') out += "\\n";
        else utf8_append(out, cps[i]);
    }
    if (cps.size() > limit) out += "...";
    return out;
}

}  // namespace fa::localization_detail
